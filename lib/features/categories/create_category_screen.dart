import 'package:flutter/material.dart';

import '../../data/repositories/cashguard_repository.dart';

class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({super.key});

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  int _colorIndex = 0;
  int _iconIndex = 0;

  static const _colors = [
    Color(0xFFFFB020),
    Color(0xFFFF7A1A),
    Color(0xFFEF4444),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF2563EB),
    Color(0xFF14B8A6),
    Color(0xFF18C964),
  ];

  static const _icons = [
    Icons.restaurant,
    Icons.flight,
    Icons.flash_on,
    Icons.person,
    Icons.sports_soccer,
    Icons.local_taxi,
    Icons.theater_comedy,
    Icons.home,
    Icons.local_dining,
    Icons.favorite,
    Icons.shopping_bag,
    Icons.hotel,
    Icons.photo_camera,
    Icons.spa,
    Icons.account_balance_wallet,
    Icons.checkroom,
    Icons.train,
    Icons.local_bar,
    Icons.fitness_center,
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = CashguardScope.of(context);
    final name = _name.text.trim();
    final exists = repo.settings.categories.any((item) => item.toLowerCase() == name.toLowerCase());
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This category already exists.')));
      return;
    }
    await repo.updateSettings(
      repo.settings.copyWith(categories: [...repo.settings.categories, name]),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Create a New Category'),
        actions: [IconButton(onPressed: _save, icon: const Icon(Icons.add), tooltip: 'Create')],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _colors[_colorIndex],
                  foregroundColor: Colors.white,
                  child: Icon(_icons[_iconIndex]),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Category name'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter a category name' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text('It belongs to', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Expanded(child: Text('Expense categories')),
                  Text('All wallets', style: TextStyle(color: scheme.onSurfaceVariant)),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('Category color', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_colors.length, (index) {
                final selected = index == _colorIndex;
                return InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: () => setState(() => _colorIndex = index),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _colors[index],
                      shape: BoxShape.circle,
                      border: Border.all(color: selected ? scheme.onSurface : Colors.transparent, width: 3),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Text('Category icon', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            GridView.builder(
              itemCount: _icons.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final selected = index == _iconIndex;
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => setState(() => _iconIndex = index),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: selected ? _colors[_colorIndex].withValues(alpha: 0.2) : scheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: selected ? _colors[_colorIndex] : Colors.transparent),
                    ),
                    child: Icon(_icons[index], color: selected ? _colors[_colorIndex] : scheme.onSurfaceVariant),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Create a New Category')),
          ],
        ),
      ),
    );
  }
}
