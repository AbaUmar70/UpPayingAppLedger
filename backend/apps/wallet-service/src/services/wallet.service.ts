import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/upaying',
});

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

interface LogContext {
  [key: string]: unknown;
}

class Logger {
  private service: string;
  private isProduction: boolean;

  constructor(service: string) {
    this.service = service;
    this.isProduction = process.env.NODE_ENV === 'production';
  }

  private formatMessage(level: LogLevel, message: string, context?: LogContext): string {
    const timestamp = new Date().toISOString();
    const contextStr = context ? ` ${JSON.stringify(context)}` : '';
    return `[${timestamp}] ${level.toUpperCase()} [${this.service}] ${message}${contextStr}`;
  }

  private log(level: LogLevel, message: string, context?: LogContext): void {
    const formattedMessage = this.formatMessage(level, message, context);
    if (level === 'error') console.error(formattedMessage);
    else if (level === 'warn') console.warn(formattedMessage);
    else console.log(formattedMessage);
  }

  debug(message: string, context?: LogContext): void { if (!this.isProduction) this.log('debug', message, context); }
  info(message: string, context?: LogContext): void { this.log('info', message, context); }
  warn(message: string, context?: LogContext): void { this.log('warn', message, context); }
  error(message: string, context?: LogContext): void { this.log('error', message, context); }
}

function createLogger(service: string): Logger {
  return new Logger(service);
}

const logger = createLogger('WalletService');

async function query<T>(sql: string, params: any[] = []): Promise<T[]> {
  const result = await pool.query(sql, params);
  return result.rows as T[];
}

async function queryOne<T>(sql: string, params: any[] = []): Promise<T | null> {
  const rows = await query<T>(sql, params);
  return rows[0] || null;
}

async function execute(sql: string, params: any[] = []): Promise<void> {
  await pool.query(sql, params);
}

import { ledgerService, LedgerTransaction } from './ledger.service';

function generateAccountNumberForType(type: string): string {
  const prefix = type === 'merchant' ? '3' : type === 'escrow' ? '5' : '9';
  const randomDigits = Math.floor(100000000 + Math.random() * 900000000).toString();
  return prefix + randomDigits;
}

export interface CreateWalletParams {
  userId: string;
  currency?: string;
  walletType?: 'main' | 'savings' | 'escrow' | 'merchant';
}

export interface WalletResponse {
  id: string;
  accountNumber: string;
  currency: string;
  balance: bigint;
  availableBalance: bigint;
  lockedBalance: bigint;
  status: string;
  walletType: string;
}

export interface TransferParams {
  senderWalletId: string;
  receiverWalletId: string;
  amount: bigint;
  reference: string;
  description?: string;
}

export class WalletService {
  async createWallet(params: CreateWalletParams): Promise<WalletResponse> {
    const { userId, currency = 'NGN', walletType = 'main' } = params;

    const existingWallet = await queryOne<{ id: string }>(
      `SELECT id FROM wallets WHERE user_id = $1 AND wallet_type = $2 AND currency = $3`,
      [userId, walletType, currency]
    );

    if (existingWallet) {
      throw new Error(`Wallet of type ${walletType} already exists for this user`);
    }

    const accountNumber = generateAccountNumberForType(walletType);
    const id = crypto.randomUUID();

    await execute(
      `INSERT INTO wallets (id, user_id, account_number, currency, wallet_type, balance, available_balance, locked_balance, status) 
       VALUES ($1, $2, $3, $4, $5, 0, 0, 0, 'active')`,
      [id, userId, accountNumber, currency, walletType]
    );

    await execute(
      `INSERT INTO wallet_balances (id, wallet_id, available_balance, locked_balance, total_balance) VALUES ($1, $2, 0, 0, 0)`,
      [crypto.randomUUID(), id]
    );

    await execute(
      `INSERT INTO wallet_limits (id, wallet_id, daily_limit, monthly_limit, single_transaction_limit, daily_used, monthly_used, reset_at) 
       VALUES ($1, $2, 5000000, 20000000, 1000000, 0, 0, NOW() + INTERVAL '1 day')`,
      [crypto.randomUUID(), id]
    );

    await ledgerService.createAccount({
      accountNumber,
      accountName: `Wallet-${id}`,
      accountType: walletType === 'merchant' ? 'merchant_wallet' : 'user_wallet',
      currency,
      userId,
      walletId: id,
    });

    logger.info('Wallet created', { walletId: id, accountNumber });

    return {
      id,
      accountNumber,
      currency,
      balance: BigInt(0),
      availableBalance: BigInt(0),
      lockedBalance: BigInt(0),
      status: 'active',
      walletType,
    };
  }

