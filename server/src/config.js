import dotenv from 'dotenv';

dotenv.config();

export const config = {
  port: Number(process.env.PORT || 8080),
  databaseUrl: process.env.DATABASE_URL,
  dbName: process.env.DB_NAME,
  dbSslRejectUnauthorized: process.env.DB_SSL_REJECT_UNAUTHORIZED !== 'false',
  jwtSecret: process.env.JWT_SECRET,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  corsOrigin: process.env.CORS_ORIGIN || '*',
};

if (!config.databaseUrl) {
  throw new Error('DATABASE_URL is required');
}

if (!config.jwtSecret || config.jwtSecret.length < 32) {
  throw new Error('JWT_SECRET must be at least 32 characters');
}
