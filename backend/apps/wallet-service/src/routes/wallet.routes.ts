import { Router } from 'express';
import { walletController } from '../controllers/wallet.controller';

const router = Router();

router.post('/wallets', async (req, res) => {
  const result = await walletController.createWallet(req.body);
  res.json(result);
});

router.get('/wallets/:id', async (req, res) => {
  const result = await walletController.getWallet(req.params.id);
  res.json(result);
});

router.get('/wallets/account/:accountNumber', async (req, res) => {
  const result = await walletController.getWalletByAccountNumber(req.params.accountNumber);
  res.json(result);
});

router.get('/users/:userId/wallets', async (req, res) => {
  const result = await walletController.getUserWallets(req.params.userId, req.query.type as string);
  res.json(result);
});

router.post('/wallets/transfer', async (req, res) => {
  const result = await walletController.transfer(req.body);
  res.json(result);
});

router.post('/wallets/credit', async (req, res) => {
  const result = await walletController.creditWallet(req.body);
  res.json(result);
});

router.post('/wallets/debit', async (req, res) => {
  const result = await walletController.debitWallet(req.body);
  res.json(result);
});

router.post('/wallets/:id/freeze', async (req, res) => {
  const result = await walletController.freezeWallet(
    req.params.id,
    req.body.freezeType,
    req.body.reason,
    req.body.userId
  );
  res.json(result);
});

router.post('/wallets/:id/unfreeze', async (req, res) => {
  const result = await walletController.unfreezeWallet(req.params.id, req.body.userId);
  res.json(result);
});

router.get('/wallets/:id/statement', async (req, res) => {
  const result = await walletController.getStatement(req.params.id, {
    startDate: req.query.startDate as string,
    endDate: req.query.endDate as string,
    limit: req.query.limit ? parseInt(req.query.limit as string) : undefined,
  });
  res.json(result);
});

export default router;