  async getWalletById(walletId: string): Promise<WalletResponse | null> {
    const wallet = await queryOne<any>(`SELECT * FROM wallets WHERE id = $1`, [walletId]);
    if (!wallet) return null;

    return {
      id: wallet.id,
      accountNumber: wallet.account_number,
      currency: wallet.currency,
      balance: BigInt(wallet.balance),
      availableBalance: BigInt(wallet.available_balance),
      lockedBalance: BigInt(wallet.locked_balance),
      status: wallet.status,
      walletType: wallet.wallet_type,
    };
  }

  async getWalletByAccountNumber(accountNumber: string): Promise<WalletResponse | null> {
    const wallet = await queryOne<any>(`SELECT * FROM wallets WHERE account_number = $1`, [accountNumber]);
    if (!wallet) return null;

    return {
      id: wallet.id,
      accountNumber: wallet.account_number,
      currency: wallet.currency,
      balance: BigInt(wallet.balance),
      availableBalance: BigInt(wallet.available_balance),
      lockedBalance: BigInt(wallet.locked_balance),
      status: wallet.status,
      walletType: wallet.wallet_type,
    };
  }

  async getWalletByUserId(userId: string, walletType?: string): Promise<WalletResponse[]> {
    let sql = `SELECT * FROM wallets WHERE user_id = $1`;
    const params: any[] = [userId];
    
    if (walletType) {
      params.push(walletType);
      sql += ` AND wallet_type = $2`;
    }

    const wallets = await query<any>(sql, params);

    return wallets.map(wallet => ({
      id: wallet.id,
      accountNumber: wallet.account_number,
      currency: wallet.currency,
      balance: BigInt(wallet.balance),
      availableBalance: BigInt(wallet.available_balance),
      lockedBalance: BigInt(wallet.locked_balance),
      status: wallet.status,
      walletType: wallet.wallet_type,
    }));
  }

  async creditWallet(walletId: string, amount: bigint, reference: string, description?: string): Promise<void> {
    const wallet = await this.getWalletById(walletId);
    if (!wallet) throw new Error('Wallet not found');
    if (wallet.status !== 'active') throw new Error('Wallet is not active');

    const balanceBefore = wallet.balance;
    const balanceAfter = balanceBefore + amount;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      await client.query(
        `UPDATE wallets SET balance = balance + $1, available_balance = available_balance + $1 WHERE id = $2`,
        [amount, walletId]
      );

      await client.query(
        `INSERT INTO wallet_statements (id, wallet_id, reference, description, credit, balance_before, balance_after, transaction_type) 
         VALUES ($1, $2, $3, $4, $5, $6, $7, 'credit')`,
        [crypto.randomUUID(), walletId, reference, description || null, amount, balanceBefore, balanceAfter]
      );

      await client.query('COMMIT');
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }

    const account = await ledgerService.getAccountByNumber(wallet.accountNumber);
    if (account) {
      await ledgerService.postTransaction({
        reference,
        description: description || 'Wallet credit',
        transactionType: 'bank_deposit',
        totalAmount: amount,
        entries: [
          { accountId: account.id, entryType: 'CREDIT', amount, description },
        ],
      });
    }

