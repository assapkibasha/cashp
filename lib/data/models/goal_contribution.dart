class GoalContribution {
  const GoalContribution({
    required this.id,
    required this.goalId,
    required this.goalName,
    required this.amount,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final String goalId;
  final String goalName;
  final double amount;
  final DateTime date;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'goalId': goalId,
        'goalName': goalName,
        'amount': amount,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory GoalContribution.fromJson(Map<String, dynamic> json) {
    return GoalContribution(
      id: json['id'] as String,
      goalId: json['goalId'] as String,
      goalName: json['goalName'] as String? ?? 'Savings goal',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
