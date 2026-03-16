import express, { Request, Response } from 'express';
import walletRoutes from './routes/wallet.routes';

const app = express();

app.use(express.json());

app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', service: 'wallet-service' });
});

app.use('/api/v1', walletRoutes);

app.use((err: Error, req: Request, res: Response, next: Function) => {
  console.error('Error:', err.message);
  res.status(500).json({ success: false, error: 'Internal server error' });
});

export default app;
