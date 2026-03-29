import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/core/constants/api_constants.dart';
import 'package:bookie_ai/data/models/category_model.dart';
import 'package:bookie_ai/data/services/api_service.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final response = await api.get(ApiConstants.categories);
  final items = response.data['data'] as List<dynamic>;
  return items
      .map((e) => Category.fromJson(e as Map<String, dynamic>))
      .toList();
});
