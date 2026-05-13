import 'package:flutter/material.dart';

class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (subtitle != null) ...[
            Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
          ],
          ...children,
        ],
      ),
    );
  }
}
