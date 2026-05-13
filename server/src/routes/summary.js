import express from 'express';

import { pool } from '../db/pool.js';

export const summaryRouter = express.Router();

summaryRouter.get('/summary', async (req, res, next) => {
  try {
    const [wallets] = await pool.query(
      `SELECT type, name, balance
       FROM wallets
       WHERE user_id = ?
       ORDER BY FIELD(type, 'needs', 'savings', 'wants')`,
      [req.user.id],
    );
    const [monthIncome] = await pool.query(
      `SELECT COALESCE(SUM(amount), 0) AS total
       FROM incomes
       WHERE user_id = ? AND YEAR(income_date) = YEAR(CURRENT_DATE()) AND MONTH(income_date) = MONTH(CURRENT_DATE())`,
      [req.user.id],
    );
    const [monthExpenses] = await pool.query(
      `SELECT COALESCE(SUM(amount), 0) AS total
       FROM expenses
       WHERE user_id = ? AND YEAR(expense_date) = YEAR(CURRENT_DATE()) AND MONTH(expense_date) = MONTH(CURRENT_DATE())`,
      [req.user.id],
    );
    const [categoryRows] = await pool.query(
      `SELECT category_name AS category, SUM(amount) AS amount
       FROM expenses
       WHERE user_id = ? AND YEAR(expense_date) = YEAR(CURRENT_DATE()) AND MONTH(expense_date) = MONTH(CURRENT_DATE())
       GROUP BY category_name
       ORDER BY amount DESC`,
      [req.user.id],
    );
    const [walletRows] = await pool.query(
      `SELECT wallet_type AS walletType, SUM(amount) AS amount
       FROM expenses
       WHERE user_id = ? AND YEAR(expense_date) = YEAR(CURRENT_DATE()) AND MONTH(expense_date) = MONTH(CURRENT_DATE())
       GROUP BY wallet_type`,
      [req.user.id],
    );

    return res.json({
      wallets: wallets.map((row) => ({ ...row, balance: Number(row.balance) })),
      monthlyIncome: Number(monthIncome[0].total),
      monthlyExpenses: Number(monthExpenses[0].total),
      spendingByCategory: categoryRows.map((row) => ({ ...row, amount: Number(row.amount) })),
      spendingByWallet: walletRows.map((row) => ({ ...row, amount: Number(row.amount) })),
    });
  } catch (error) {
    return next(error);
  }
});
