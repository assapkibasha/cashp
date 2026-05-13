CREATE TABLE IF NOT EXISTS users (
  id CHAR(36) PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  display_name VARCHAR(120) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_settings (
  user_id CHAR(36) PRIMARY KEY,
  currency VARCHAR(8) NOT NULL DEFAULT 'RWF',
  monthly_income_expectation DECIMAL(14, 2) NULL,
  needs_percentage TINYINT UNSIGNED NOT NULL DEFAULT 60,
  savings_percentage TINYINT UNSIGNED NOT NULL DEFAULT 20,
  wants_percentage TINYINT UNSIGNED NOT NULL DEFAULT 20,
  theme_mode ENUM('system', 'light', 'dark') NOT NULL DEFAULT 'system',
  setup_completed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_user_settings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_budget_split_total CHECK (needs_percentage + savings_percentage + wants_percentage = 100)
);

CREATE TABLE IF NOT EXISTS wallets (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  type ENUM('needs', 'savings', 'wants') NOT NULL,
  name VARCHAR(40) NOT NULL,
  balance DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_wallet_user_type (user_id, type),
  INDEX idx_wallets_user (user_id),
  CONSTRAINT fk_wallets_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_wallet_balance_nonnegative CHECK (balance >= 0)
);

CREATE TABLE IF NOT EXISTS categories (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  name VARCHAR(120) NOT NULL,
  kind ENUM('expense', 'income') NOT NULL DEFAULT 'expense',
  color VARCHAR(16) NULL,
  icon VARCHAR(64) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_categories_user_kind_name (user_id, kind, name),
  INDEX idx_categories_user_kind (user_id, kind),
  CONSTRAINT fk_categories_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS incomes (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  amount DECIMAL(14, 2) NOT NULL,
  source VARCHAR(120) NOT NULL,
  income_date DATE NOT NULL,
  note VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_incomes_user_date (user_id, income_date),
  CONSTRAINT fk_incomes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_incomes_amount_positive CHECK (amount > 0)
);

CREATE TABLE IF NOT EXISTS expenses (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  amount DECIMAL(14, 2) NOT NULL,
  category_id CHAR(36) NULL,
  category_name VARCHAR(120) NOT NULL,
  wallet_type ENUM('needs', 'savings', 'wants') NOT NULL,
  expense_date DATE NOT NULL,
  note VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_expenses_user_date (user_id, expense_date),
  INDEX idx_expenses_user_wallet (user_id, wallet_type),
  INDEX idx_expenses_user_category (user_id, category_name),
  CONSTRAINT fk_expenses_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_expenses_category FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
  CONSTRAINT chk_expenses_amount_positive CHECK (amount > 0)
);

CREATE TABLE IF NOT EXISTS savings_goals (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  name VARCHAR(160) NOT NULL,
  target_amount DECIMAL(14, 2) NOT NULL,
  saved_amount DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
  deadline DATE NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_goals_user (user_id),
  CONSTRAINT fk_goals_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_goals_target_positive CHECK (target_amount > 0),
  CONSTRAINT chk_goals_saved_nonnegative CHECK (saved_amount >= 0)
);

CREATE TABLE IF NOT EXISTS goal_contributions (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  goal_id CHAR(36) NOT NULL,
  amount DECIMAL(14, 2) NOT NULL,
  contribution_date DATE NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_contributions_user_date (user_id, contribution_date),
  INDEX idx_contributions_goal (goal_id),
  CONSTRAINT fk_contributions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_contributions_goal FOREIGN KEY (goal_id) REFERENCES savings_goals(id) ON DELETE CASCADE,
  CONSTRAINT chk_contributions_amount_positive CHECK (amount > 0)
);
