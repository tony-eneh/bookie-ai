class Category {
  final String id;
  final String name;
  final String type; // INCOME, EXPENSE
  final String icon;
  final String? color;
  final bool isDefault;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    this.color,
    required this.isDefault,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      icon: json['icon'] as String? ?? '📦',
      color: json['color'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      if (color != null) 'color': color,
      'isDefault': isDefault,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? type,
    String? icon,
    String? color,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Category && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
