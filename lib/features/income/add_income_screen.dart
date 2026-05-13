import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/money_formatter.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/wallet_type.dart';
import '../../data/repositories/cashguard_repository.dart';
import '../../data/services/finance_service.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _source = AppConstants.incomeSources.first;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amount.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _amount.removeListener(_refreshPreview);
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await CashguardScope.of(context).addIncome(
      amount: double.parse(_amount.text.replaceAll(',', '')),
      source: _source,
      date: _date,
      note: _note.text.trim(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final repo = CashguardScope.of(context);
    final amount = double.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
    final split = FinanceService.splitIncome(amount, repo.settings);

    return Scaffold(
      appBar: AppBar(title: const Text('Add income')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _EntryHeader(
                icon: Icons.trending_up,
                title: 'Record income',
                subtitle:
                    'CashGuard will split this amount into your configured money buckets.',
                amount: MoneyFormatter.format(amount, repo.settings.currency),
              ),
              const SizedBox(height: 14),
              SectionCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AmountField(controller: _amount, label: 'Amount'),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _source,
                        decoration: const InputDecoration(
                          labelText: 'Source',
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                        items: AppConstants.incomeSources
                            .map(
                              (source) => DropdownMenuItem(
                                value: source,
                                child: Text(source),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _source = value ?? _source),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _note,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          hintText: 'Optional',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _DateButton(date: _date, onPick: _pickDate),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Save income'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _SplitPreview(split: split, currency: repo.settings.currency),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _refreshPreview() => setState(() {});
}

class _EntryHeader extends StatelessWidget {
  const _EntryHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: colors.onPrimary.withValues(alpha: 0.16),
            foregroundColor: colors.onPrimary,
            child: Icon(icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.86),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  amount,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w900,
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

class _DateButton extends StatelessWidget {
  const _DateButton({required this.date, required this.onPick});

  final DateTime date;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPick,
      icon: const Icon(Icons.calendar_today),
      label: Text(_formatDate(date)),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _SplitPreview extends StatelessWidget {
  const _SplitPreview({required this.split, required this.currency});

  final Map<WalletType, double> split;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Split preview',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...split.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Icon(
                    _walletIcon(entry.key),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.key.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    MoneyFormatter.format(entry.value, currency),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
