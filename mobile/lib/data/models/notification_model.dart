class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime? readAt;
  final Map<String, dynamic>? actionPayload;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.readAt,
    this.actionPayload,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final readAtValue = json['readAt'];
    final DateTime? parsedReadAt = readAtValue != null
        ? DateTime.parse(readAtValue as String)
        : null;

    final bool isRead = json.containsKey('isRead')
        ? json['isRead'] as bool
        : parsedReadAt != null;

    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      isRead: isRead,
      readAt: parsedReadAt,
      actionPayload: json['actionPayload'] != null
          ? Map<String, dynamic>.from(
              json['actionPayload'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'isRead': isRead,
      if (readAt != null) 'readAt': readAt!.toIso8601String(),
      if (actionPayload != null) 'actionPayload': actionPayload,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    DateTime? readAt,
    Map<String, dynamic>? actionPayload,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      actionPayload: actionPayload ?? this.actionPayload,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'AppNotification(id: $id, title: $title, isRead: $isRead)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
