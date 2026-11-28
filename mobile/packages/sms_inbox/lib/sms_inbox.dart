import 'package:flutter/services.dart';

/// One message from the device's SMS inbox.
typedef InboxSms = ({String address, String body, DateTime date});

/// Reads received SMS on Android. Needs the READ_SMS permission.
abstract final class SmsInbox {
  static const _channel = MethodChannel('bookie_ai/sms');

  /// Messages received after [since], newest first, at most [limit].
  static Future<List<InboxSms>> read({
    required DateTime since,
    int limit = 200,
  }) async {
    final raw = await _channel.invokeListMethod<Map>('readInbox', {
      'since': since.millisecondsSinceEpoch,
      'limit': limit,
    });
    return [
      for (final m in raw ?? const <Map>[])
        (
          address: m['address'] as String? ?? '',
          body: m['body'] as String? ?? '',
          date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        ),
    ];
  }
}
