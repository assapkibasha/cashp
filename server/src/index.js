import cors from 'cors';
import express from 'express';
import helmet from 'helmet';

import { config } from './config.js';
import { requireAuth } from './middleware/auth.js';
import { errorHandler, notFound } from './middleware/errors.js';
import { authRouter } from './routes/auth.js';
import { categoriesRouter } from './routes/categories.js';
import { expensesRouter } from './routes/expenses.js';
import { goalsRouter } from './routes/goals.js';
import { incomesRouter } from './routes/incomes.js';
import { meRouter } from './routes/me.js';
import { settingsRouter } from './routes/settings.js';
import { summaryRouter } from './routes/summary.js';
import { transactionsRouter } from './routes/transactions.js';
import { walletsRouter } from './routes/wallets.js';

const app = express();

app.use(helmet());
app.use(cors({ origin: config.corsOrigin === '*' ? true : config.corsOrigin }));
app.use(express.json({ limit: '256kb' }));

app.get('/health', (_req, res) => res.json({ ok: true }));
app.use('/auth', authRouter);
app.use(requireAuth);
app.use(meRouter);
app.use(settingsRouter);
app.use(categoriesRouter);
app.use(walletsRouter);
app.use(incomesRouter);
app.use(expensesRouter);
app.use(goalsRouter);
app.use(summaryRouter);
app.use(transactionsRouter);
app.use(notFound);
app.use(errorHandler);

app.listen(config.port, () => {
  console.log(`CashGuard API listening on port ${config.port}`);
});
