import 'package:bookie_ai/data/models/transaction_model.dart';

class Clarification {
  final String id;
  final String transactionId;
  final Transaction? transaction;
  final String question;
  final String? answerText;
  final String? answerSource; // VOICE, TEXT, TAP
  final String status; // PENDING, ANSWERED, DISMISSED
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const Clarification({
    required this.id,
    required this.transactionId,
    this.transaction,
    required this.question,
    this.answerText,
    this.answerSource,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  factory Clarification.fromJson(Map<String, dynamic> json) {
    return Clarification(
      id: json['id'] as String,
      transactionId: json['transactionId'] as String,
      transaction: json['transaction'] != null
          ? Transaction.fromJson(
              json['transaction'] as Map<String, dynamic>)
          : null,
      question: (json['questionText'] ?? json['question']) as String,
      answerText: json['answerText'] as String?,
      answerSource: json['answerSource'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'questionText': question,
      if (answerText != null) 'answerText': answerText,
      if (answerSource != null) 'answerSource': answerSource,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (resolvedAt != null)
        'resolvedAt': resolvedAt!.toIso8601String(),
    };
  }

  bool get isPending => status == 'PENDING';
  bool get isAnswered => status == 'ANSWERED';
  bool get isDismissed => status == 'DISMISSED';

  Clarification copyWith({
    String? id,
    String? transactionId,
    Transaction? transaction,
    String? question,
    String? answerText,
    String? answerSource,
    String? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return Clarification(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      transaction: transaction ?? this.transaction,
      question: question ?? this.question,
      answerText: answerText ?? this.answerText,
      answerSource: answerSource ?? this.answerSource,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  String toString() =>
      'Clarification(id: $id, status: $status, question: $question)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Clarification && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
