import 'package:bookie_ai/core/utils/json_parsers.dart';

class Goal {
  final String id;
  final String title;
  final String? description;
  final double targetAmount;
  final String targetCurrency;
  final double currentAmount;
  final DateTime targetDate;
  final String priority; // LOW, MEDIUM, HIGH
  final String status; // ON_TRACK, AT_RISK, OFF_TRACK, ACHIEVED
  final double? monthlyRequired;
  final DateTime createdAt;
  final List<GoalContribution>? contributions;

  const Goal({
    required this.id,
    required this.title,
    this.description,
    required this.targetAmount,
    required this.targetCurrency,
    required this.currentAmount,
    required this.targetDate,
    required this.priority,
    required this.status,
    this.monthlyRequired,
    required this.createdAt,
    this.contributions,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetAmount: parseDouble(json['targetAmount']),
      targetCurrency: json['targetCurrency'] as String? ?? 'USD',
      currentAmount: parseDouble(json['currentAmount']),
      targetDate: DateTime.parse(json['targetDate'] as String),
      priority: json['priority'] as String? ?? 'MEDIUM',
      status: json['status'] as String? ?? 'ON_TRACK',
      monthlyRequired:
          parseNullableDouble(json['monthlyRequiredAmount']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      contributions: (json['contributions'] as List<dynamic>?)
          ?.map((e) =>
              GoalContribution.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      'targetAmount': targetAmount,
      'targetCurrency': targetCurrency,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      'priority': priority,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  double get percentComplete =>
      targetAmount > 0 ? (currentAmount / targetAmount * 100) : 0;

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    double? targetAmount,
    String? targetCurrency,
    double? currentAmount,
    DateTime? targetDate,
    String? priority,
    String? status,
    double? monthlyRequired,
    DateTime? createdAt,
    List<GoalContribution>? contributions,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      monthlyRequired: monthlyRequired ?? this.monthlyRequired,
      createdAt: createdAt ?? this.createdAt,
      contributions: contributions ?? this.contributions,
    );
  }

  @override
  String toString() => 'Goal(id: $id, title: $title, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Goal && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class GoalContribution {
  final String id;
  final double amount;
  final String currency;
  final DateTime contributionDate;
  final String? sourceType;
  final double? convertedAmount;

  const GoalContribution({
    required this.id,
    required this.amount,
    required this.currency,
    required this.contributionDate,
    this.sourceType,
    this.convertedAmount,
  });

  factory GoalContribution.fromJson(Map<String, dynamic> json) {
    return GoalContribution(
      id: json['id'] as String,
      amount: parseDouble(json['amount']),
      currency: json['currency'] as String,
      contributionDate:
          DateTime.parse(json['contributionDate'] as String),
      sourceType: json['sourceType'] as String?,
      convertedAmount: parseNullableDouble(json['convertedAmount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'contributionDate': contributionDate.toIso8601String(),
      if (sourceType != null) 'sourceType': sourceType,
      if (convertedAmount != null) 'convertedAmount': convertedAmount,
    };
  }

  @override
  String toString() =>
      'GoalContribution(id: $id, amount: $amount $currency)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalContribution && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class GoalProjection {
  final double monthsRemaining;
  final double currentMonthlyPace;
  final double requiredMonthlyAmount;
  final DateTime? projectedCompletionDate;
  final double? requiredMonthlyIncome;
  final String coaching;

  const GoalProjection({
    required this.monthsRemaining,
    required this.currentMonthlyPace,
    required this.requiredMonthlyAmount,
    this.projectedCompletionDate,
    this.requiredMonthlyIncome,
    required this.coaching,
  });

  factory GoalProjection.fromJson(Map<String, dynamic> json) {
    return GoalProjection(
      monthsRemaining: parseDouble(json['monthsRemaining']),
      currentMonthlyPace:
          parseDouble(json['currentMonthlyPace']),
      requiredMonthlyAmount:
          parseDouble(json['requiredMonthlyAmount']),
      projectedCompletionDate: json['projectedCompletionDate'] != null
          ? DateTime.parse(json['projectedCompletionDate'] as String)
          : null,
      requiredMonthlyIncome:
          parseNullableDouble(json['requiredMonthlyIncome']),
      coaching: json['coaching'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthsRemaining': monthsRemaining,
      'currentMonthlyPace': currentMonthlyPace,
      'requiredMonthlyAmount': requiredMonthlyAmount,
      if (projectedCompletionDate != null)
        'projectedCompletionDate':
            projectedCompletionDate!.toIso8601String(),
      if (requiredMonthlyIncome != null)
        'requiredMonthlyIncome': requiredMonthlyIncome,
      'coaching': coaching,
    };
  }

  @override
  String toString() =>
      'GoalProjection(monthsRemaining: $monthsRemaining, requiredMonthly: $requiredMonthlyAmount)';
}
