import { prisma } from '@upaying/database';
import { createLogger } from '@upaying/logger';
import { v4 as uuidv4 } from 'uuid';

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

export class LedgerService {
  async createAccount(data: {
    accountNumber: string;
    accountName: string;
    accountType: string;
    currency?: string;
    userId?: string;
    walletId?: string;
  }): Promise<Account> {
    const account = await prisma.ledgerAccounts.create({
      data: {
        accountNumber: data.accountNumber,
        accountName: data.accountName,
        accountType: data.accountType,
        currency: data.currency || 'NGN',
        userId: data.userId,
        walletId: data.walletId,
        isActive: true,
      },
    });

    await prisma.accountBalances.create({
      data: {
        accountId: account.id,
        balance: 0,
        debitBalance: 0,
        creditBalance: 0,
      },
    });

    logger.info('Ledger account created', { accountId: account.id, accountNumber: data.accountNumber });
    return account;
  }

  async getAccountById(accountId: string): Promise<Account | null> {
    return prisma.ledgerAccounts.findUnique({
      where: { id: accountId },
    });
  }

  async getAccountByNumber(accountNumber: string): Promise<Account | null> {
    return prisma.ledgerAccounts.findUnique({
      where: { account_number: accountNumber },
    });
  }

  async getAccountBalance(accountId: string): Promise<bigint> {
    const result = await prisma.$queryRaw<{ balance: bigint }[]>`
      SELECT get_account_balance(${accountId}::uuid) as balance
    `;
    return result[0]?.balance || BigInt(0);
  }

  async postTransaction(tx: LedgerTransaction): Promise<string> {
    const client = await prisma.$connect();
    
    try {
      await client.$executeRaw`BEGIN`;

      const transaction = await client.ledgerTransactions.create({
        data: {
          reference: tx.reference,
          description: tx.description,
          transactionType: tx.transactionType,
          status: 'completed',
          totalAmount: tx.totalAmount,
          currency: tx.currency || 'NGN',
          metadata: tx.metadata || {},
          completedAt: new Date(),
        },
      });

      let totalDebit = BigInt(0);
      let totalCredit = BigInt(0);

      for (const entry of tx.entries) {
        await client.ledgerEntries.create({
          data: {
            transactionId: transaction.id,
            accountId: entry.accountId,
            entryType: entry.entryType,
            amount: entry.amount,
            currency: entry.currency || 'NGN',
            description: entry.description,
          },
        });

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
        await this.updateAccountBalance(client, entry.accountId, entry.entryType, entry.amount);
      }

      await client.$executeRaw`COMMIT`;
      
      logger.info('Ledger transaction posted', { 
        transactionId: transaction.id, 
        reference: tx.reference,
        amount: tx.totalAmount 
      });
      
      return transaction.id;
    } catch (error) {
      await client.$executeRaw`ROLLBACK`;
      logger.error('Failed to post ledger transaction', { 
        reference: tx.reference, 
        error: String(error) 
      });
      throw error;
    } finally {
      await client.$disconnect();
    }
  }

  private async updateAccountBalance(
    client: any,
    accountId: string,
    entryType: EntryType,
    amount: bigint
  ): Promise<void> {
    if (entryType === 'DEBIT') {
      await client.$executeRaw`
        UPDATE account_balances 
        SET debit_balance = debit_balance + ${amount},
            balance = balance - ${amount},
            last_transaction_at = NOW(),
            updated_at = NOW()
        WHERE account_id = ${accountId}
      `;
    } else {
      await client.$executeRaw`
        UPDATE account_balances 
        SET credit_balance = credit_balance + ${amount},
            balance = balance + ${amount},
            last_transaction_at = NOW(),
            updated_at = NOW()
        WHERE account_id = ${accountId}
      `;
    }
  }

