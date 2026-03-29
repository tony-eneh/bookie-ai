import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/core/constants/api_constants.dart';
import 'package:bookie_ai/data/models/budget_model.dart';
import 'package:bookie_ai/data/services/api_service.dart';

class BudgetsNotifier extends StateNotifier<AsyncValue<List<Budget>>> {
  final ApiService _api;

  BudgetsNotifier(this._api) : super(const AsyncValue.loading()) {
    fetchBudgets();
  }

  Future<void> fetchBudgets() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _api.get(ApiConstants.budgets);
      final items = response.data['data'] as List<dynamic>;
      return items
          .map((e) => Budget.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Budget> createBudget(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConstants.budgets, data: data);
    final budget =
        Budget.fromJson(response.data['data'] as Map<String, dynamic>);

    state.whenData((budgets) {
      state = AsyncValue.data([...budgets, budget]);
    });

    return budget;
  }

  Future<Budget> updateBudget(String id, Map<String, dynamic> data) async {
    final response = await _api.patch(ApiConstants.budget(id), data: data);
    final updated =
        Budget.fromJson(response.data['data'] as Map<String, dynamic>);

    state.whenData((budgets) {
      state = AsyncValue.data([
        for (final b in budgets)
          if (b.id == id) updated else b,
      ]);
    });

    return updated;
  }

  Future<void> deleteBudget(String id) async {
    await _api.delete(ApiConstants.budget(id));

    state.whenData((budgets) {
      state = AsyncValue.data(
        budgets.where((b) => b.id != id).toList(),
      );
    });
  }

  Future<Budget> getBudgetProgress(String id) async {
    final response = await _api.get(ApiConstants.budgetProgress(id));
    return Budget.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}

final budgetsProvider =
    StateNotifierProvider<BudgetsNotifier, AsyncValue<List<Budget>>>((ref) {
  return BudgetsNotifier(ref.read(apiServiceProvider));
});
