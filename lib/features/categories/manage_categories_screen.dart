import 'package:flutter/material.dart';

import '../../core/utils/category_style.dart';
import '../../data/repositories/cashguard_repository.dart';
import 'create_category_screen.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final repo = CashguardScope.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCategoryScreen())),
            icon: const Icon(Icons.add),
            tooltip: 'Create category',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text('Categories from all wallets', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Expenses')),
              ButtonSegment(value: 1, label: Text('Income')),
            ],
            selected: {_tab},
            onSelectionChanged: (value) => setState(() => _tab = value.first),
          ),
          const SizedBox(height: 18),
          if (_tab == 1)
            const _CategoryPlaceholder()
          else
            ...repo.settings.categories.map((category) {
              final style = CategoryStyles.forName(category);
              final count = repo.expenses.where((expense) => expense.category == category).length;
              final walletCount = repo.expenses.where((expense) => expense.category == category).map((expense) => expense.walletType).toSet().length;
              return _CategoryTile(
                category: category,
                color: style.color,
                icon: style.icon,
                subtitle: '$count transactions in ${walletCount == 0 ? 'all' : walletCount} wallets',
              );
            }),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.color,
    required this.icon,
    required this.subtitle,
  });

  final String category;
  final Color color;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Icon(icon, size: 20),
        ),
        title: Text(category, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _CategoryPlaceholder extends StatelessWidget {
  const _CategoryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          'Income sources are managed in the Add Income form for now.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
