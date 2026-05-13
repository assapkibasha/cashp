import 'package:flutter/material.dart';

class AmountField extends StatelessWidget {
  const AmountField({super.key, required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final amount = double.tryParse((value ?? '').replaceAll(',', ''));
        if (amount == null || amount <= 0) return 'Enter an amount greater than zero';
        return null;
      },
    );
  }
}

class PercentageField extends StatelessWidget {
  const PercentageField({
    super.key,
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, suffixText: '%'),
      validator: (value) {
        final number = int.tryParse(value ?? '');
        if (number == null || number < 0 || number > 100) return 'Use 0 to 100';
        return null;
      },
    );
  }
}
