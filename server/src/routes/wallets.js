import express from 'express';

import { pool } from '../db/pool.js';

export const walletsRouter = express.Router();

walletsRouter.get('/wallets', async (req, res, next) => {
  try {
    const [rows] = await pool.query(
      `SELECT id, type, name, balance
       FROM wallets
       WHERE user_id = ?
       ORDER BY FIELD(type, 'needs', 'savings', 'wants')`,
      [req.user.id],
    );
    return res.json({ wallets: rows.map((row) => ({ ...row, balance: Number(row.balance) })) });
  } catch (error) {
    return next(error);
  }
});
