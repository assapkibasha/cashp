import 'package:flutter/material.dart';

class CategoryStyle {
  const CategoryStyle({required this.color, required this.icon});

  final Color color;
  final IconData icon;
}

class CategoryStyles {
  static const _colors = [
    Color(0xFFFFB020),
    Color(0xFF23C7A9),
    Color(0xFFEF4E8B),
    Color(0xFFBA6B36),
    Color(0xFF2F9BFF),
    Color(0xFF7C6CE4),
    Color(0xFFEE6352),
    Color(0xFF41B883),
  ];

  static const _icons = [
    Icons.restaurant,
    Icons.directions_bus,
    Icons.wifi,
    Icons.home,
    Icons.family_restroom,
    Icons.school,
    Icons.checkroom,
    Icons.movie,
    Icons.health_and_safety,
    Icons.more_horiz,
  ];

  static CategoryStyle forName(String name) {
    final lower = name.toLowerCase();
    final icon = switch (lower) {
      String value when value.contains('food') || value.contains('drink') => Icons.restaurant,
      String value when value.contains('transport') || value.contains('bus') => Icons.directions_bus,
      String value when value.contains('airtime') || value.contains('internet') => Icons.wifi,
      String value when value.contains('rent') || value.contains('home') => Icons.home,
      String value when value.contains('family') => Icons.family_restroom,
      String value when value.contains('school') => Icons.school,
      String value when value.contains('cloth') => Icons.checkroom,
      String value when value.contains('entertainment') => Icons.movie,
      String value when value.contains('health') => Icons.health_and_safety,
      _ => _icons[name.hashCode.abs() % _icons.length],
    };
    return CategoryStyle(
      color: _colors[name.hashCode.abs() % _colors.length],
      icon: icon,
    );
  }
}
