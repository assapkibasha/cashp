import bcrypt from 'bcryptjs';
import express from 'express';
import jwt from 'jsonwebtoken';
import { z } from 'zod';

import { config } from '../config.js';
import { pool } from '../db/pool.js';
import { validate } from '../middleware/validate.js';
import { bootstrapUserData } from '../services/bootstrapUser.js';
import { newId } from '../utils/ids.js';

export const authRouter = express.Router();

const credentialsSchema = z.object({
  email: z.string().email().transform((value) => value.toLowerCase()),
  password: z.string().min(8),
  displayName: z.string().trim().min(1).max(120).optional(),
});

const loginSchema = credentialsSchema.pick({ email: true, password: true });

authRouter.post('/register', validate(credentialsSchema), async (req, res, next) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const userId = newId();
    const passwordHash = await bcrypt.hash(req.body.password, 12);
    await connection.query(
      'INSERT INTO users (id, email, password_hash, display_name) VALUES (?, ?, ?, ?)',
      [userId, req.body.email, passwordHash, req.body.displayName || null],
    );
    await bootstrapUserData(connection, userId);
    await connection.commit();
    res.status(201).json(tokenResponse(userId, req.body.email));
  } catch (error) {
    await connection.rollback();
    next(error);
  } finally {
    connection.release();
  }
});

authRouter.post('/login', validate(loginSchema), async (req, res, next) => {
  try {
    const [rows] = await pool.query(
      'SELECT id, email, password_hash FROM users WHERE email = ?',
      [req.body.email],
    );
    const user = rows[0];
    if (!user || !(await bcrypt.compare(req.body.password, user.password_hash))) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    return res.json(tokenResponse(user.id, user.email));
  } catch (error) {
    return next(error);
  }
});

function tokenResponse(userId, email) {
  const token = jwt.sign({ email }, config.jwtSecret, {
    subject: userId,
    expiresIn: config.jwtExpiresIn,
  });
  return { token, user: { id: userId, email } };
}
