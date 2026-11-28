import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:bookie_ai/data/services/sms_import_service.dart';

/// SMS import settings. Kept in SharedPreferences (not Hive) because the
/// background task reads them from another process, which Hive doesn't
/// support safely.
abstract final class SmsPrefs {
  static const _enabled = 'sms_import_enabled';
  static const _lastScan = 'sms_last_scan';

  static Future<SharedPreferences> _prefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // pick up writes from the other process
    return prefs;
  }

  static Future<bool> enabled() async =>
      (await _prefs()).getBool(_enabled) ?? false;

  static Future<void> setEnabled(bool value) async =>
      (await _prefs()).setBool(_enabled, value);

  static Future<DateTime?> lastScan() async {
    final ms = (await _prefs()).getInt(_lastScan);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> setLastScan(DateTime value) async =>
      (await _prefs()).setInt(_lastScan, value.millisecondsSinceEpoch);

  static Future<void> clear() async {
    final prefs = await _prefs();
    await prefs.remove(_enabled);
    await prefs.remove(_lastScan);
  }
}

/// Periodic background scan (~every 15 minutes, Android's minimum) so bank
/// alerts become transactions without opening the app.
abstract final class SmsBackground {
  static const _task = 'bookie_ai.sms_scan';

  static Future<void> initialize() =>
      Workmanager().initialize(smsBackgroundDispatcher);

  static Future<void> schedule() => Workmanager().registerPeriodicTask(
        _task,
        _task,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );

  static Future<void> cancel() => Workmanager().cancelByUniqueName(_task);
}

const _channel = AndroidNotificationDetails(
  'sms_import',
  'Bank SMS',
  channelDescription: 'Transactions BookieAI picked up from bank alerts',
  importance: Importance.defaultImportance,
);

Future<void> _notifyPickedUp(int count) async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  await plugin.show(
    4101,
    'Bookie picked up $count new transaction${count == 1 ? '' : 's'}',
    'From your bank SMS. Open BookieAI to review.',
    const NotificationDetails(android: _channel),
  );
}

/// Runs in a background isolate started by WorkManager.
@pragma('vm:entry-point')
void smsBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    // Same API settings as the app (main() doesn't run here).
    await dotenv.load(fileName: 'assets/env/.env', isOptional: true);
    final container = ProviderContainer();
    try {
      final result = await container.read(smsImportServiceProvider).scan();
      if (result.recorded > 0) await _notifyPickedUp(result.recorded);
      return true;
    } catch (e) {
      debugPrint('Background SMS scan failed: $e');
      return false; // WorkManager retries later
    } finally {
      container.dispose();
    }
  });
}
