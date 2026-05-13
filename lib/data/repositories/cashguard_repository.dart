import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';
import '../models/goal_contribution.dart';
import '../models/income.dart';
import '../models/savings_goal.dart';
import '../models/transaction_record.dart';
import '../models/user_settings.dart';
import '../models/wallet.dart';
import '../models/wallet_type.dart';
import '../services/finance_service.dart';

class CashguardRepository extends ChangeNotifier {
  CashguardRepository(this._preferences);

  static const _settingsKey = 'cashguard_settings';
  static const _walletsKey = 'cashguard_wallets';
  static const _incomesKey = 'cashguard_incomes';
  static const _expensesKey = 'cashguard_expenses';
  static const _goalsKey = 'cashguard_goals';
  static const _contributionsKey = 'cashguard_contributions';

  final SharedPreferences _preferences;

  UserSettings settings = UserSettings.defaults();
  List<Wallet> wallets = _defaultWallets();
  List<Income> incomes = [];
  List<Expense> expenses = [];
  List<SavingsGoal> goals = [];
  List<GoalContribution> contributions = [];

  static Future<CashguardRepository> create() async {
    final preferences = await SharedPreferences.getInstance();
    final repository = CashguardRepository(preferences);
    repository.load();
    return repository;
  }

  void load() {
    final settingsJson = _preferences.getString(_settingsKey);
    if (settingsJson != null) {
      settings = UserSettings.fromJson(jsonDecode(settingsJson) as Map<String, dynamic>);
    }

    wallets = _readList(_walletsKey, Wallet.fromJson);
    if (wallets.isEmpty) wallets = _defaultWallets();

    incomes = _readList(_incomesKey, Income.fromJson);
    expenses = _readList(_expensesKey, Expense.fromJson);
    goals = _readList(_goalsKey, SavingsGoal.fromJson);
    contributions = _readList(_contributionsKey, GoalContribution.fromJson);
  }

  bool get setupCompleted => settings.setupCompleted;
  double get totalBalance => FinanceService.totalBalance(wallets);
  double walletBalance(WalletType type) => FinanceService.walletBalance(wallets, type);

