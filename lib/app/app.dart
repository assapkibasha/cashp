import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/cashguard_repository.dart';
import '../features/auth/auth_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/transactions/transactions_screen.dart';
import '../features/expenses/add_expense_screen.dart';
import '../features/goals/add_goal_screen.dart';
import '../features/income/add_income_screen.dart';
import 'theme.dart';

class CashguardApp extends StatelessWidget {
  const CashguardApp({
    super.key,
    required this.repository,
    required this.authRepository,
  });

  final CashguardRepository repository;
  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      repository: authRepository,
      child: CashguardScope(
        repository: repository,
        child: ListenableBuilder(
        listenable: Listenable.merge([repository, authRepository]),
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: AppConstants.appName,
            theme: CashguardTheme.light(),
            darkTheme: CashguardTheme.dark(),
            themeMode: repository.settings.themeMode,
            home: authRepository.isAuthenticated
                ? repository.setupCompleted
                    ? const CashguardShell()
                    : const OnboardingScreen()
                : const AuthScreen(),
          );
        },
        ),
      ),
    );
  }
}

class CashguardShell extends StatefulWidget {
  const CashguardShell({super.key});

  @override
  State<CashguardShell> createState() => _CashguardShellState();
}

class _CashguardShellState extends State<CashguardShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    GoalsScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[_index]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 72,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.account_balance_wallet_outlined,
              activeIcon: Icons.account_balance_wallet,
              label: 'Wallet',
              selected: _index == 0,
              onTap: () => setState(() => _index = 0),
            ),
            _NavItem(
              icon: Icons.show_chart,
              activeIcon: Icons.show_chart,
              label: 'Charts',
              selected: _index == 3,
              onTap: () => setState(() => _index = 3),
            ),
            const SizedBox(width: 48),
            _NavItem(
              icon: Icons.flag_outlined,
              activeIcon: Icons.flag,
              label: 'Goals',
              selected: _index == 2,
              onTap: () => setState(() => _index = 2),
            ),
            _NavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: 'Settings',
              selected: _index == 4,
              onTap: () => setState(() => _index = 4),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.add)),
                title: const Text('Add income'),
                onTap: () => _openFromSheet(context, const AddIncomeScreen()),
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.remove)),
                title: const Text('Add expense'),
                onTap: () => _openFromSheet(context, const AddExpenseScreen()),
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.flag)),
                title: const Text('Add goal'),
                onTap: () => _openFromSheet(context, const AddGoalScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFromSheet(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(label, maxLines: 1, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
