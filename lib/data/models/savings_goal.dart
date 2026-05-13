class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.deadline,
    required this.createdAt,
  });

  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final DateTime createdAt;

  double get progress {
    if (targetAmount <= 0) return 0;
    return (savedAmount / targetAmount).clamp(0, 1);
  }

  double get remainingAmount => (targetAmount - savedAmount).clamp(0, double.infinity);

  SavingsGoal copyWith({double? savedAmount}) {
    return SavingsGoal(
      id: id,
      name: name,
      targetAmount: targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'deadline': deadline?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Savings goal',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
      savedAmount: (json['savedAmount'] as num?)?.toDouble() ?? 0,
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
