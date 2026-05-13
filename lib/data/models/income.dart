class Income {
  const Income({
    required this.id,
    required this.amount,
    required this.source,
    required this.date,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final double amount;
  final String source;
  final DateTime date;
  final String note;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'source': source,
        'date': date.toIso8601String(),
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      source: json['source'] as String? ?? 'Other',
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
