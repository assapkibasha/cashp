import 'package:flutter/material.dart';

import '../../core/widgets/form_fields.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_settings.dart';
import '../../data/repositories/cashguard_repository.dart';
import '../categories/manage_categories_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = CashguardScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Theme'),
                  subtitle: Text(repo.settings.themeMode.name),
                  trailing: DropdownButton<ThemeMode>(
                    value: repo.settings.themeMode,
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                    ],
                    onChanged: (mode) {
                      if (mode != null) repo.updateSettings(repo.settings.copyWith(themeMode: mode));
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Currency'),
                  subtitle: Text(repo.settings.currency),
                  onTap: () => _editCurrency(context, repo),
                ),
                ListTile(
                  leading: const Icon(Icons.pie_chart_outline),
                  title: const Text('Budget split'),
                  subtitle: Text('${repo.settings.needsPercentage}% Needs - ${repo.settings.savingsPercentage}% Savings - ${repo.settings.wantsPercentage}% Wants'),
                  onTap: () => _editSplit(context, repo),
                ),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Manage categories'),
                  subtitle: Text('${repo.settings.categories.length} expense categories'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCategoriesScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context, repo),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Reset app data'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => AuthScope.of(context).logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Future<void> _editCurrency(BuildContext context, CashguardRepository repo) async {
    final controller = TextEditingController(text: repo.settings.currency);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change currency'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Currency')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim().toUpperCase()), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty) {
      await repo.updateSettings(repo.settings.copyWith(currency: value));
    }
  }

  Future<void> _editSplit(BuildContext context, CashguardRepository repo) async {
    final needs = TextEditingController(text: repo.settings.needsPercentage.toString());
    final savings = TextEditingController(text: repo.settings.savingsPercentage.toString());
    final wants = TextEditingController(text: repo.settings.wantsPercentage.toString());
    final formKey = GlobalKey<FormState>();
    final updated = await showDialog<UserSettings>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Budget split'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PercentageField(controller: needs, label: 'Needs'),
              const SizedBox(height: 10),
              PercentageField(controller: savings, label: 'Savings'),
              const SizedBox(height: 10),
              PercentageField(controller: wants, label: 'Wants'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final n = int.parse(needs.text);
              final s = int.parse(savings.text);
              final w = int.parse(wants.text);
              if (n + s + w != 100) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Percentages must total 100%.')));
                return;
              }
              Navigator.pop(context, repo.settings.copyWith(needsPercentage: n, savingsPercentage: s, wantsPercentage: w));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    needs.dispose();
    savings.dispose();
    wants.dispose();
    if (updated != null) await repo.updateSettings(updated);
  }

  Future<void> _confirmReset(BuildContext context, CashguardRepository repo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset app data?'),
        content: const Text('This clears setup, wallets, transactions, goals, and settings from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed == true) await repo.resetData();
  }
}