    logger.info('Wallet credited', { walletId, amount, reference });
  }

  async debitWallet(walletId: string, amount: bigint, reference: string, description?: string): Promise<void> {
    const wallet = await this.getWalletById(walletId);
    if (!wallet) throw new Error('Wallet not found');
    if (wallet.status !== 'active') throw new Error('Wallet is not active');
    if (wallet.availableBalance < amount) throw new Error('Insufficient funds');

    const balanceBefore = wallet.balance;
    const balanceAfter = balanceBefore - amount;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      await client.query(
        `UPDATE wallets SET balance = balance - $1, available_balance = available_balance - $1 WHERE id = $2`,
        [amount, walletId]
      );

      await client.query(
        `INSERT INTO wallet_statements (id, wallet_id, reference, description, debit, balance_before, balance_after, transaction_type) 
         VALUES ($1, $2, $3, $4, $5, $6, $7, 'debit')`,
        [crypto.randomUUID(), walletId, reference, description || null, amount, balanceBefore, balanceAfter]
      );

      await client.query('COMMIT');
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }

    const account = await ledgerService.getAccountByNumber(wallet.accountNumber);
    if (account) {
      await ledgerService.postTransaction({
        reference,
        description: description || 'Wallet debit',
        transactionType: 'bank_withdrawal',
        totalAmount: amount,
        entries: [
          { accountId: account.id, entryType: 'DEBIT', amount, description },
        ],
      });
    }

    logger.info('Wallet debited', { walletId, amount, reference });
  }

  async transfer(params: TransferParams): Promise<void> {
    const { senderWalletId, receiverWalletId, amount, reference, description } = params;

    if (amount <= BigInt(0)) throw new Error('Amount must be greater than 0');

    const senderWallet = await this.getWalletById(senderWalletId);
    if (!senderWallet) throw new Error('Sender wallet not found');
    if (senderWallet.status !== 'active') throw new Error('Sender wallet is not active');
    if (senderWallet.availableBalance < amount) throw new Error('Insufficient funds');

    const receiverWallet = await this.getWalletById(receiverWalletId);
    if (!receiverWallet) throw new Error('Receiver wallet not found');
    if (receiverWallet.status !== 'active') throw new Error('Receiver wallet is not active');

    const senderAccount = await ledgerService.getAccountByNumber(senderWallet.accountNumber);
    const receiverAccount = await ledgerService.getAccountByNumber(receiverWallet.accountNumber);

    if (!senderAccount || !receiverAccount) {
      throw new Error('Ledger accounts not found');
    }

    const ledgerTx: LedgerTransaction = {
      reference,
      description: description || 'Wallet transfer',
      transactionType: 'wallet_transfer',
      totalAmount: amount,
      entries: [
        { accountId: senderAccount.id, entryType: 'DEBIT', amount, description: `Transfer to ${receiverWallet.accountNumber}` },
        { accountId: receiverAccount.id, entryType: 'CREDIT', amount, description: `Transfer from ${senderWallet.accountNumber}` },
      ],
    };

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      await client.query(
        `UPDATE wallets SET balance = balance - $1, available_balance = available_balance - $1 WHERE id = $2`,
        [amount, senderWalletId]
      );

      await client.query(
        `UPDATE wallets SET balance = balance + $1, available_balance = available_balance + $1 WHERE id = $2`,
        [amount, receiverWalletId]
      );

      await client.query(
        `INSERT INTO wallet_statements (id, wallet_id, reference, description, debit, balance_before, balance_after, transaction_type) 
         VALUES ($1, $2, $3, $4, $5, $6, $7, 'transfer_out')`,
        [crypto.randomUUID(), senderWalletId, reference, description || null, amount, senderWallet.balance, senderWallet.balance - amount]
      );

      await client.query(
        `INSERT INTO wallet_statements (id, wallet_id, reference, description, credit, balance_before, balance_after, transaction_type) 
         VALUES ($1, $2, $3, $4, $5, $6, $7, 'transfer_in')`,
        [crypto.randomUUID(), receiverWalletId, reference, description || null, amount, receiverWallet.balance, receiverWallet.balance + amount]
      );

      await client.query('COMMIT');
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }

    await ledgerService.postTransaction(ledgerTx);

    logger.info('Wallet transfer completed', { senderWalletId, receiverWalletId, amount, reference });
  }

  async freezeWallet(walletId: string, freezeType: 'full' | 'partial' | 'debit' | 'credit', reason: string, frozenBy: string): Promise<void> {
    const wallet = await this.getWalletById(walletId);
    if (!wallet) throw new Error('Wallet not found');

    await execute(
      `INSERT INTO wallet_freeze (id, wallet_id, freeze_type, reason, frozen_by) VALUES ($1, $2, $3, $4, $5)`,
      [crypto.randomUUID(), walletId, freezeType, reason, frozenBy]
    );

    const status = freezeType === 'full' ? 'frozen' : wallet.status;
    await execute(`UPDATE wallets SET status = $1 WHERE id = $2`, [status, walletId]);

    logger.info('Wallet frozen', { walletId, freezeType, reason });
  }

  async unfreezeWallet(walletId: string, unfrozenBy: string): Promise<void> {
    const activeFreeze = await queryOne<{ id: string }>(
      `SELECT id FROM wallet_freeze WHERE wallet_id = $1 AND unfrozen_at IS NULL ORDER BY created_at DESC LIMIT 1`,
      [walletId]
    );

    if (!activeFreeze) throw new Error('No active freeze found');

    await execute(`UPDATE wallet_freeze SET unfrozen_by = $1, unfrozen_at = NOW() WHERE id = $2`, [unfrozenBy, activeFreeze.id]);
    await execute(`UPDATE wallets SET status = 'active' WHERE id = $1`, [walletId]);

    logger.info('Wallet unfrozen', { walletId });
  }

  async getWalletStatement(walletId: string, options?: { startDate?: Date; endDate?: Date; limit?: number; offset?: number }) {
    let sql = `SELECT * FROM wallet_statements WHERE wallet_id = $1`;
    const params: any[] = [walletId];

    if (options?.startDate) {
      params.push(options.startDate);
      sql += ` AND created_at >= $${params.length}`;
    }
    if (options?.endDate) {
      params.push(options.endDate);
      sql += ` AND created_at <= $${params.length}`;
    }

    sql += ` ORDER BY created_at DESC`;

    if (options?.limit) {
      params.push(options.limit);
      sql += ` LIMIT $${params.length}`;
    }
    if (options?.offset) {
      params.push(options.offset);
      sql += ` OFFSET $${params.length}`;
    }

    return query(sql, params);
  }

  async checkLimits(walletId: string, amount: bigint): Promise<{ allowed: boolean; reason?: string }> {
    const limits = await queryOne<any>(`SELECT * FROM wallet_limits WHERE wallet_id = $1`, [walletId]);
    if (!limits) return { allowed: true };

    if (amount > BigInt(limits.single_transaction_limit)) {
      return { allowed: false, reason: 'Amount exceeds single transaction limit' };
    }

    const today = new Date();
    const resetDate = new Date(limits.reset_at);
    
    if (today > resetDate) {
      await execute(
        `UPDATE wallet_limits SET daily_used = 0, monthly_used = 0, reset_at = NOW() + INTERVAL '1 day' WHERE wallet_id = $1`,
        [walletId]
      );
    }

    if (amount + BigInt(limits.daily_used) > BigInt(limits.daily_limit)) {
      return { allowed: false, reason: 'Amount exceeds daily limit' };
    }

    if (amount + BigInt(limits.monthly_used) > BigInt(limits.monthly_limit)) {
      return { allowed: false, reason: 'Amount exceeds monthly limit' };
    }

    return { allowed: true };
  }

  async updateLimitUsage(walletId: string, amount: bigint): Promise<void> {
    await execute(
      `UPDATE wallet_limits SET daily_used = daily_used + $1, monthly_used = monthly_used + $1 WHERE wallet_id = $2`,
      [amount, walletId]
    );
  }
}

export const walletService = new WalletService();
