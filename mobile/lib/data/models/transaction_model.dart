import 'package:bookie_ai/core/utils/json_parsers.dart';
import 'package:bookie_ai/data/models/account_model.dart';
import 'package:bookie_ai/data/models/category_model.dart';

class Transaction {
  final String id;
  final String type; // INCOME, EXPENSE, TRANSFER
  final double amount;
  final String currency;
  final DateTime occurredAt;
  final String? description;
  final String? merchantName;
  final String? counterparty;
  final String? categoryId;
  final Category? category;
  final String? subcategory;
  final String sourceType; // SMS, EMAIL, VOICE, MANUAL, AI_IMPORT
  final String? note;
  final double parseConfidence;
  final double categoryConfidence;
  final String? accountId;
  final Account? account;
  final double? convertedAmount;
  final double? fxRateUsed;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.occurredAt,
    this.description,
    this.merchantName,
    this.counterparty,
    this.categoryId,
    this.category,
    this.subcategory,
    required this.sourceType,
    this.note,
    required this.parseConfidence,
    required this.categoryConfidence,
    this.accountId,
    this.account,
    this.convertedAmount,
    this.fxRateUsed,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: parseDouble(json['amount']),
      currency: json['currency'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      description: json['description'] as String?,
      merchantName: json['merchantName'] as String?,
      counterparty: json['counterparty'] as String?,
      categoryId: json['categoryId'] as String?,
      category: json['category'] != null
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      subcategory: json['subcategory'] as String?,
      sourceType: json['sourceType'] as String,
      note: json['note'] as String?,
      parseConfidence: parseDouble(json['parseConfidence'], fallback: 1.0),
      categoryConfidence:
          parseDouble(json['categoryConfidence'], fallback: 1.0),
      accountId: json['accountId'] as String?,
      account: json['account'] != null
          ? Account.fromJson(json['account'] as Map<String, dynamic>)
          : null,
      convertedAmount: parseNullableDouble(json['convertedAmount']),
      fxRateUsed: parseNullableDouble(json['fxRateUsed']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'currency': currency,
      'occurredAt': occurredAt.toIso8601String(),
      if (description != null) 'description': description,
      if (merchantName != null) 'merchantName': merchantName,
      if (counterparty != null) 'counterparty': counterparty,
      if (categoryId != null) 'categoryId': categoryId,
      if (subcategory != null) 'subcategory': subcategory,
      'sourceType': sourceType,
      if (note != null) 'note': note,
      'parseConfidence': parseConfidence,
      'categoryConfidence': categoryConfidence,
      if (accountId != null) 'accountId': accountId,
      if (convertedAmount != null) 'convertedAmount': convertedAmount,
      if (fxRateUsed != null) 'fxRateUsed': fxRateUsed,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Transaction copyWith({
    String? id,
    String? type,
    double? amount,
    String? currency,
    DateTime? occurredAt,
    String? description,
    String? merchantName,
    String? counterparty,
    String? categoryId,
    Category? category,
    String? subcategory,
    String? sourceType,
    String? note,
    double? parseConfidence,
    double? categoryConfidence,
    String? accountId,
    Account? account,
    double? convertedAmount,
    double? fxRateUsed,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      occurredAt: occurredAt ?? this.occurredAt,
      description: description ?? this.description,
      merchantName: merchantName ?? this.merchantName,
      counterparty: counterparty ?? this.counterparty,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      sourceType: sourceType ?? this.sourceType,
      note: note ?? this.note,
      parseConfidence: parseConfidence ?? this.parseConfidence,
      categoryConfidence: categoryConfidence ?? this.categoryConfidence,
      accountId: accountId ?? this.accountId,
      account: account ?? this.account,
      convertedAmount: convertedAmount ?? this.convertedAmount,
      fxRateUsed: fxRateUsed ?? this.fxRateUsed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Transaction(id: $id, type: $type, amount: $amount $currency)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Transaction && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
