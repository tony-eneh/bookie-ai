import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/core/constants/api_constants.dart';
import 'package:bookie_ai/data/models/account_model.dart';
import 'package:bookie_ai/data/services/api_service.dart';

class AccountsNotifier extends StateNotifier<AsyncValue<List<Account>>> {
  final ApiService _api;

  AccountsNotifier(this._api) : super(const AsyncValue.loading()) {
    fetchAccounts();
  }

  Future<void> fetchAccounts() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _api.get(ApiConstants.accounts);
      final items = response.data['data'] as List<dynamic>;
      return items
          .map((e) => Account.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Account> createAccount(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConstants.accounts, data: data);
    final account =
        Account.fromJson(response.data['data'] as Map<String, dynamic>);

    state.whenData((accounts) {
      state = AsyncValue.data([...accounts, account]);
    });

    return account;
  }

  Future<Account> updateAccount(String id, Map<String, dynamic> data) async {
    final response = await _api.patch(ApiConstants.account(id), data: data);
    final updated =
        Account.fromJson(response.data['data'] as Map<String, dynamic>);

    state.whenData((accounts) {
      state = AsyncValue.data([
        for (final a in accounts)
          if (a.id == id) updated else a,
      ]);
    });

    return updated;
  }

  Future<void> deleteAccount(String id) async {
    await _api.delete(ApiConstants.account(id));

    state.whenData((accounts) {
      state = AsyncValue.data(
        accounts.where((a) => a.id != id).toList(),
      );
    });
  }

  Future<Account> reconcile(String id, double actualBalance) async {
    final response = await _api.post(
      ApiConstants.reconcileAccount(id),
      data: {'actualBalance': actualBalance},
    );
    final updated =
        Account.fromJson(response.data['data'] as Map<String, dynamic>);

    state.whenData((accounts) {
      state = AsyncValue.data([
        for (final a in accounts)
          if (a.id == id) updated else a,
      ]);
    });

    return updated;
  }
}

final accountsProvider =
    StateNotifierProvider<AccountsNotifier, AsyncValue<List<Account>>>((ref) {
  return AccountsNotifier(ref.read(apiServiceProvider));
});
