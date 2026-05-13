import 'package:flutter/material.dart';

import '../../core/utils/money_formatter.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/section_card.dart';
import '../../data/repositories/cashguard_repository.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _target = TextEditingController();
  final _saved = TextEditingController(text: '0');
  DateTime? _deadline;

  double get _targetAmount =>
      double.tryParse(_target.text.replaceAll(',', '')) ?? 0;
  double get _savedAmount =>
      double.tryParse(_saved.text.replaceAll(',', '')) ?? 0;
  double get _progress =>
      _targetAmount <= 0 ? 0 : (_savedAmount / _targetAmount).clamp(0, 1);

  @override
  void initState() {
    super.initState();
    _target.addListener(_refreshPreview);
    _saved.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _target.removeListener(_refreshPreview);
    _saved.removeListener(_refreshPreview);
    _name.dispose();
    _target.dispose();
    _saved.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await CashguardScope.of(context).addGoal(
      name: _name.text.trim(),
      targetAmount: _targetAmount,
      currentSavedAmount: _savedAmount,
      deadline: _deadline,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currency = CashguardScope.of(context).settings.currency;
    final remaining = (_targetAmount - _savedAmount)
        .clamp(0, double.infinity)
        .toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('Add goal')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _GoalHeader(
                progress: _progress,
                target: MoneyFormatter.format(_targetAmount, currency),
                remaining: MoneyFormatter.format(remaining, currency),
              ),
              const SizedBox(height: 14),
              SectionCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Goal name',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Enter a goal name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      AmountField(controller: _target, label: 'Target amount'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _saved,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Current saved amount',
                          prefixIcon: Icon(Icons.savings_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _pickDeadline,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _deadline == null
                              ? 'Deadline optional'
                              : _formatDate(_deadline!),
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Save goal'),
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

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: _deadline ?? DateTime.now(),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  void _refreshPreview() => setState(() {});

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _GoalHeader extends StatelessWidget {
  const _GoalHeader({
    required this.progress,
    required this.target,
    required this.remaining,
  });

  final double progress;
  final String target;
  final String remaining;

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
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.onPrimary.withValues(alpha: 0.16),
                foregroundColor: colors.onPrimary,
                child: const Icon(Icons.flag_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Plan a savings goal',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            minHeight: 9,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: colors.onPrimary.withValues(alpha: 0.2),
            color: colors.onPrimary,
          ),
          const SizedBox(height: 12),
          Text(
            '${(progress * 100).round()}% ready - $remaining left toward $target',
            style: TextStyle(
              color: colors.onPrimary.withValues(alpha: 0.9),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
