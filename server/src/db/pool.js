import mysql from 'mysql2/promise';

import { config } from '../config.js';
import { mysql2Uri } from './databaseUrl.js';

export const pool = mysql.createPool({
  uri: mysql2Uri(config.databaseUrl, config.dbName),
  waitForConnections: true,
  connectionLimit: 10,
  maxIdle: 10,
  idleTimeout: 60000,
  enableKeepAlive: true,
  ssl: { rejectUnauthorized: config.dbSslRejectUnauthorized },
  namedPlaceholders: true,
});
