import express from 'express';
import { z } from 'zod';

import { pool } from '../db/pool.js';
import { validate } from '../middleware/validate.js';
import { addToWallet } from '../services/wallets.js';
import { toDateOnly } from '../utils/dates.js';
import { newId } from '../utils/ids.js';

export const incomesRouter = express.Router();

const incomeSchema = z.object({
  amount: z.number().positive(),
  source: z.string().trim().min(1).max(120),
  date: z.coerce.date(),
  note: z.string().trim().max(500).optional().default(''),
});

incomesRouter.post('/incomes', validate(incomeSchema), async (req, res, next) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [settingsRows] = await connection.query(
      `SELECT needs_percentage AS needsPercentage,
              savings_percentage AS savingsPercentage,
              wants_percentage AS wantsPercentage
       FROM user_settings
       WHERE user_id = ?
       FOR UPDATE`,
      [req.user.id],
    );
    const settings = settingsRows[0];
    const id = newId();
    await connection.query(
      `INSERT INTO incomes (id, user_id, amount, source, income_date, note)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [id, req.user.id, req.body.amount, req.body.source, toDateOnly(req.body.date), req.body.note],
    );
    await addToWallet(connection, req.user.id, 'needs', req.body.amount * Number(settings.needsPercentage) / 100);
    await addToWallet(connection, req.user.id, 'savings', req.body.amount * Number(settings.savingsPercentage) / 100);
    await addToWallet(connection, req.user.id, 'wants', req.body.amount * Number(settings.wantsPercentage) / 100);
    await connection.commit();
    return res.status(201).json({ income: { id, ...req.body, date: toDateOnly(req.body.date) } });
  } catch (error) {
    await connection.rollback();
    return next(error);
  } finally {
    connection.release();
  }
});

incomesRouter.get('/incomes', async (req, res, next) => {
  try {
    const [rows] = await pool.query(
      `SELECT id, amount, source, income_date AS date, note, created_at AS createdAt
       FROM incomes
       WHERE user_id = ?
       ORDER BY income_date DESC, created_at DESC`,
      [req.user.id],
    );
    return res.json({ incomes: rows.map((row) => ({ ...row, amount: Number(row.amount) })) });
  } catch (error) {
    return next(error);
  }
});
