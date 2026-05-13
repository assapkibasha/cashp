import 'package:flutter/material.dart';

import '../../core/utils/money_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_card.dart';
import '../../data/repositories/cashguard_repository.dart';
import '../../data/services/finance_service.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = CashguardScope.of(context);
    final now = DateTime.now();
    final currency = repo.settings.currency;
    final income = FinanceService.monthlyIncome(repo.incomes, now);
    final expenses = FinanceService.monthlyExpenses(repo.expenses, now);
    final byCategory = FinanceService.spendingByCategory(repo.expenses, now);
    final byWallet = FinanceService.spendingByWallet(repo.expenses, now);
    final biggest = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              children: [
                _ReportRow(label: 'Income this month', value: MoneyFormatter.format(income, currency)),
                _ReportRow(label: 'Expenses this month', value: MoneyFormatter.format(expenses, currency)),
                _ReportRow(label: 'Net movement', value: MoneyFormatter.format(income - expenses, currency)),
                _ReportRow(label: 'Biggest category', value: biggest.isEmpty ? 'None yet' : biggest.first.key),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Spending by category', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (byCategory.isEmpty)
            const EmptyState(icon: Icons.bar_chart, title: 'No spending yet', message: 'Add expenses to unlock monthly summaries.')
          else
            ...byCategory.entries.map((entry) => _ProgressRow(label: entry.key, amount: entry.value, max: expenses, currency: currency)),
          const SizedBox(height: 16),
          Text('Spending by wallet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...byWallet.entries.map((entry) => _ProgressRow(label: entry.key.label, amount: entry.value, max: expenses, currency: currency)),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.w800))]),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, required this.amount, required this.max, required this.currency});

  final String label;
  final double amount;
  final double max;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Expanded(child: Text(label)), Text(MoneyFormatter.format(amount, currency))]),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: max <= 0 ? 0 : amount / max, minHeight: 7, borderRadius: BorderRadius.circular(99)),
          ],
        ),
      ),
    );
  }
}
