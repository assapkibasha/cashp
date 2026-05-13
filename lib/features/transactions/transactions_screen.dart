import 'package:flutter/material.dart';

import '../../core/utils/category_style.dart';
import '../../core/utils/money_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/transaction_record.dart';
import '../../data/repositories/cashguard_repository.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionType? _filter;

  @override
  Widget build(BuildContext context) {
    final repo = CashguardScope.of(context);
    final records = repo.transactions
        .where((record) => _filter == null || record.type == _filter)
        .toList();
    final incomeTotal = records
        .where((record) => record.type == TransactionType.income)
        .fold<double>(0, (sum, record) => sum + record.amount);
    final expenseTotal = records
        .where((record) => record.type != TransactionType.income)
        .fold<double>(0, (sum, record) => sum + record.amount);
    final netTotal = incomeTotal - expenseTotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _filter = null),
            icon: const Icon(Icons.filter_alt_off_outlined),
            tooltip: 'Clear filter',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _TransactionsHeader(
                count: records.length,
                net: MoneyFormatter.format(netTotal, repo.settings.currency),
                income: MoneyFormatter.format(
                  incomeTotal,
                  repo.settings.currency,
                ),
                expenses: MoneyFormatter.format(
                  expenseTotal,
                  repo.settings.currency,
                ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<TransactionType?>(
                segments: const [
                  ButtonSegment(
                    value: null,
                    icon: Icon(Icons.list_alt),
                    label: Text('All'),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    icon: Icon(Icons.arrow_downward),
                    label: Text('Income'),
                  ),
                  ButtonSegment(
                    value: TransactionType.expense,
                    icon: Icon(Icons.arrow_upward),
                    label: Text('Expense'),
                  ),
                  ButtonSegment(
                    value: TransactionType.goalContribution,
                    icon: Icon(Icons.flag_outlined),
                    label: Text('Goals'),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (value) =>
                    setState(() => _filter = value.first),
              ),
              const SizedBox(height: 14),
              if (records.isEmpty)
                const EmptyState(
                  icon: Icons.receipt_long,
                  title: 'No transactions yet',
                  message: 'Add income or expenses and they will appear here.',
                )
              else
                ..._groupRecords(records).entries.map(
                  (entry) => _TransactionGroup(
                    label: entry.key,
                    records: entry.value,
                    currency: repo.settings.currency,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<TransactionRecord>> _groupRecords(
    List<TransactionRecord> records,
  ) {
    final grouped = <String, List<TransactionRecord>>{};
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    for (final record in records) {
      final label = _sameDay(record.date, today)
          ? 'Today'
          : _sameDay(record.date, yesterday)
          ? 'Yesterday'
          : _formatDate(record.date);
      grouped.putIfAbsent(label, () => []).add(record);
    }
    return grouped;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _TransactionsHeader extends StatelessWidget {
  const _TransactionsHeader({
    required this.count,
    required this.net,
    required this.income,
    required this.expenses,
  });

  final int count;
  final String net;
  final String income;
  final String expenses;

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
            'Cash activity',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count records in this view',
            style: TextStyle(
              color: colors.onPrimary.withValues(alpha: 0.86),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryChip(label: 'Net', value: net),
              _SummaryChip(label: 'Income', value: income),
              _SummaryChip(label: 'Outflow', value: expenses),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.onPrimary.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
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

class _TransactionGroup extends StatelessWidget {
  const _TransactionGroup({
    required this.label,
    required this.records,
    required this.currency,
  });

  final String label;
  final List<TransactionRecord> records;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final total = records.fold<double>(
      0,
      (sum, record) => record.type == TransactionType.income
          ? sum + record.amount
          : sum - record.amount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                MoneyFormatter.format(total, currency),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        ...records.map(
          (record) => _TransactionTile(record: record, currency: currency),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.record, required this.currency});

  final TransactionRecord record;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyles.forName(record.category ?? record.title);
    final isIncome = record.type == TransactionType.income;
    final isGoal = record.type == TransactionType.goalContribution;
    final color = isIncome
        ? Theme.of(context).colorScheme.primary
        : isGoal
        ? Theme.of(context).colorScheme.tertiary
        : style.color;
    final sign = isIncome ? '+' : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        leading: CircleAvatar(
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Icon(_icon(record, style.icon), size: 20),
        ),
        title: Text(
          record.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(_subtitle(record)),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$sign${MoneyFormatter.format(record.amount, currency)}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isIncome
                  ? Theme.of(context).colorScheme.primary
                  : Colors.redAccent,
            ),
          ),
        ),
      ),
    );
  }

  static IconData _icon(TransactionRecord record, IconData categoryIcon) {
    switch (record.type) {
      case TransactionType.income:
        return Icons.arrow_downward;
      case TransactionType.expense:
        return categoryIcon;
      case TransactionType.goalContribution:
        return Icons.flag_outlined;
    }
  }

  static String _subtitle(TransactionRecord record) {
    final date =
        '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
    final wallet = record.walletType == null
        ? ''
        : ' - ${record.walletType!.label}';
    final note = record.note.trim().isEmpty ? '' : ' - ${record.note.trim()}';
    return '$date$wallet$note';
  }
}
