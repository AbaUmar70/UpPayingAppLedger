import { prisma } from '@upaying/database';
import { createLogger } from '@upaying/logger';
import { ledgerService, LedgerTransaction } from './ledger.service';

const logger = createLogger('WalletService');

function generateAccountNumber(): string {
  const prefix = '9';
  const randomDigits = Math.floor(100000000 + Math.random() * 900000000).toString();
  return prefix + randomDigits;
}

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

    const existingWallet = await prisma.wallets.findFirst({
      where: { userId, walletType, currency },
    });

    if (existingWallet) {
      throw new Error(`Wallet of type ${walletType} already exists for this user`);
    }

    const accountNumber = generateAccountNumberForType(walletType);

    const wallet = await prisma.wallets.create({
      data: {
        userId,
        accountNumber,
        currency,
        walletType,
        balance: BigInt(0),
        availableBalance: BigInt(0),
        lockedBalance: BigInt(0),
        status: 'active',
      },
    });

    await prisma.walletBalances.create({
      data: {
        walletId: wallet.id,
        availableBalance: BigInt(0),
        lockedBalance: BigInt(0),
        totalBalance: BigInt(0),
      },
    });

    await prisma.walletLimits.create({
      data: {
        walletId: wallet.id,
        dailyLimit: BigInt(5000000),
        monthlyLimit: BigInt(20000000),
        singleTransactionLimit: BigInt(1000000),
        dailyUsed: BigInt(0),
        monthlyUsed: BigInt(0),
        resetAt: new Date(new Date().setDate(new Date().getDate() + 1)),
      },
    });

    await ledgerService.createAccount({
      accountNumber: wallet.accountNumber,
      accountName: `Wallet-${wallet.id}`,
      accountType: walletType === 'merchant' ? 'merchant_wallet' : 'user_wallet',
      currency,
      userId,
      walletId: wallet.id,
    });

    logger.info('Wallet created', { walletId: wallet.id, accountNumber });

    return {
      id: wallet.id,
      accountNumber: wallet.accountNumber,
      currency: wallet.currency,
      balance: wallet.balance,
      availableBalance: wallet.availableBalance,
      lockedBalance: wallet.lockedBalance,
      status: wallet.status,
      walletType: wallet.walletType,
    };
  }

  async getWalletById(walletId: string): Promise<WalletResponse | null> {
    const wallet = await prisma.wallets.findUnique({
      where: { id: walletId },
    });

    if (!wallet) return null;

    return {
      id: wallet.id,
      accountNumber: wallet.accountNumber,
      currency: wallet.currency,
      balance: wallet.balance,
      availableBalance: wallet.availableBalance,
      lockedBalance: wallet.lockedBalance,
      status: wallet.status,
      walletType: wallet.walletType,
    };
  }

  async getWalletByAccountNumber(accountNumber: string): Promise<WalletResponse | null> {
    const wallet = await prisma.wallets.findUnique({
      where: { account_number: accountNumber },
    });

    if (!wallet) return null;

    return {
      id: wallet.id,
      accountNumber: wallet.accountNumber,
      currency: wallet.currency,
      balance: wallet.balance,
      availableBalance: wallet.availableBalance,
      lockedBalance: wallet.lockedBalance,
      status: wallet.status,
      walletType: wallet.walletType,
    };
  }

  async getWalletByUserId(userId: string, walletType?: string): Promise<WalletResponse[]> {
    const where: any = { userId };
    if (walletType) where.walletType = walletType;

    const wallets = await prisma.wallets.findMany({ where });

    return wallets.map(wallet => ({
      id: wallet.id,
      accountNumber: wallet.accountNumber,
      currency: wallet.currency,
      balance: wallet.balance,
      availableBalance: wallet.availableBalance,
      lockedBalance: wallet.lockedBalance,
      status: wallet.status,
      walletType: wallet.walletType,
    }));
  }

  async creditWallet(walletId: string, amount: bigint, reference: string, description?: string): Promise<void> {
    const wallet = await prisma.wallets.findUnique({ where: { id: walletId } });
    if (!wallet) throw new Error('Wallet not found');
    if (wallet.status !== 'active') throw new Error('Wallet is not active');

    const balanceBefore = wallet.balance;
    const balanceAfter = balanceBefore + amount;

    await prisma.$transaction([
      prisma.wallets.update({
        where: { id: walletId },
        data: {
          balance: { increment: amount },
          availableBalance: { increment: amount },
        },
      }),
      prisma.walletStatements.create({
        data: {
          walletId,
          reference,
          description,
          credit: amount,
          balanceBefore,
          balanceAfter,
          transactionType: 'credit',
        },
      }),
    ]);

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
    const wallet = await prisma.wallets.findUnique({ where: { id: walletId } });
    if (!wallet) throw new Error('Wallet not found');
    if (wallet.status !== 'active') throw new Error('Wallet is not active');
    if (wallet.availableBalance < amount) throw new Error('Insufficient funds');

    const balanceBefore = wallet.balance;
    const balanceAfter = balanceBefore - amount;

    await prisma.$transaction([
      prisma.wallets.update({
        where: { id: walletId },
        data: {
          balance: { decrement: amount },
          availableBalance: { decrement: amount },
        },
      }),
      prisma.walletStatements.create({
        data: {
          walletId,
          reference,
          description,
          debit: amount,
          balanceBefore,
          balanceAfter,
          transactionType: 'debit',
        },
      }),
    ]);

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

    const senderWallet = await prisma.wallets.findUnique({ where: { id: senderWalletId } });
    if (!senderWallet) throw new Error('Sender wallet not found');
    if (senderWallet.status !== 'active') throw new Error('Sender wallet is not active');
    if (senderWallet.availableBalance < amount) throw new Error('Insufficient funds');

    const receiverWallet = await prisma.wallets.findUnique({ where: { id: receiverWalletId } });
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

    await prisma.$transaction([
      prisma.wallets.update({
        where: { id: senderWalletId },
        data: {
          balance: { decrement: amount },
          availableBalance: { decrement: amount },
        },
      }),
      prisma.wallets.update({
        where: { id: receiverWalletId },
        data: {
          balance: { increment: amount },
          availableBalance: { increment: amount },
        },
      }),
      prisma.walletStatements.create({
        data: {
          walletId: senderWalletId,
          reference,
          description,
          debit: amount,
          balanceBefore: senderWallet.balance,
          balanceAfter: senderWallet.balance - amount,
          transactionType: 'transfer_out',
        },
      }),
      prisma.walletStatements.create({
        data: {
          walletId: receiverWalletId,
          reference,
          description,
          credit: amount,
          balanceBefore: receiverWallet.balance,
          balanceAfter: receiverWallet.balance + amount,
          transactionType: 'transfer_in',
        },
      }),
    ]);

    await ledgerService.postTransaction(ledgerTx);

    logger.info('Wallet transfer completed', { 
      senderWalletId, 
      receiverWalletId, 
      amount, 
      reference 
    });
  }

  async freezeWallet(walletId: string, freezeType: 'full' | 'partial' | 'debit' | 'credit', reason: string, frozenBy: string): Promise<void> {
    const wallet = await prisma.wallets.findUnique({ where: { id: walletId } });
    if (!wallet) throw new Error('Wallet not found');

    await prisma.walletFreeze.create({
      data: {
        walletId,
        freezeType,
        reason,
        frozenBy,
      },
    });

    const status = freezeType === 'full' ? 'frozen' : wallet.status;
    await prisma.wallets.update({
      where: { id: walletId },
      data: { status },
    });

    logger.info('Wallet frozen', { walletId, freezeType, reason });
  }

  async unfreezeWallet(walletId: string, unfrozenBy: string): Promise<void> {
    const activeFreeze = await prisma.walletFreeze.findFirst({
      where: { walletId, unfrozenAt: null },
      orderBy: { createdAt: 'desc' },
    });

    if (!activeFreeze) throw new Error('No active freeze found');

    await prisma.walletFreeze.update({
      where: { id: activeFreeze.id },
      data: { unfrozenBy, unfrozenAt: new Date() },
    });

    await prisma.wallets.update({
      where: { id: walletId },
      data: { status: 'active' },
    });

    logger.info('Wallet unfrozen', { walletId });
  }

  async getWalletStatement(
    walletId: string,
    options?: { startDate?: Date; endDate?: Date; limit?: number; offset?: number }
  ) {
    const where: any = { walletId };
    
    if (options?.startDate || options?.endDate) {
      where.createdAt = {};
      if (options?.startDate) where.createdAt.gte = options.startDate;
      if (options?.endDate) where.createdAt.lte = options.endDate;
    }

    return prisma.walletStatements.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: options?.limit || 50,
      skip: options?.offset || 0,
    });
  }

  async checkLimits(walletId: string, amount: bigint): Promise<{ allowed: boolean; reason?: string }> {
    const limits = await prisma.walletLimits.findUnique({ where: { walletId } });
    if (!limits) return { allowed: true };

    if (amount > limits.singleTransactionLimit) {
      return { allowed: false, reason: 'Amount exceeds single transaction limit' };
    }

    const today = new Date();
    const resetDate = new Date(limits.resetAt || today);
    
    if (today > resetDate) {
      await prisma.walletLimits.update({
        where: { walletId },
        data: {
          dailyUsed: BigInt(0),
          monthlyUsed: BigInt(0),
          resetAt: new Date(new Date().setDate(new Date().getDate() + 1)),
        },
      });
    }

    if (amount + limits.dailyUsed > limits.dailyLimit) {
      return { allowed: false, reason: 'Amount exceeds daily limit' };
    }

    if (amount + limits.monthlyUsed > limits.monthlyLimit) {
      return { allowed: false, reason: 'Amount exceeds monthly limit' };
    }

    return { allowed: true };
  }

  async updateLimitUsage(walletId: string, amount: bigint): Promise<void> {
    await prisma.walletLimits.update({
      where: { walletId },
      data: {
        dailyUsed: { increment: amount },
        monthlyUsed: { increment: amount },
      },
    });
  }
}

export const walletService = new WalletService();
