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

const logger = createLogger('LedgerService');

export type EntryType = 'DEBIT' | 'CREDIT';
export type TransactionType = 
  | 'wallet_transfer'
  | 'merchant_payment'
  | 'bill_payment'
  | 'bank_withdrawal'
  | 'bank_deposit'
  | 'card_payment'
  | 'loan_disbursement'
  | 'loan_repayment'
  | 'fee_charge'
  | 'reversal'
  | 'settlement'
  | 'commission'
  | 'airtime_purchase'
  | 'data_purchase'
  | 'electricity_payment';

export type TransactionStatus = 'pending' | 'completed' | 'failed' | 'reversed';

export interface LedgerEntry {
  accountId: string;
  entryType: EntryType;
  amount: bigint;
  currency?: string;
  description?: string;
}

export interface LedgerTransaction {
  reference: string;
  description: string;
  transactionType: TransactionType;
  totalAmount: bigint;
  currency?: string;
  metadata?: Record<string, unknown>;
  entries: LedgerEntry[];
}

export interface Account {
  id: string;
  accountNumber: string;
  accountName: string;
  accountType: string;
  currency: string;
  userId?: string;
  walletId?: string;
  isActive: boolean;
}

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

export class LedgerService {
  async createAccount(data: {
    accountNumber: string;
    accountName: string;
    accountType: string;
    currency?: string;
    userId?: string;
    walletId?: string;
  }): Promise<Account> {
    const id = crypto.randomUUID();
    await execute(
      `INSERT INTO ledger_accounts (id, account_number, account_name, account_type, currency, user_id, wallet_id, is_active) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, true)`,
      [id, data.accountNumber, data.accountName, data.accountType, data.currency || 'NGN', data.userId || null, data.walletId || null]
    );

    await execute(
      `INSERT INTO account_balances (id, account_id, balance, debit_balance, credit_balance) VALUES ($1, $2, 0, 0, 0)`,
      [crypto.randomUUID(), id]
    );

    logger.info('Ledger account created', { accountId: id, accountNumber: data.accountNumber });
    return { id, accountNumber: data.accountNumber, accountName: data.accountName, accountType: data.accountType, currency: data.currency || 'NGN', isActive: true };
  }

  async getAccountById(accountId: string): Promise<Account | null> {
    return queryOne<Account>(`SELECT * FROM ledger_accounts WHERE id = $1`, [accountId]);
  }

  async getAccountByNumber(accountNumber: string): Promise<Account | null> {
    return queryOne<Account>(`SELECT * FROM ledger_accounts WHERE account_number = $1`, [accountNumber]);
  }

  async getAccountBalance(accountId: string): Promise<bigint> {
    const result = await queryOne<{ balance: bigint }>(`SELECT get_account_balance($1) as balance`, [accountId]);
    return result?.balance || BigInt(0);
  }

