import express from 'express';
import { z } from 'zod';

import { pool } from '../db/pool.js';
import { validate } from '../middleware/validate.js';
import { deductFromWallet } from '../services/wallets.js';
import { toDateOnly } from '../utils/dates.js';
import { newId } from '../utils/ids.js';

export const goalsRouter = express.Router();

const goalSchema = z.object({
  name: z.string().trim().min(1).max(160),
  targetAmount: z.number().positive(),
  savedAmount: z.number().min(0).optional().default(0),
  deadline: z.coerce.date().nullable().optional(),
});

const contributionSchema = z.object({
  amount: z.number().positive(),
});

goalsRouter.get('/goals', async (req, res, next) => {
  try {
    const [rows] = await pool.query(
      `SELECT id, name, target_amount AS targetAmount, saved_amount AS savedAmount,
              deadline, created_at AS createdAt
       FROM savings_goals
       WHERE user_id = ?
       ORDER BY created_at DESC`,
      [req.user.id],
    );
    return res.json({
      goals: rows.map((row) => ({
        ...row,
        targetAmount: Number(row.targetAmount),
        savedAmount: Number(row.savedAmount),
      })),
    });
  } catch (error) {
    return next(error);
  }
});

goalsRouter.post('/goals', validate(goalSchema), async (req, res, next) => {
  try {
    const id = newId();
    await pool.query(
      `INSERT INTO savings_goals (id, user_id, name, target_amount, saved_amount, deadline)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        id,
        req.user.id,
        req.body.name,
        req.body.targetAmount,
        req.body.savedAmount,
        req.body.deadline ? toDateOnly(req.body.deadline) : null,
      ],
    );
    return res.status(201).json({ goal: { id, ...req.body } });
  } catch (error) {
    return next(error);
  }
});

goalsRouter.post('/goals/:goalId/contributions', validate(contributionSchema), async (req, res, next) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [goals] = await connection.query(
      'SELECT id, name FROM savings_goals WHERE id = ? AND user_id = ? FOR UPDATE',
      [req.params.goalId, req.user.id],
    );
    if (goals.length === 0) {
      await connection.rollback();
      return res.status(404).json({ error: 'Goal not found' });
    }
    await deductFromWallet(connection, req.user.id, 'savings', req.body.amount);
    await connection.query(
      'UPDATE savings_goals SET saved_amount = saved_amount + ? WHERE id = ? AND user_id = ?',
      [req.body.amount, req.params.goalId, req.user.id],
    );
    const id = newId();
    const date = toDateOnly();
    await connection.query(
      `INSERT INTO goal_contributions (id, user_id, goal_id, amount, contribution_date)
       VALUES (?, ?, ?, ?, ?)`,
      [id, req.user.id, req.params.goalId, req.body.amount, date],
    );
    await connection.commit();
    return res.status(201).json({ contribution: { id, goalId: req.params.goalId, amount: req.body.amount, date } });
  } catch (error) {
    await connection.rollback();
    if (error.status) return res.status(error.status).json({ error: error.message });
    return next(error);
  } finally {
    connection.release();
  }
});
