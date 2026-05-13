import 'package:flutter/material.dart';

import '../../core/widgets/form_fields.dart';
import '../../data/models/user_settings.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/cashguard_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currency = TextEditingController(text: 'RWF');
  final _income = TextEditingController();
  final _needs = TextEditingController(text: '60');
  final _savings = TextEditingController(text: '20');
  final _wants = TextEditingController(text: '20');
  String? _errorMessage;

  int get _needsValue => int.tryParse(_needs.text) ?? 0;
  int get _savingsValue => int.tryParse(_savings.text) ?? 0;
  int get _wantsValue => int.tryParse(_wants.text) ?? 0;
  int get _splitTotal => _needsValue + _savingsValue + _wantsValue;

  @override
  void initState() {
    super.initState();
    _needs.addListener(_refreshSplit);
    _savings.addListener(_refreshSplit);
    _wants.addListener(_refreshSplit);
  }

  @override
  void dispose() {
    _needs.removeListener(_refreshSplit);
    _savings.removeListener(_refreshSplit);
    _wants.removeListener(_refreshSplit);
    _currency.dispose();
    _income.dispose();
    _needs.dispose();
    _savings.dispose();
    _wants.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final needs = int.parse(_needs.text);
    final savings = int.parse(_savings.text);
    final wants = int.parse(_wants.text);
    if (needs + savings + wants != 100) {
      setState(
        () => _errorMessage = 'Needs, Savings, and Wants must total 100%.',
      );
      return;
    }
    final monthlyIncome = double.tryParse(_income.text.replaceAll(',', ''));
    await CashguardScope.of(context).completeSetup(
      UserSettings.defaults().copyWith(
        currency: _currency.text.trim().isEmpty
            ? 'RWF'
            : _currency.text.trim().toUpperCase(),
        monthlyIncomeExpectation: monthlyIncome,
        needsPercentage: needs,
        savingsPercentage: savings,
        wantsPercentage: wants,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final horizontalPadding = compact ? 18.0 : 28.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 28,
                  ),
                  children: [
                    _SetupHeader(email: auth.email),
                    const SizedBox(height: 16),
                    _SplitPreview(
                      needs: _needsValue,
                      savings: _savingsValue,
                      wants: _wantsValue,
                      total: _splitTotal,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Money profile',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _currency,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  labelText: 'Currency',
                                  prefixIcon: Icon(Icons.payments_outlined),
                                ),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                    ? 'Enter a currency'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _income,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Monthly income expectation',
                                  hintText: 'Optional',
                                  prefixIcon: Icon(Icons.trending_up),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Budget split',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 10),
                              PercentageField(
                                controller: _needs,
                                label: 'Needs',
                              ),
                              const SizedBox(height: 12),
                              PercentageField(
                                controller: _savings,
                                label: 'Savings',
                              ),
                              const SizedBox(height: 12),
                              PercentageField(
                                controller: _wants,
                                label: 'Wants',
                              ),
                              const SizedBox(height: 14),
                              _SplitTotal(total: _splitTotal),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 12),
                                _SetupError(message: _errorMessage!),
                              ],
                              const SizedBox(height: 22),
                              FilledButton.icon(
                                onPressed: _save,
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Start managing money'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _refreshSplit() {
    setState(() {
      if (_errorMessage != null && _splitTotal == 100) {
        _errorMessage = null;
      }
    });
  }
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader({required this.email});

  final String? email;

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
            'CashGuard setup',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your buckets once. New income will be planned into Needs, Savings, and Wants.',
            style: TextStyle(
              color: colors.onPrimary.withValues(alpha: 0.86),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline, color: colors.onPrimary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Logged in as ${email ?? 'unknown user'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w800,
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

class _SplitPreview extends StatelessWidget {
  const _SplitPreview({
    required this.needs,
    required this.savings,
    required this.wants,
    required this.total,
  });

  final int needs;
  final int savings;
  final int wants;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bucket preview',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: _barFlex(needs),
                  child: _PreviewBar(
                    label: 'Needs',
                    value: needs,
                    color: const Color(0xFF18C964),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: _barFlex(savings),
                  child: _PreviewBar(
                    label: 'Savings',
                    value: savings,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: _barFlex(wants),
                  child: _PreviewBar(
                    label: 'Wants',
                    value: wants,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Current total: $total%',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: total == 100
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _barFlex(int value) => value.clamp(1, 100).toInt();
}

class _PreviewBar extends StatelessWidget {
  const _PreviewBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label $value%',
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$value%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _SplitTotal extends StatelessWidget {
  const _SplitTotal({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final ok = total == 100;
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ok ? colors.primaryContainer : colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_outline : Icons.error_outline, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ok
                  ? 'Split is balanced at 100%.'
                  : 'Split must total 100%. Current total is $total%.',
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupError extends StatelessWidget {
  const _SetupError({required this.message});

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
