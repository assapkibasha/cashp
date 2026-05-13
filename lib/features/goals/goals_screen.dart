import 'package:flutter/material.dart';

import '../../core/utils/money_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/savings_goal.dart';
import '../../data/models/wallet_type.dart';
import '../../data/repositories/cashguard_repository.dart';
import 'add_goal_screen.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = CashguardScope.of(context);
    final currency = repo.settings.currency;
    final totalTarget = repo.goals.fold<double>(
      0,
      (sum, goal) => sum + goal.targetAmount,
    );
    final totalSaved = repo.goals.fold<double>(
      0,
      (sum, goal) => sum + goal.savedAmount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddGoalScreen()),
            ),
            icon: const Icon(Icons.add),
            tooltip: 'Add goal',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _GoalsHeader(
                count: repo.goals.length,
                saved: MoneyFormatter.format(totalSaved, currency),
                target: MoneyFormatter.format(totalTarget, currency),
                savingsWallet: MoneyFormatter.format(
                  repo.walletBalance(WalletType.savings),
                  currency,
                ),
              ),
              const SizedBox(height: 14),
              if (repo.goals.isEmpty)
                const EmptyState(
                  icon: Icons.flag,
                  title: 'No goals yet',
                  message:
                      'Create a goal and fund it from your Savings wallet.',
                )
              else
                ...repo.goals.map((goal) => _GoalCard(goal: goal)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalsHeader extends StatelessWidget {
  const _GoalsHeader({
    required this.count,
    required this.saved,
    required this.target,
    required this.savingsWallet,
  });

  final int count;
  final String saved;
  final String target;
  final String savingsWallet;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Savings goals',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count active goals - $saved saved toward $target',
            style: TextStyle(
              color: colors.onPrimary.withValues(alpha: 0.86),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _HeaderChip(
            icon: Icons.savings_outlined,
            label: 'Savings wallet',
            value: savingsWallet,
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.onPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.onPrimary, size: 18),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: colors.onPrimary.withValues(alpha: 0.84),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.onPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final repo = CashguardScope.of(context);
    final currency = repo.settings.currency;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.flag_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      if (goal.deadline != null)
                        Text(
                          'Due ${_formatDate(goal.deadline!)}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                    ],
                  ),
                ),
                Text(
                  '${(goal.progress * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: goal.progress,
              minHeight: 9,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _GoalMetric(
                    label: 'Saved',
                    value: MoneyFormatter.format(goal.savedAmount, currency),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GoalMetric(
                    label: 'Remaining',
                    value: MoneyFormatter.format(
                      goal.remainingAmount,
                      currency,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => _showContributionDialog(context, goal),
                icon: const Icon(Icons.add),
                label: const Text('Contribute'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showContributionDialog(
    BuildContext context,
    SavingsGoal goal,
  ) async {
    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contribute to ${goal.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount from Savings',
            prefixIcon: Icon(Icons.savings_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              double.tryParse(controller.text.replaceAll(',', '')),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result <= 0 || !context.mounted) return;
    final message = await CashguardScope.of(
      context,
    ).contributeToGoal(goal, result);
    if (message != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _GoalMetric extends StatelessWidget {
  const _GoalMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
