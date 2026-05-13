import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/money_formatter.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/wallet_type.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/cashguard_repository.dart';
import '../../data/services/finance_service.dart';
import '../categories/manage_categories_screen.dart';
import '../expenses/add_expense_screen.dart';
import '../goals/add_goal_screen.dart';
import '../goals/goals_screen.dart';
import '../income/add_income_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/transactions_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = CashguardScope.of(context);
    final auth = AuthScope.of(context);
    final currency = repo.settings.currency;
    final safeDaily = FinanceService.safeDailyNeedsSpending(
      repo.wallets,
      DateTime.now(),
    );
    final spentToday = FinanceService.todayNeedsSpending(
      repo.expenses,
      DateTime.now(),
    );
    final remaining = safeDaily - spentToday;
    final insight = remaining >= 0
        ? 'You are still within today\'s safe limit.'
        : 'You are above today\'s safe limit by ${MoneyFormatter.format(remaining.abs(), currency)}.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionsScreen()),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Transactions',
          ),
          PopupMenuButton<_DashboardMenuAction>(
            tooltip: 'Menu',
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (action) => _handleMenuAction(context, action),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: _SignedInMenuHeader(email: auth.email),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _DashboardMenuAction.transactions,
                child: ListTile(
                  leading: Icon(Icons.receipt_long_outlined),
                  title: Text('Transactions'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: _DashboardMenuAction.goals,
                child: ListTile(
                  leading: Icon(Icons.flag_outlined),
                  title: Text('Goals'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: _DashboardMenuAction.reports,
                child: ListTile(
                  leading: Icon(Icons.show_chart),
                  title: Text('Reports'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: _DashboardMenuAction.categories,
                child: ListTile(
                  leading: Icon(Icons.category_outlined),
                  title: Text('Categories'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: _DashboardMenuAction.settings,
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _DashboardMenuAction.signOut,
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sign out'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final walletColumns = constraints.maxWidth < 520 ? 1 : 3;
          final contentPadding = compact
              ? const EdgeInsets.fromLTRB(16, 8, 16, 24)
              : const EdgeInsets.fromLTRB(24, 14, 24, 32);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: ListView(
                padding: contentPadding,
                children: [
                  Semantics(
                    liveRegion: true,
                    label: 'Logged in as ${auth.email ?? 'unknown user'}',
                    child: _UserBanner(email: auth.email),
                  ),
                  const SizedBox(height: 14),
                  _BalanceHero(
                    currency: currency,
                    totalBalance: repo.totalBalance,
                    safeDaily: safeDaily,
                    spentToday: spentToday,
                    remaining: remaining,
                    insight: insight,
                    onAddIncome: () => _open(context, const AddIncomeScreen()),
                    onAddExpense: () =>
                        _open(context, const AddExpenseScreen()),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: walletColumns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: walletColumns == 1 ? 4.2 : 1.35,
                    children: AppConstants.walletOrder.map((type) {
                      return _WalletTile(
                        type: type,
                        amount: repo.walletBalance(type),
                        currency: currency,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  SectionCard(
                    child: Column(
                      children: [
                        _MetricRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Safe daily needs spending',
                          value: MoneyFormatter.format(safeDaily, currency),
                        ),
                        _MetricRow(
                          icon: Icons.local_fire_department_outlined,
                          label: 'Spent today from Needs',
                          value: MoneyFormatter.format(spentToday, currency),
                        ),
                        _MetricRow(
                          icon: Icons.task_alt_outlined,
                          label: 'Remaining safe amount',
                          value: MoneyFormatter.format(
                            remaining.clamp(0, double.infinity),
                            currency,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _QuickActions(
                    onIncome: () => _open(context, const AddIncomeScreen()),
                    onExpense: () => _open(context, const AddExpenseScreen()),
                    onGoal: () => _open(context, const AddGoalScreen()),
                    onTransactions: () =>
                        _open(context, const TransactionsScreen()),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static void _handleMenuAction(
    BuildContext context,
    _DashboardMenuAction action,
  ) {
    switch (action) {
      case _DashboardMenuAction.transactions:
        _open(context, const TransactionsScreen());
      case _DashboardMenuAction.goals:
        _open(context, const GoalsScreen());
      case _DashboardMenuAction.reports:
        _open(context, const ReportsScreen());
      case _DashboardMenuAction.categories:
        _open(context, const ManageCategoriesScreen());
      case _DashboardMenuAction.settings:
        _open(context, const SettingsScreen());
      case _DashboardMenuAction.signOut:
        AuthScope.of(context).logout();
    }
  }

  static void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  static IconData _walletIcon(WalletType type) {
    switch (type) {
      case WalletType.needs:
        return Icons.home_work_outlined;
      case WalletType.savings:
        return Icons.savings_outlined;
      case WalletType.wants:
        return Icons.shopping_bag_outlined;
    }
  }
}

enum _DashboardMenuAction {
  transactions,
  goals,
  reports,
  categories,
  settings,
  signOut,
}

class _SignedInMenuHeader extends StatelessWidget {
  const _SignedInMenuHeader({required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            child: const Icon(Icons.person_outline),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signed in as',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  email ?? 'Unknown user',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBanner extends StatelessWidget {
  const _UserBanner({required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.onPrimaryContainer,
            child: const Icon(Icons.person_outline, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Logged in user',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  email ?? 'Unknown user',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_user_outlined, size: 20),
        ],
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.currency,
    required this.totalBalance,
    required this.safeDaily,
    required this.spentToday,
    required this.remaining,
    required this.insight,
    required this.onAddIncome,
    required this.onAddExpense,
  });

  final String currency;
  final double totalBalance;
  final double safeDaily;
  final double spentToday;
  final double remaining;
  final String insight;
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total balance',
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    MoneyFormatter.format(totalBalance, currency),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroAction(
                      icon: Icons.add,
                      label: 'Income',
                      onTap: onAddIncome,
                    ),
                    _HeroAction(
                      icon: Icons.remove,
                      label: 'Expense',
                      onTap: onAddExpense,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.bolt, color: colors.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s spending signal',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insight,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: safeDaily <= 0
                            ? 0
                            : (spentToday / safeDaily).clamp(0, 1),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(999),
                        backgroundColor: colors.surfaceContainerHighest,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${MoneyFormatter.format(remaining.clamp(0, double.infinity), currency)} left today',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.onPrimary.withValues(alpha: 0.16),
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        minimumSize: const Size(120, 42),
      ),
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({
    required this.type,
    required this.amount,
    required this.currency,
  });

  final WalletType type;
  final double amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.primary.withValues(alpha: 0.14),
            foregroundColor: colors.primary,
            child: Icon(DashboardScreen._walletIcon(type), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    MoneyFormatter.format(amount, currency),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onIncome,
    required this.onExpense,
    required this.onGoal,
    required this.onTransactions,
  });

  final VoidCallback onIncome;
  final VoidCallback onExpense;
  final VoidCallback onGoal;
  final VoidCallback onTransactions;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _QuickButton(icon: Icons.add, label: 'Income', onTap: onIncome),
          _QuickButton(icon: Icons.remove, label: 'Expense', onTap: onExpense),
          _QuickButton(icon: Icons.flag, label: 'Goal', onTap: onGoal),
          _QuickButton(
            icon: Icons.receipt_long_outlined,
            label: 'Transactions',
            onTap: onTransactions,
          ),
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(minimumSize: const Size(128, 44)),
    );
  }
}
