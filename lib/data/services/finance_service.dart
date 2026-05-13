import '../../core/utils/date_helpers.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/user_settings.dart';
import '../models/wallet.dart';
import '../models/wallet_type.dart';

class FinanceService {
  static Map<WalletType, double> splitIncome(double amount, UserSettings settings) {
    return {
      WalletType.needs: amount * settings.needsPercentage / 100,
      WalletType.savings: amount * settings.savingsPercentage / 100,
      WalletType.wants: amount * settings.wantsPercentage / 100,
    };
  }

  static double totalBalance(List<Wallet> wallets) {
    return wallets.fold(0, (sum, wallet) => sum + wallet.balance);
  }

  static double safeDailyNeedsSpending(List<Wallet> wallets, DateTime now) {
    final needs = walletBalance(wallets, WalletType.needs);
    return needs / DateHelpers.daysLeftInMonth(now);
  }

  static double todayNeedsSpending(List<Expense> expenses, DateTime now) {
    return expenses
        .where(
          (expense) =>
              expense.walletType == WalletType.needs &&
              DateHelpers.isSameDay(expense.date, now),
        )
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  static double walletBalance(List<Wallet> wallets, WalletType type) {
    return wallets.firstWhere((wallet) => wallet.type == type).balance;
  }

  static double monthlyIncome(List<Income> incomes, DateTime now) {
    return incomes
        .where((income) => DateHelpers.isSameMonth(income.date, now))
        .fold(0, (sum, income) => sum + income.amount);
  }

  static double monthlyExpenses(List<Expense> expenses, DateTime now) {
    return expenses
        .where((expense) => DateHelpers.isSameMonth(expense.date, now))
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  static Map<String, double> spendingByCategory(List<Expense> expenses, DateTime now) {
    final totals = <String, double>{};
    for (final expense in expenses.where((e) => DateHelpers.isSameMonth(e.date, now))) {
      totals.update(expense.category, (value) => value + expense.amount, ifAbsent: () => expense.amount);
    }
    return totals;
  }

  static Map<WalletType, double> spendingByWallet(List<Expense> expenses, DateTime now) {
    final totals = <WalletType, double>{};
    for (final expense in expenses.where((e) => DateHelpers.isSameMonth(e.date, now))) {
      totals.update(expense.walletType, (value) => value + expense.amount, ifAbsent: () => expense.amount);
    }
    return totals;
  }
}
