import 'wallet_type.dart';

class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.walletType,
    required this.date,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final double amount;
  final String category;
  final WalletType walletType;
  final DateTime date;
  final String note;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'category': category,
        'walletType': walletType.name,
        'date': date.toIso8601String(),
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? 'Other',
      walletType: walletTypeFromName(json['walletType'] as String? ?? 'needs'),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
