import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/core/constants/api_constants.dart';
import 'package:bookie_ai/data/models/notification_model.dart';
import 'package:bookie_ai/data/services/api_service.dart';

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  NotificationsNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetch();
  }

  final Ref _ref;
  ApiService get _api => _ref.read(apiServiceProvider);

  Future<void> fetch() async {
    state = await AsyncValue.guard(() async {
      final response = await _api.get(ApiConstants.notifications);
      final body = response.data['data'];
      final items = body is List ? body : (body as Map)['data'] as List;
      return items
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> markRead(String id) async {
    await _api.patch(ApiConstants.readNotification(id));
    await fetch();
    _ref.invalidate(unreadNotificationsProvider);
  }

  Future<void> markAllRead() async {
    await _api.patch(ApiConstants.readAllNotifications);
    await fetch();
    _ref.invalidate(unreadNotificationsProvider);
  }
}

final notificationsProvider = StateNotifierProvider.autoDispose<
    NotificationsNotifier, AsyncValue<List<AppNotification>>>(
  (ref) => NotificationsNotifier(ref),
);

/// Drives the dot on the dashboard bell.
final unreadNotificationsProvider = FutureProvider<int>((ref) async {
  final response =
      await ref.read(apiServiceProvider).get(ApiConstants.unreadCount);
  final data = response.data['data'];
  return (data is Map ? data['count'] as num? : null)?.toInt() ?? 0;
});
