import express from 'express';
import { z } from 'zod';

import { pool } from '../db/pool.js';
import { validate } from '../middleware/validate.js';
import { deductFromWallet } from '../services/wallets.js';
import { toDateOnly } from '../utils/dates.js';
import { newId } from '../utils/ids.js';

export const expensesRouter = express.Router();

const expenseSchema = z.object({
  amount: z.number().positive(),
  categoryId: z.string().uuid().nullable().optional(),
  category: z.string().trim().min(1).max(120),
  walletType: z.enum(['needs', 'savings', 'wants']),
  date: z.coerce.date(),
  note: z.string().trim().max(500).optional().default(''),
});

expensesRouter.post('/expenses', validate(expenseSchema), async (req, res, next) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    if (req.body.categoryId) {
      const [categories] = await connection.query(
        'SELECT id FROM categories WHERE id = ? AND user_id = ?',
        [req.body.categoryId, req.user.id],
      );
      if (categories.length === 0) {
        await connection.rollback();
        return res.status(404).json({ error: 'Category not found' });
      }
    }
    await deductFromWallet(connection, req.user.id, req.body.walletType, req.body.amount);
    const id = newId();
    await connection.query(
      `INSERT INTO expenses (id, user_id, amount, category_id, category_name, wallet_type, expense_date, note)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        id,
        req.user.id,
        req.body.amount,
        req.body.categoryId ?? null,
        req.body.category,
        req.body.walletType,
        toDateOnly(req.body.date),
        req.body.note,
      ],
    );
    await connection.commit();
    return res.status(201).json({ expense: { id, ...req.body, date: toDateOnly(req.body.date) } });
  } catch (error) {
    await connection.rollback();
    if (error.status) return res.status(error.status).json({ error: error.message });
    return next(error);
  } finally {
    connection.release();
  }
});

expensesRouter.get('/expenses', async (req, res, next) => {
  try {
    const [rows] = await pool.query(
      `SELECT id, amount, category_id AS categoryId, category_name AS category, wallet_type AS walletType,
              expense_date AS date, note, created_at AS createdAt
       FROM expenses
       WHERE user_id = ?
       ORDER BY expense_date DESC, created_at DESC`,
      [req.user.id],
    );
    return res.json({ expenses: rows.map((row) => ({ ...row, amount: Number(row.amount) })) });
  } catch (error) {
    return next(error);
  }
});
