export const config = {
  database: {
    url: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/upaying',
  },
  redis: {
    url: process.env.REDIS_URL || 'redis://localhost:6379',
  },
  jwt: {
    secret: process.env.JWT_SECRET || 'your-secret-key-change-in-production',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },
  server: {
    port: parseInt(process.env.PORT || '3000', 10),
    host: process.env.HOST || '0.0.0.0',
  },
  limits: {
    minTransferAmount: 100,
    maxTransferAmount: 5000000,
    dailyLimit: 5000000,
    monthlyLimit: 20000000,
  },
  fees: {
    platformFeePercentage: 0.015,
    transactionFeeFlat: 0,
  },
};
