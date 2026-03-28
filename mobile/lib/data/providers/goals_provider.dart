import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/core/constants/api_constants.dart';
import 'package:bookie_ai/data/models/goal_model.dart';
import 'package:bookie_ai/data/services/api_service.dart';

class GoalsNotifier extends StateNotifier<AsyncValue<List<Goal>>> {
  final ApiService _api;

  GoalsNotifier(this._api) : super(const AsyncValue.loading()) {
    fetchGoals();
  }

  Future<void> fetchGoals() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _api.get(ApiConstants.goals);
      final items = response.data['data'] as List<dynamic>;
      return items
          .map((e) => Goal.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Goal> createGoal(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConstants.goals, data: data);
    final goal =
        Goal.fromJson(response.data['data'] as Map<String, dynamic>);

    state.whenData((goals) {
      state = AsyncValue.data([...goals, goal]);
    });

    return goal;
  }

  Future<Goal> updateGoal(String id, Map<String, dynamic> data) async {
    final response = await _api.patch(ApiConstants.goal(id), data: data);
    final updated =
        Goal.fromJson(response.data['data'] as Map<String, dynamic>);

    state.whenData((goals) {
      state = AsyncValue.data([
        for (final g in goals)
          if (g.id == id) updated else g,
      ]);
    });

    return updated;
  }

  Future<void> deleteGoal(String id) async {
    await _api.delete(ApiConstants.goal(id));

    state.whenData((goals) {
      state = AsyncValue.data(
        goals.where((g) => g.id != id).toList(),
      );
    });
  }

  Future<void> addContribution(
    String goalId,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.post(
      ApiConstants.goalContributions(goalId),
      data: data,
    );
    final updated =
        Goal.fromJson(response.data['data'] as Map<String, dynamic>);

    state.whenData((goals) {
      state = AsyncValue.data([
        for (final g in goals)
          if (g.id == goalId) updated else g,
      ]);
    });
  }

  Future<GoalProjection> getProjection(String goalId) async {
    final response = await _api.get(ApiConstants.goalProjection(goalId));
    return GoalProjection.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, AsyncValue<List<Goal>>>((ref) {
  return GoalsNotifier(ref.read(apiServiceProvider));
});
