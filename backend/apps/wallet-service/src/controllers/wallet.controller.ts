import { walletService } from '../services/wallet.service';
import { createLogger } from '@upaying/logger';

const logger = createLogger('WalletController');

export interface CreateWalletRequest {
  userId: string;
  currency?: string;
  walletType?: 'main' | 'savings' | 'escrow' | 'merchant';
}

export interface TransferRequest {
  senderWalletId: string;
  receiverWalletId: string;
  amount: number;
  reference: string;
  description?: string;
}

export interface CreditDebitRequest {
  walletId: string;
  amount: number;
  reference: string;
  description?: string;
}

export class WalletController {
  async createWallet(req: CreateWalletRequest) {
    try {
      const wallet = await walletService.createWallet({
        userId: req.userId,
        currency: req.currency,
        walletType: req.walletType,
      });
      
      logger.info('Wallet created via API', { userId: req.userId });
      return { success: true, data: wallet };
    } catch (error) {
      logger.error('Failed to create wallet', { error: String(error), userId: req.userId });
      return { success: false, error: String(error) };
    }
  }

  async getWallet(walletId: string) {
    try {
      const wallet = await walletService.getWalletById(walletId);
      if (!wallet) {
        return { success: false, error: 'Wallet not found' };
      }
      return { success: true, data: wallet };
    } catch (error) {
      logger.error('Failed to get wallet', { error: String(error), walletId });
      return { success: false, error: String(error) };
    }
  }

  async getWalletByAccountNumber(accountNumber: string) {
    try {
      const wallet = await walletService.getWalletByAccountNumber(accountNumber);
      if (!wallet) {
        return { success: false, error: 'Wallet not found' };
      }
      return { success: true, data: wallet };
    } catch (error) {
      logger.error('Failed to get wallet', { error: String(error), accountNumber });
      return { success: false, error: String(error) };
    }
  }

  async getUserWallets(userId: string, walletType?: string) {
    try {
      const wallets = await walletService.getWalletByUserId(userId, walletType);
      return { success: true, data: wallets };
    } catch (error) {
      logger.error('Failed to get user wallets', { error: String(error), userId });
      return { success: false, error: String(error) };
    }
  }

  async transfer(req: TransferRequest) {
    try {
      const limitCheck = await walletService.checkLimits(req.senderWalletId, BigInt(req.amount));
      if (!limitCheck.allowed) {
        return { success: false, error: limitCheck.reason };
      }

      await walletService.transfer({
        senderWalletId: req.senderWalletId,
        receiverWalletId: req.receiverWalletId,
        amount: BigInt(req.amount),
        reference: req.reference,
        description: req.description,
      });

      await walletService.updateLimitUsage(req.senderWalletId, BigInt(req.amount));

      logger.info('Transfer completed via API', { 
        senderWalletId: req.senderWalletId,
        receiverWalletId: req.receiverWalletId,
        amount: req.amount,
        reference: req.reference 
      });
      
      return { success: true, data: { reference: req.reference } };
    } catch (error) {
      logger.error('Failed to transfer', { error: String(error), reference: req.reference });
      return { success: false, error: String(error) };
    }
  }

  async creditWallet(req: CreditDebitRequest) {
    try {
      await walletService.creditWallet(
        req.walletId,
        BigInt(req.amount),
        req.reference,
        req.description
      );
      
      logger.info('Wallet credited via API', { walletId: req.walletId, amount: req.amount });
      return { success: true, data: { reference: req.reference } };
    } catch (error) {
      logger.error('Failed to credit wallet', { error: String(error), walletId: req.walletId });
      return { success: false, error: String(error) };
    }
  }

  async debitWallet(req: CreditDebitRequest) {
    try {
      await walletService.debitWallet(
        req.walletId,
        BigInt(req.amount),
        req.reference,
        req.description
      );
      
      logger.info('Wallet debited via API', { walletId: req.walletId, amount: req.amount });
      return { success: true, data: { reference: req.reference } };
    } catch (error) {
      logger.error('Failed to debit wallet', { error: String(error), walletId: req.walletId });
      return { success: false, error: String(error) };
    }
  }

  async freezeWallet(walletId: string, freezeType: string, reason: string, userId: string) {
    try {
      await walletService.freezeWallet(walletId, freezeType as any, reason, userId);
      return { success: true };
    } catch (error) {
      logger.error('Failed to freeze wallet', { error: String(error), walletId });
      return { success: false, error: String(error) };
    }
  }

  async unfreezeWallet(walletId: string, userId: string) {
    try {
      await walletService.unfreezeWallet(walletId, userId);
      return { success: true };
    } catch (error) {
      logger.error('Failed to unfreeze wallet', { error: String(error), walletId });
      return { success: false, error: String(error) };
    }
  }

  async getStatement(walletId: string, options?: { startDate?: string; endDate?: string; limit?: number }) {
    try {
      const statement = await walletService.getWalletStatement(walletId, {
        startDate: options?.startDate ? new Date(options.startDate) : undefined,
        endDate: options?.endDate ? new Date(options.endDate) : undefined,
        limit: options?.limit,
      });
      return { success: true, data: statement };
    } catch (error) {
      logger.error('Failed to get statement', { error: String(error), walletId });
      return { success: false, error: String(error) };
    }
  }
}

export const walletController = new WalletController();
