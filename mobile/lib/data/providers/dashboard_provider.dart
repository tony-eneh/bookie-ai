import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/core/constants/api_constants.dart';
import 'package:bookie_ai/data/models/insight_model.dart';
import 'package:bookie_ai/data/services/api_service.dart';
import 'package:bookie_ai/data/services/storage_service.dart';

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final api = ref.read(apiServiceProvider);
  final storage = ref.read(storageServiceProvider);

  try {
    final response = await api.get(ApiConstants.dashboardInsights);
    final data = response.data['data'] as Map<String, dynamic>;
    await storage.saveDashboard(data);
    return DashboardData.fromJson(data);
  } catch (_) {
    final cached = await storage.getDashboard();
    if (cached != null) return DashboardData.fromJson(cached);
    rethrow;
  }
});

final weeklySummaryProvider = FutureProvider<WeeklySummary>((ref) async {
  final api = ref.read(apiServiceProvider);
  final response = await api.get(ApiConstants.weeklyInsights);
  return WeeklySummary.fromJson(response.data['data'] as Map<String, dynamic>);
});
