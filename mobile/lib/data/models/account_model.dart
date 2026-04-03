import 'package:bookie_ai/core/utils/json_parsers.dart';

class Account {
  final String id;
  final String name;
  final String type; // BANK, WALLET, CASH, SAVINGS, BUSINESS
  final String currency;
  final double currentBalance;
  final double? lastReconciledBalance;
  final DateTime? lastReconciledAt;
  final bool isPrimary;
  final bool isActive;
  final double? convertedBalance;
  final String? confidence; // HIGH, MEDIUM, LOW
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.currentBalance,
    this.lastReconciledBalance,
    this.lastReconciledAt,
    required this.isPrimary,
    required this.isActive,
    this.convertedBalance,
    this.confidence,
    required this.createdAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      currency: json['currency'] as String? ?? 'USD',
      currentBalance: parseDouble(json['currentBalance']),
      lastReconciledBalance:
          parseNullableDouble(json['lastReconciledBalance']),
      lastReconciledAt: json['lastReconciledAt'] != null
          ? DateTime.parse(json['lastReconciledAt'] as String)
          : null,
      isPrimary: json['isPrimary'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      convertedBalance: parseNullableDouble(json['convertedBalance']),
      confidence: json['confidence'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'currency': currency,
      'currentBalance': currentBalance,
      if (lastReconciledBalance != null)
        'lastReconciledBalance': lastReconciledBalance,
      if (lastReconciledAt != null)
        'lastReconciledAt': lastReconciledAt!.toIso8601String(),
      'isPrimary': isPrimary,
      'isActive': isActive,
      if (convertedBalance != null) 'convertedBalance': convertedBalance,
      if (confidence != null) 'confidence': confidence,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Account copyWith({
    String? id,
    String? name,
    String? type,
    String? currency,
    double? currentBalance,
    double? lastReconciledBalance,
    DateTime? lastReconciledAt,
    bool? isPrimary,
    bool? isActive,
    double? convertedBalance,
    String? confidence,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      currentBalance: currentBalance ?? this.currentBalance,
      lastReconciledBalance:
          lastReconciledBalance ?? this.lastReconciledBalance,
      lastReconciledAt: lastReconciledAt ?? this.lastReconciledAt,
      isPrimary: isPrimary ?? this.isPrimary,
      isActive: isActive ?? this.isActive,
      convertedBalance: convertedBalance ?? this.convertedBalance,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Account(id: $id, name: $name, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Account && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
