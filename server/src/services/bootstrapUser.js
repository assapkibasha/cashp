import { newId } from '../utils/ids.js';

const defaultCategories = [
  'Food',
  'Transport',
  'Airtime/Internet',
  'Rent',
  'Family Support',
  'School',
  'Clothing',
  'Entertainment',
  'Health',
  'Other',
];

export async function bootstrapUserData(connection, userId) {
  await connection.query(
    `INSERT INTO user_settings (user_id, currency, needs_percentage, savings_percentage, wants_percentage)
     VALUES (?, 'RWF', 60, 20, 20)`,
    [userId],
  );

  await connection.query(
    `INSERT INTO wallets (id, user_id, type, name, balance)
     VALUES (?, ?, 'needs', 'Needs', 0), (?, ?, 'savings', 'Savings', 0), (?, ?, 'wants', 'Wants', 0)`,
    [newId(), userId, newId(), userId, newId(), userId],
  );

  for (const category of defaultCategories) {
    await connection.query(
      `INSERT INTO categories (id, user_id, name, kind) VALUES (?, ?, ?, 'expense')`,
      [newId(), userId, category],
    );
  }
}
