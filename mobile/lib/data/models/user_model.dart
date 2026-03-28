class User {
  final String id;
  final String email;
  final String fullName;
  final String? country;
  final String primaryCurrency;
  final List<String> secondaryCurrencies;
  final String fxPreference; // REAL_TIME, DAILY_AVERAGE, MANUAL_OVERRIDE
  final String language;
  final bool onboardingCompleted;
  final String notificationMode; // MINIMAL, STANDARD, PROACTIVE, COACH
  final String financialPersonality; // GENTLE, DIRECT, COACH_LIKE
  final String incomeStyle; // FIXED_SALARY, IRREGULAR, BUSINESS, MIXED
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.country,
    required this.primaryCurrency,
    required this.secondaryCurrencies,
    required this.fxPreference,
    required this.language,
    required this.onboardingCompleted,
    required this.notificationMode,
    required this.financialPersonality,
    required this.incomeStyle,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      country: json['country'] as String?,
      primaryCurrency: json['primaryCurrency'] as String? ?? 'USD',
      secondaryCurrencies: (json['secondaryCurrencies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      fxPreference: json['fxPreference'] as String? ?? 'REAL_TIME',
      language: json['language'] as String? ?? 'en',
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      notificationMode: json['notificationMode'] as String? ?? 'STANDARD',
      financialPersonality:
          json['financialPersonality'] as String? ?? 'GENTLE',
      incomeStyle: json['incomeStyle'] as String? ?? 'FIXED_SALARY',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'country': country,
      'primaryCurrency': primaryCurrency,
      'secondaryCurrencies': secondaryCurrencies,
      'fxPreference': fxPreference,
      'language': language,
      'onboardingCompleted': onboardingCompleted,
      'notificationMode': notificationMode,
      'financialPersonality': financialPersonality,
      'incomeStyle': incomeStyle,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? country,
    String? primaryCurrency,
    List<String>? secondaryCurrencies,
    String? fxPreference,
    String? language,
    bool? onboardingCompleted,
    String? notificationMode,
    String? financialPersonality,
    String? incomeStyle,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      country: country ?? this.country,
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      secondaryCurrencies: secondaryCurrencies ?? this.secondaryCurrencies,
      fxPreference: fxPreference ?? this.fxPreference,
      language: language ?? this.language,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      notificationMode: notificationMode ?? this.notificationMode,
      financialPersonality: financialPersonality ?? this.financialPersonality,
      incomeStyle: incomeStyle ?? this.incomeStyle,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'User(id: $id, email: $email, fullName: $fullName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is User && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
