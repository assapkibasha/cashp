import express from 'express';

import { pool } from '../db/pool.js';

export const transactionsRouter = express.Router();

transactionsRouter.get('/transactions', async (req, res, next) => {
  try {
    const [rows] = await pool.query(
      `SELECT id, 'income' AS type, source AS title, amount, income_date AS date, NULL AS walletType, NULL AS category, note, created_at AS createdAt
       FROM incomes
       WHERE user_id = ?
       UNION ALL
       SELECT id, 'expense' AS type, category_name AS title, amount, expense_date AS date, wallet_type AS walletType, category_name AS category, note, created_at AS createdAt
       FROM expenses
       WHERE user_id = ?
       UNION ALL
       SELECT gc.id, 'goalContribution' AS type, sg.name AS title, gc.amount, gc.contribution_date AS date, 'savings' AS walletType, NULL AS category, '' AS note, gc.created_at AS createdAt
       FROM goal_contributions gc
       INNER JOIN savings_goals sg ON sg.id = gc.goal_id AND sg.user_id = gc.user_id
       WHERE gc.user_id = ?
       ORDER BY createdAt DESC`,
      [req.user.id, req.user.id, req.user.id],
    );
    return res.json({ transactions: rows.map((row) => ({ ...row, amount: Number(row.amount) })) });
  } catch (error) {
    return next(error);
  }
});
