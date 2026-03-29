import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/core/constants/api_constants.dart';
import 'package:bookie_ai/core/constants/app_constants.dart';
import 'package:bookie_ai/data/models/api_response.dart';
import 'package:bookie_ai/data/models/transaction_model.dart';
import 'package:bookie_ai/data/services/api_service.dart';

class TransactionFilters {
  final String? type;
  final String? accountId;
  final String? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int limit;

  const TransactionFilters({
    this.type,
    this.accountId,
    this.categoryId,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.limit = AppConstants.pageSize,
  });

  TransactionFilters copyWith({
    String? type,
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
  }) {
    return TransactionFilters(
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return {
      'page': page.toString(),
      'limit': limit.toString(),
      if (type != null) 'type': type,
      if (accountId != null) 'accountId': accountId,
      if (categoryId != null) 'categoryId': categoryId,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
    };
  }
}

class TransactionsNotifier
    extends StateNotifier<AsyncValue<PaginatedResponse<Transaction>>> {
  final ApiService _api;
  TransactionFilters _filters;

  TransactionsNotifier(this._api)
      : _filters = const TransactionFilters(),
        super(const AsyncValue.loading()) {
    fetchTransactions();
  }

  TransactionFilters get filters => _filters;

  Future<void> fetchTransactions({TransactionFilters? filters}) async {
    if (filters != null) _filters = filters;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _api.get(
        ApiConstants.transactions,
        queryParameters: _filters.toQueryParameters(),
      );
      return PaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => Transaction.fromJson(json),
      );
    });
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;

    _filters = _filters.copyWith(page: _filters.page + 1);
    state = await AsyncValue.guard(() async {
      final response = await _api.get(
        ApiConstants.transactions,
        queryParameters: _filters.toQueryParameters(),
      );
      final next = PaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => Transaction.fromJson(json),
      );
      return PaginatedResponse(
        data: [...current.data, ...next.data],
        total: next.total,
        page: next.page,
        limit: next.limit,
      );
    });
  }

  Future<Transaction> createTransaction(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConstants.transactions, data: data);
    final transaction =
        Transaction.fromJson(response.data['data'] as Map<String, dynamic>);

    state.whenData((paginated) {
      state = AsyncValue.data(
        PaginatedResponse(
          data: [transaction, ...paginated.data],
          total: paginated.total + 1,
          page: paginated.page,
          limit: paginated.limit,
        ),
      );
    });

    return transaction;
  }

  Future<Transaction> updateTransaction(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response =
        await _api.patch(ApiConstants.transaction(id), data: data);
    final updated =
        Transaction.fromJson(response.data['data'] as Map<String, dynamic>);

    state.whenData((paginated) {
      state = AsyncValue.data(
        PaginatedResponse(
          data: [
            for (final t in paginated.data)
              if (t.id == id) updated else t,
          ],
          total: paginated.total,
          page: paginated.page,
          limit: paginated.limit,
        ),
      );
    });

    return updated;
  }

  Future<void> deleteTransaction(String id) async {
    await _api.delete(ApiConstants.transaction(id));

    state.whenData((paginated) {
      state = AsyncValue.data(
        PaginatedResponse(
          data: paginated.data.where((t) => t.id != id).toList(),
          total: paginated.total - 1,
          page: paginated.page,
          limit: paginated.limit,
        ),
      );
    });
  }
}

final transactionsProvider = StateNotifierProvider<TransactionsNotifier,
    AsyncValue<PaginatedResponse<Transaction>>>((ref) {
  return TransactionsNotifier(ref.read(apiServiceProvider));
});
