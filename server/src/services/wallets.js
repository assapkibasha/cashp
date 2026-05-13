export async function getWalletBalance(connection, userId, type) {
  const [rows] = await connection.query(
    'SELECT balance FROM wallets WHERE user_id = ? AND type = ? FOR UPDATE',
    [userId, type],
  );
  if (rows.length === 0) return null;
  return Number(rows[0].balance);
}

export async function addToWallet(connection, userId, type, amount) {
  await connection.query(
    'UPDATE wallets SET balance = balance + ? WHERE user_id = ? AND type = ?',
    [amount, userId, type],
  );
}

export async function deductFromWallet(connection, userId, type, amount) {
  const balance = await getWalletBalance(connection, userId, type);
  if (balance === null) {
    const error = new Error('Wallet not found');
    error.status = 404;
    throw error;
  }
  if (amount > balance) {
    const error = new Error('Insufficient wallet balance');
    error.status = 409;
    throw error;
  }
  await connection.query(
    'UPDATE wallets SET balance = balance - ? WHERE user_id = ? AND type = ?',
    [amount, userId, type],
  );
}
