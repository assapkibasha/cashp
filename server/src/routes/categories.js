import express from 'express';
import { z } from 'zod';

import { pool } from '../db/pool.js';
import { validate } from '../middleware/validate.js';
import { newId } from '../utils/ids.js';

export const categoriesRouter = express.Router();

const categorySchema = z.object({
  name: z.string().trim().min(1).max(120),
  kind: z.enum(['expense', 'income']).default('expense'),
  color: z.string().trim().max(16).nullable().optional(),
  icon: z.string().trim().max(64).nullable().optional(),
});

categoriesRouter.get('/categories', async (req, res, next) => {
  try {
    const [rows] = await pool.query(
      `SELECT id, name, kind, color, icon, created_at AS createdAt
       FROM categories
       WHERE user_id = ?
       ORDER BY kind, name`,
      [req.user.id],
    );
    return res.json({ categories: rows });
  } catch (error) {
    return next(error);
  }
});

categoriesRouter.post('/categories', validate(categorySchema), async (req, res, next) => {
  try {
    const id = newId();
    await pool.query(
      `INSERT INTO categories (id, user_id, name, kind, color, icon)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [id, req.user.id, req.body.name, req.body.kind, req.body.color ?? null, req.body.icon ?? null],
    );
    return res.status(201).json({ category: { id, ...req.body } });
  } catch (error) {
    return next(error);
  }
});
