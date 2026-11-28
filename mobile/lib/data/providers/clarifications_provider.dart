import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/core/constants/api_constants.dart';
import 'package:bookie_ai/data/models/clarification_model.dart';
import 'package:bookie_ai/data/providers/dashboard_provider.dart';
import 'package:bookie_ai/data/services/api_service.dart';

/// Pending questions Bookie has about transactions it wasn't sure of.
class ClarificationsNotifier
    extends StateNotifier<AsyncValue<List<Clarification>>> {
  ClarificationsNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetch();
  }

  final Ref _ref;
  ApiService get _api => _ref.read(apiServiceProvider);

  Future<void> fetch() async {
    state = await AsyncValue.guard(() async {
      final response = await _api.get(
        ApiConstants.clarifications,
        queryParameters: {'status': 'PENDING'},
      );
      return (response.data['data'] as List<dynamic>)
          .map((e) => Clarification.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// Answers a question, optionally recategorizing or retyping the
  /// transaction. [source] is TAP for chips, TEXT for typed answers.
  Future<void> respond(
    String id, {
    required String answerText,
    String source = 'TAP',
    String? categoryId,
    String? transactionType,
  }) async {
    await _api.post(
      ApiConstants.respondClarification(id),
      data: {
        'answerText': answerText,
        'answerSource': source,
        if (categoryId != null) 'categoryId': categoryId,
        if (transactionType != null) 'transactionType': transactionType,
      },
    );
    _remove(id);
  }

  Future<void> dismiss(String id) async {
    await _api.post(ApiConstants.dismissClarification(id));
    _remove(id);
  }

  void _remove(String id) {
    state.whenData((items) {
      state = AsyncValue.data(items.where((c) => c.id != id).toList());
    });
    // The dashboard banner shows the pending count.
    _ref.invalidate(dashboardProvider);
  }
}

final clarificationsProvider = StateNotifierProvider.autoDispose<
    ClarificationsNotifier, AsyncValue<List<Clarification>>>((ref) {
  return ClarificationsNotifier(ref);
});
