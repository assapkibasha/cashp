import express from 'express';

import { pool } from '../db/pool.js';

export const meRouter = express.Router();

meRouter.get('/me', async (req, res, next) => {
  try {
    const [users] = await pool.query(
      'SELECT id, email, display_name AS displayName, created_at AS createdAt FROM users WHERE id = ?',
      [req.user.id],
    );
    if (users.length === 0) return res.status(404).json({ error: 'User not found' });
    return res.json({ user: users[0] });
  } catch (error) {
    return next(error);
  }
});