  async postTransaction(tx: LedgerTransaction): Promise<string> {
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');

      const transactionId = crypto.randomUUID();
      await client.query(
        `INSERT INTO ledger_transactions (id, reference, description, transaction_type, status, total_amount, currency, metadata, completed_at) 
         VALUES ($1, $2, $3, $4, 'completed', $5, $6, $7, NOW())`,
        [transactionId, tx.reference, tx.description, tx.transactionType, tx.totalAmount, tx.currency || 'NGN', JSON.stringify(tx.metadata || {})]
      );

      let totalDebit = BigInt(0);
      let totalCredit = BigInt(0);

      for (const entry of tx.entries) {
        await client.query(
          `INSERT INTO ledger_entries (id, transaction_id, account_id, entry_type, amount, currency, description) 
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [crypto.randomUUID(), transactionId, entry.accountId, entry.entryType, entry.amount, entry.currency || 'NGN', entry.description || null]
        );

        if (entry.entryType === 'DEBIT') {
          totalDebit += entry.amount;
        } else {
          totalCredit += entry.amount;
        }
      }

      const isBalanced = totalDebit === totalCredit;
      if (!isBalanced) {
        throw new Error(`Transaction is not balanced: Debit=${totalDebit}, Credit=${totalCredit}`);
      }

      for (const entry of tx.entries) {
        if (entry.entryType === 'DEBIT') {
          await client.query(
            `UPDATE account_balances SET debit_balance = debit_balance + $1, balance = balance - $1, last_transaction_at = NOW(), updated_at = NOW() WHERE account_id = $2`,
            [entry.amount, entry.accountId]
          );
        } else {
          await client.query(
            `UPDATE account_balances SET credit_balance = credit_balance + $1, balance = balance + $1, last_transaction_at = NOW(), updated_at = NOW() WHERE account_id = $2`,
            [entry.amount, entry.accountId]
          );
        }
      }

      await client.query('COMMIT');
      
      logger.info('Ledger transaction posted', { transactionId, reference: tx.reference, amount: tx.totalAmount });
      
      return transactionId;
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Failed to post ledger transaction', { reference: tx.reference, error: String(error) });
      throw error;
    } finally {
      client.release();
    }
  }

  async reverseTransaction(originalTransactionId: string, reason: string, reversedBy: string): Promise<string> {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      const originalTx = await client.query('SELECT * FROM ledger_transactions WHERE id = $1', [originalTransactionId]);
      if (originalTx.rows.length === 0) throw new Error('Original transaction not found');
      if (originalTx.rows[0].status === 'reversed') throw new Error('Transaction already reversed');

      const reversalReference = `REV-${originalTx.rows[0].reference}`;
      const reversalTxId = crypto.randomUUID();
      
      await client.query(
        `INSERT INTO ledger_transactions (id, reference, description, transaction_type, status, total_amount, currency, metadata, reversed_by, reversed_at, completed_at) 
         VALUES ($1, $2, $3, 'reversal', 'completed', $4, $5, $6, $7, NOW(), NOW())`,
        [reversalTxId, reversalReference, `Reversal: ${reason}`, originalTx.rows[0].total_amount, originalTx.rows[0].currency, JSON.stringify({ originalTransactionId }), reversedBy]
      );

      const originalEntries = await client.query('SELECT * FROM ledger_entries WHERE transaction_id = $1', [originalTransactionId]);

      for (const entry of originalEntries.rows) {
        const reversedEntryType = entry.entry_type === 'DEBIT' ? 'CREDIT' : 'DEBIT';
        
        await client.query(
          `INSERT INTO ledger_entries (id, transaction_id, account_id, entry_type, amount, currency, description) 
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [crypto.randomUUID(), reversalTxId, entry.account_id, reversedEntryType, entry.amount, entry.currency, `Reversal of entry ${entry.id}`]
        );

        if (reversedEntryType === 'DEBIT') {
          await client.query(
            `UPDATE account_balances SET debit_balance = debit_balance + $1, balance = balance - $1 WHERE account_id = $2`,
            [entry.amount, entry.account_id]
          );
        } else {
          await client.query(
            `UPDATE account_balances SET credit_balance = credit_balance + $1, balance = balance + $1 WHERE account_id = $2`,
            [entry.amount, entry.account_id]
          );
        }
      }

      await client.query(`UPDATE ledger_transactions SET status = 'reversed' WHERE id = $1`, [originalTransactionId]);

      await client.query(
        `INSERT INTO ledger_reversals (id, original_transaction_id, reversal_transaction_id, reason, reversed_by) VALUES ($1, $2, $3, $4, $5)`,
        [crypto.randomUUID(), originalTransactionId, reversalTxId, reason, reversedBy]
      );

      await client.query('COMMIT');

      logger.info('Transaction reversed', { originalTransactionId, reversalTransactionId: reversalTxId });

      return reversalTxId;
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Failed to reverse transaction', { originalTransactionId, error: String(error) });
      throw error;
    } finally {
      client.release();
    }
  }

  async getTransactionHistory(accountId: string, options?: { startDate?: Date; endDate?: Date; limit?: number; offset?: number }): Promise<any[]> {
    let sql = `SELECT le.*, lt.reference as tx_reference, lt.description as tx_description, lt.transaction_type, lt.created_at as tx_created_at 
               FROM ledger_entries le 
               JOIN ledger_transactions lt ON le.transaction_id = lt.id 
               WHERE le.account_id = $1`;
    const params: any[] = [accountId];

    if (options?.startDate) {
      params.push(options.startDate);
      sql += ` AND lt.created_at >= $${params.length}`;
    }
    if (options?.endDate) {
      params.push(options.endDate);
      sql += ` AND lt.created_at <= $${params.length}`;
    }

    sql += ` ORDER BY le.created_at DESC`;
    
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

  async getAccountStatement(accountId: string, startDate: Date, endDate: Date): Promise<any[]> {
    return query(
      `SELECT le.*, lt.reference, lt.description, lt.transaction_type FROM ledger_entries le 
       JOIN ledger_transactions lt ON le.transaction_id = lt.id 
       WHERE le.account_id = $1 AND le.created_at >= $2 AND le.created_at <= $3 
       ORDER BY le.created_at ASC`,
      [accountId, startDate, endDate]
    );
  }

  async reconcileAccount(accountId: string): Promise<{ ledgerBalance: bigint; calculatedBalance: bigint; isBalanced: boolean }> {
    const accountBalance = await queryOne<{ balance: bigint }>(`SELECT balance FROM account_balances WHERE account_id = $1`, [accountId]);
    const calculatedBalance = await this.getAccountBalance(accountId);

    return {
      ledgerBalance: accountBalance?.balance || BigInt(0),
      calculatedBalance,
      isBalanced: (accountBalance?.balance || BigInt(0)) === calculatedBalance,
    };
  }
}

export const ledgerService = new LedgerService();
