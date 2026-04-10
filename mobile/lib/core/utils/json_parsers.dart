double? parseNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

double parseDouble(Object? value, {double fallback = 0.0}) {
  return parseNullableDouble(value) ?? fallback;
}
