import 'package:bookie_ai/data/models/category_model.dart';

class Budget {
  final String id;
  final String name;
  final String? categoryId;
  final Category? category;
  final String periodType; // WEEKLY, MONTHLY
  final double amount;
  final String currency;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  // Progress fields from API
  final double? amountUsed;
  final double? amountRemaining;
  final double? percentageUsed;
  final bool? isOverspent;
  final double? projectedOverspend;

  const Budget({
    required this.id,
    required this.name,
    this.categoryId,
    this.category,
    required this.periodType,
    required this.amount,
    required this.currency,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdAt,
    this.amountUsed,
    this.amountRemaining,
    this.percentageUsed,
    this.isOverspent,
    this.projectedOverspend,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      name: json['name'] as String,
      categoryId: json['categoryId'] as String?,
      category: json['category'] != null
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      periodType: json['periodType'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      amountUsed: (json['amountUsed'] as num?)?.toDouble(),
      amountRemaining: (json['amountRemaining'] as num?)?.toDouble(),
      percentageUsed: (json['percentageUsed'] as num?)?.toDouble(),
      isOverspent: json['isOverspent'] as bool?,
      projectedOverspend: (json['projectedOverspend'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (categoryId != null) 'categoryId': categoryId,
      'periodType': periodType,
      'amount': amount,
      'currency': currency,
      'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Budget copyWith({
    String? id,
    String? name,
    String? categoryId,
    Category? category,
    String? periodType,
    double? amount,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    double? amountUsed,
    double? amountRemaining,
    double? percentageUsed,
    bool? isOverspent,
    double? projectedOverspend,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      periodType: periodType ?? this.periodType,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      amountUsed: amountUsed ?? this.amountUsed,
      amountRemaining: amountRemaining ?? this.amountRemaining,
      percentageUsed: percentageUsed ?? this.percentageUsed,
      isOverspent: isOverspent ?? this.isOverspent,
      projectedOverspend: projectedOverspend ?? this.projectedOverspend,
    );
  }

  @override
  String toString() => 'Budget(id: $id, name: $name, amount: $amount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Budget && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
