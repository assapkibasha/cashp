import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

import { mysql2Uri } from './databaseUrl.js';

dotenv.config();

const databaseUrl = process.env.DATABASE_URL;
const rejectUnauthorized = process.env.DB_SSL_REJECT_UNAUTHORIZED !== 'false';

if (!databaseUrl) {
  throw new Error('DATABASE_URL is required');
}

const url = new URL(databaseUrl);
const targetDatabase = process.env.DB_NAME || 'cashGuard';
const originalDatabase = url.pathname.replace('/', '') || 'defaultdb';

async function main() {
  const bootstrap = await mysql.createConnection({
    uri: mysql2Uri(databaseUrl, originalDatabase),
    ssl: { rejectUnauthorized },
    multipleStatements: true,
  });

  await bootstrap.query(`CREATE DATABASE IF NOT EXISTS \`${targetDatabase}\``);
  await bootstrap.end();

  const connection = await mysql.createConnection({
    uri: mysql2Uri(databaseUrl, targetDatabase),
    ssl: { rejectUnauthorized },
    multipleStatements: true,
  });

  const dirname = path.dirname(fileURLToPath(import.meta.url));
  const schema = await fs.readFile(path.join(dirname, 'schema.sql'), 'utf8');
  await connection.query(schema);
  await connection.end();

  console.log(`Migrated database ${targetDatabase}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
