import express from 'express';
import { z } from 'zod';

import { pool } from '../db/pool.js';
import { validate } from '../middleware/validate.js';

export const settingsRouter = express.Router();

const settingsSchema = z.object({
  currency: z.string().trim().min(1).max(8).transform((value) => value.toUpperCase()),
  monthlyIncomeExpectation: z.number().positive().nullable().optional(),
  needsPercentage: z.number().int().min(0).max(100),
  savingsPercentage: z.number().int().min(0).max(100),
  wantsPercentage: z.number().int().min(0).max(100),
  themeMode: z.enum(['system', 'light', 'dark']),
  setupCompleted: z.boolean(),
}).refine(
  (value) => value.needsPercentage + value.savingsPercentage + value.wantsPercentage === 100,
  'Budget split must total 100',
);

settingsRouter.get('/settings', async (req, res, next) => {
  try {
    const [rows] = await pool.query(
      `SELECT currency,
              monthly_income_expectation AS monthlyIncomeExpectation,
              needs_percentage AS needsPercentage,
              savings_percentage AS savingsPercentage,
              wants_percentage AS wantsPercentage,
              theme_mode AS themeMode,
              setup_completed AS setupCompleted
       FROM user_settings
       WHERE user_id = ?`,
      [req.user.id],
    );
    return res.json({ settings: rows[0] });
  } catch (error) {
    return next(error);
  }
});

settingsRouter.put('/settings', validate(settingsSchema), async (req, res, next) => {
  try {
    await pool.query(
      `UPDATE user_settings
       SET currency = ?,
           monthly_income_expectation = ?,
           needs_percentage = ?,
           savings_percentage = ?,
           wants_percentage = ?,
           theme_mode = ?,
           setup_completed = ?
       WHERE user_id = ?`,
      [
        req.body.currency,
        req.body.monthlyIncomeExpectation ?? null,
        req.body.needsPercentage,
        req.body.savingsPercentage,
        req.body.wantsPercentage,
        req.body.themeMode,
        req.body.setupCompleted,
        req.user.id,
      ],
    );
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
});