  async reverseTransaction(
    originalTransactionId: string,
    reason: string,
    reversedBy: string
  ): Promise<string> {
    const client = await prisma.$connect();

    try {
      await client.$executeRaw`BEGIN`;

      const originalTx = await client.ledgerTransactions.findUnique({
        where: { id: originalTransactionId },
      });

      if (!originalTx) {
        throw new Error('Original transaction not found');
      }

      if (originalTx.status === 'reversed') {
        throw new Error('Transaction already reversed');
      }

      const reversalReference = `REV-${originalTx.reference}`;
      const reversalTx = await client.ledgerTransactions.create({
        data: {
          reference: reversalReference,
          description: `Reversal: ${reason}`,
          transactionType: 'reversal',
          status: 'completed',
          totalAmount: originalTx.totalAmount,
          currency: originalTx.currency,
          metadata: { originalTransactionId },
          reversedBy: reversedBy,
          reversedAt: new Date(),
          completedAt: new Date(),
        },
      });

      const originalEntries = await client.ledgerEntries.findMany({
        where: { transactionId: originalTransactionId },
      });

      for (const entry of originalEntries) {
        const reversedEntryType = entry.entryType === 'DEBIT' ? 'CREDIT' : 'DEBIT';
        
        await client.ledgerEntries.create({
          data: {
            transactionId: reversalTx.id,
            accountId: entry.accountId,
            entryType: reversedEntryType,
            amount: entry.amount,
            currency: entry.currency,
            description: `Reversal of entry ${entry.id}`,
          },
        });

        await this.updateAccountBalance(client, entry.accountId, reversedEntryType, entry.amount);
      }

      await client.ledgerTransactions.update({
        where: { id: originalTransactionId },
        data: { status: 'reversed' },
      });

      await client.ledgerReversals.create({
        data: {
          originalTransactionId,
          reversalTransactionId: reversalTx.id,
          reason,
          reversedBy,
        },
      });

      await client.$executeRaw`COMMIT`;

      logger.info('Transaction reversed', { 
        originalTransactionId, 
        reversalTransactionId: reversalTx.id 
      });

      return reversalTx.id;
    } catch (error) {
      await client.$executeRaw`ROLLBACK`;
      logger.error('Failed to reverse transaction', { 
        originalTransactionId, 
        error: String(error) 
      });
      throw error;
    } finally {
      await client.$disconnect();
    }
  }

  async getTransactionHistory(
    accountId: string,
    options?: {
      startDate?: Date;
      endDate?: Date;
      limit?: number;
      offset?: number;
    }
  ): Promise<any[]> {
    const where: any = { accountId };

    if (options?.startDate || options?.endDate) {
      where.createdAt = {};
      if (options?.startDate) where.createdAt.gte = options.startDate;
      if (options?.endDate) where.createdAt.lte = options.endDate;
    }

    return prisma.ledgerEntries.findMany({
      where,
      include: {
        transaction: true,
        account: true,
      },
      orderBy: { createdAt: 'desc' },
      take: options?.limit || 50,
      skip: options?.offset || 0,
    });
  }

  async getAccountStatement(
    accountId: string,
    startDate: Date,
    endDate: Date
  ): Promise<any[]> {
    return prisma.ledgerEntries.findMany({
      where: {
        accountId,
        createdAt: {
          gte: startDate,
          lte: endDate,
        },
      },
      include: {
        transaction: true,
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async reconcileAccount(accountId: string): Promise<{
    ledgerBalance: bigint;
    calculatedBalance: bigint;
    isBalanced: boolean;
  }> {
    const accountBalance = await prisma.accountBalances.findUnique({
      where: { accountId },
    });

    const calculatedBalance = await this.getAccountBalance(accountId);

    return {
      ledgerBalance: accountBalance?.balance || BigInt(0),
      calculatedBalance,
      isBalanced: (accountBalance?.balance || BigInt(0)) === calculatedBalance,
    };
  }
}

export const ledgerService = new LedgerService();
