import 'wallet_type.dart';

enum TransactionType { income, expense, goalContribution }

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.date,
    required this.createdAt,
    this.walletType,
    this.category,
    this.note = '',
  });

  final String id;
  final TransactionType type;
  final String title;
  final double amount;
  final DateTime date;
  final DateTime createdAt;
  final WalletType? walletType;
  final String? category;
  final String note;
}
