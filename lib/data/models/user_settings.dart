import 'package:flutter/material.dart';

class UserSettings {
  const UserSettings({
    required this.currency,
    required this.monthlyIncomeExpectation,
    required this.needsPercentage,
    required this.savingsPercentage,
    required this.wantsPercentage,
    required this.themeMode,
    required this.setupCompleted,
    required this.categories,
  });

  factory UserSettings.defaults() {
    return const UserSettings(
      currency: 'RWF',
      monthlyIncomeExpectation: null,
      needsPercentage: 60,
      savingsPercentage: 20,
      wantsPercentage: 20,
      themeMode: ThemeMode.system,
      setupCompleted: false,
      categories: [
        'Food',
        'Transport',
        'Airtime/Internet',
        'Rent',
        'Family Support',
        'School',
        'Clothing',
        'Entertainment',
        'Health',
        'Other',
      ],
    );
  }

  final String currency;
  final double? monthlyIncomeExpectation;
  final int needsPercentage;
  final int savingsPercentage;
  final int wantsPercentage;
  final ThemeMode themeMode;
  final bool setupCompleted;
  final List<String> categories;

  int get totalPercentage =>
      needsPercentage + savingsPercentage + wantsPercentage;

  UserSettings copyWith({
    String? currency,
    double? monthlyIncomeExpectation,
    bool clearMonthlyIncomeExpectation = false,
    int? needsPercentage,
    int? savingsPercentage,
    int? wantsPercentage,
    ThemeMode? themeMode,
    bool? setupCompleted,
    List<String>? categories,
  }) {
    return UserSettings(
      currency: currency ?? this.currency,
      monthlyIncomeExpectation: clearMonthlyIncomeExpectation
          ? null
          : monthlyIncomeExpectation ?? this.monthlyIncomeExpectation,
      needsPercentage: needsPercentage ?? this.needsPercentage,
      savingsPercentage: savingsPercentage ?? this.savingsPercentage,
      wantsPercentage: wantsPercentage ?? this.wantsPercentage,
      themeMode: themeMode ?? this.themeMode,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      categories: categories ?? this.categories,
    );
  }

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'monthlyIncomeExpectation': monthlyIncomeExpectation,
        'needsPercentage': needsPercentage,
        'savingsPercentage': savingsPercentage,
        'wantsPercentage': wantsPercentage,
        'themeMode': themeMode.name,
        'setupCompleted': setupCompleted,
        'categories': categories,
      };

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      currency: json['currency'] as String? ?? 'RWF',
      monthlyIncomeExpectation:
          (json['monthlyIncomeExpectation'] as num?)?.toDouble(),
      needsPercentage: (json['needsPercentage'] as num?)?.toInt() ?? 60,
      savingsPercentage: (json['savingsPercentage'] as num?)?.toInt() ?? 20,
      wantsPercentage: (json['wantsPercentage'] as num?)?.toInt() ?? 20,
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      setupCompleted: json['setupCompleted'] as bool? ?? false,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          UserSettings.defaults().categories,
    );
  }
}