  List<TransactionRecord> get transactions {
    final records = <TransactionRecord>[
      ...incomes.map(
        (income) => TransactionRecord(
          id: income.id,
          type: TransactionType.income,
          title: income.source,
          amount: income.amount,
          date: income.date,
          createdAt: income.createdAt,
          note: income.note,
        ),
      ),
      ...expenses.map(
        (expense) => TransactionRecord(
          id: expense.id,
          type: TransactionType.expense,
          title: expense.category,
          amount: expense.amount,
          date: expense.date,
          createdAt: expense.createdAt,
          walletType: expense.walletType,
          category: expense.category,
          note: expense.note,
        ),
      ),
      ...contributions.map(
        (contribution) => TransactionRecord(
          id: contribution.id,
          type: TransactionType.goalContribution,
          title: contribution.goalName,
          amount: contribution.amount,
          date: contribution.date,
          createdAt: contribution.createdAt,
          walletType: WalletType.savings,
        ),
      ),
    ];
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  Future<void> completeSetup(UserSettings newSettings) async {
    settings = newSettings.copyWith(setupCompleted: true);
    await _saveAll();
    notifyListeners();
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    settings = newSettings;
    await _saveAll();
    notifyListeners();
  }

  Future<void> addIncome({
    required double amount,
    required String source,
    required DateTime date,
    required String note,
  }) async {
    final income = Income(
      id: _id(),
      amount: amount,
      source: source,
      date: date,
      note: note,
      createdAt: DateTime.now(),
    );
    incomes = [...incomes, income];
    final split = FinanceService.splitIncome(amount, settings);
    wallets = wallets
        .map((wallet) => wallet.copyWith(balance: wallet.balance + (split[wallet.type] ?? 0)))
        .toList();
    await _saveAll();
    notifyListeners();
  }

  Future<String?> addExpense({
    required double amount,
    required String category,
    required WalletType walletType,
    required DateTime date,
    required String note,
  }) async {
    final currentBalance = walletBalance(walletType);
    if (amount > currentBalance) {
      return '${walletType.label} wallet only has ${currentBalance.round()} ${settings.currency}.';
    }
    final expense = Expense(
      id: _id(),
      amount: amount,
      category: category,
      walletType: walletType,
      date: date,
      note: note,
      createdAt: DateTime.now(),
    );
    expenses = [...expenses, expense];
    wallets = wallets
        .map((wallet) => wallet.type == walletType
            ? wallet.copyWith(balance: wallet.balance - amount)
            : wallet)
        .toList();
    await _saveAll();
    notifyListeners();
    return null;
  }

  Future<void> addGoal({
    required String name,
    required double targetAmount,
    required double currentSavedAmount,
    DateTime? deadline,
  }) async {
    goals = [
      ...goals,
      SavingsGoal(
        id: _id(),
        name: name,
        targetAmount: targetAmount,
        savedAmount: currentSavedAmount,
        deadline: deadline,
        createdAt: DateTime.now(),
      ),
    ];
    await _saveAll();
    notifyListeners();
  }

  Future<String?> contributeToGoal(SavingsGoal goal, double amount) async {
    if (amount > walletBalance(WalletType.savings)) {
      return 'Savings wallet does not have enough money for this contribution.';
    }
    wallets = wallets
        .map((wallet) => wallet.type == WalletType.savings
            ? wallet.copyWith(balance: wallet.balance - amount)
            : wallet)
        .toList();
    goals = goals
        .map((item) => item.id == goal.id
            ? item.copyWith(savedAmount: item.savedAmount + amount)
            : item)
        .toList();
    contributions = [
      ...contributions,
      GoalContribution(
        id: _id(),
        goalId: goal.id,
        goalName: goal.name,
        amount: amount,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    ];
    await _saveAll();
    notifyListeners();
    return null;
  }

  Future<void> resetData() async {
    settings = UserSettings.defaults();
    wallets = _defaultWallets();
    incomes = [];
    expenses = [];
    goals = [];
    contributions = [];
    await _saveAll();
    notifyListeners();
  }

  Future<void> _saveAll() async {
    await _preferences.setString(_settingsKey, jsonEncode(settings.toJson()));
    await _saveList(_walletsKey, wallets.map((wallet) => wallet.toJson()).toList());
    await _saveList(_incomesKey, incomes.map((income) => income.toJson()).toList());
    await _saveList(_expensesKey, expenses.map((expense) => expense.toJson()).toList());
    await _saveList(_goalsKey, goals.map((goal) => goal.toJson()).toList());
    await _saveList(
      _contributionsKey,
      contributions.map((contribution) => contribution.toJson()).toList(),
    );
  }

  Future<void> _saveList(String key, List<Map<String, dynamic>> value) {
    return _preferences.setString(key, jsonEncode(value));
  }

  List<T> _readList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _preferences.getString(key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((item) => fromJson(item as Map<String, dynamic>)).toList();
  }

  static List<Wallet> _defaultWallets() => const [
        Wallet(id: 'needs', name: 'Needs', type: WalletType.needs, balance: 0),
        Wallet(id: 'savings', name: 'Savings', type: WalletType.savings, balance: 0),
        Wallet(id: 'wants', name: 'Wants', type: WalletType.wants, balance: 0),
      ];

  static String _id() => DateTime.now().microsecondsSinceEpoch.toString();
}

class CashguardScope extends InheritedNotifier<CashguardRepository> {
  const CashguardScope({
    super.key,
    required CashguardRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static CashguardRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CashguardScope>();
    assert(scope != null, 'CashguardScope not found in context');
    return scope!.notifier!;
  }
}
