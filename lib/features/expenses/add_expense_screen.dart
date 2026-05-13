import 'package:flutter/material.dart';

import '../../core/utils/money_formatter.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/wallet_type.dart';
import '../../data/repositories/cashguard_repository.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _category;
  WalletType _walletType = WalletType.needs;
  DateTime _date = DateTime.now();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amount.addListener(_refresh);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _category ??= CashguardScope.of(context).settings.categories.first;
  }

  @override
  void dispose() {
    _amount.removeListener(_refresh);
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final message = await CashguardScope.of(context).addExpense(
      amount: double.parse(_amount.text.replaceAll(',', '')),
      category: _category!,
      walletType: _walletType,
      date: _date,
      note: _note.text.trim(),
    );
    if (!mounted) return;
    if (message != null) {
      setState(() => _errorMessage = message);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final repo = CashguardScope.of(context);
    final amount = double.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
    final walletBalance = repo.walletBalance(_walletType);
    final remaining = walletBalance - amount;

    return Scaffold(
      appBar: AppBar(title: const Text('Add expense')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _ExpenseHeader(
                amount: MoneyFormatter.format(amount, repo.settings.currency),
                wallet: _walletType.label,
                remaining: MoneyFormatter.format(
                  remaining.clamp(0, double.infinity),
                  repo.settings.currency,
                ),
                isOver: remaining < 0,
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
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: repo.settings.categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          _category = value ?? _category;
                          _errorMessage = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<WalletType>(
                        initialValue: _walletType,
                        decoration: const InputDecoration(
                          labelText: 'Wallet',
                          prefixIcon: Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                        ),
                        items: WalletType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          _walletType = value ?? _walletType;
                          _errorMessage = null;
                        }),
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
                      const SizedBox(height: 14),
                      _WalletBalanceLine(
                        label: '${_walletType.label} wallet balance',
                        value: MoneyFormatter.format(
                          walletBalance,
                          repo.settings.currency,
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        _InlineError(message: _errorMessage!),
                      ],
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Save expense'),
                      ),
                    ],
                  ),
                ),
              ),
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

  void _refresh() {
    setState(() => _errorMessage = null);
  }
}

class _ExpenseHeader extends StatelessWidget {
  const _ExpenseHeader({
    required this.amount,
    required this.wallet,
    required this.remaining,
    required this.isOver,
  });

  final String amount;
  final String wallet;
  final String remaining;
  final bool isOver;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isOver ? colors.errorContainer : colors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: (isOver ? colors.error : colors.onPrimary)
                .withValues(alpha: 0.16),
            foregroundColor: isOver
                ? colors.onErrorContainer
                : colors.onPrimary,
            child: const Icon(Icons.payments_outlined),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record expense',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isOver ? colors.onErrorContainer : colors.onPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isOver
                      ? '$wallet wallet cannot cover this amount.'
                      : '$wallet wallet will have $remaining left.',
                  style: TextStyle(
                    color: isOver
                        ? colors.onErrorContainer
                        : colors.onPrimary.withValues(alpha: 0.86),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  amount,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isOver ? colors.onErrorContainer : colors.onPrimary,
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
      label: Text(
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      ),
    );
  }
}

class _WalletBalanceLine extends StatelessWidget {
  const _WalletBalanceLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
