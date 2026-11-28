import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sms_inbox/sms_inbox.dart';
import 'package:bookie_ai/core/constants/api_constants.dart';
import 'package:bookie_ai/data/services/api_service.dart';
import 'package:bookie_ai/data/services/sms_background.dart';

/// Looks like a bank/wallet transaction alert (and not an OTP or promo).
@visibleForTesting
bool looksLikeBankAlert(String body) {
  final t = body.toLowerCase();
  if (RegExp(r'\b(otp|one[- ]time|verification code|password|pin)\b').hasMatch(t)) {
    return false;
  }
  final hasAmount = RegExp(
    r'(₦|\$|₩|€|£|\b(ngn|usd|krw|eur|gbp|ghs|kes|zar|inr)\b)\s?[\d,]+(\.\d+)?|[\d,]+(\.\d+)?\s?(ngn|usd|krw|naira)\b',
  ).hasMatch(t);
  final isTransaction = RegExp(
    r'\b(debit(ed)?|credit(ed)?|spent|withdraw(n|al)?|purchase|payment|paid|transfer(red)?|txn|trx|acct|a/c|pos)\b',
  ).hasMatch(t);
  return hasAmount && isTransaction;
}

class SmsScanResult {
  const SmsScanResult({this.recorded = 0, this.duplicates = 0, this.skipped = 0});

  final int recorded;
  final int duplicates;
  final int skipped;
}

/// Reads bank alert SMS from the Android inbox and sends new ones to the
/// server, which parses, deduplicates and categorizes them. Opt-in.
class SmsImportService {
  SmsImportService(this._api);

  static const _firstScanWindow = Duration(days: 30);

  final ApiService _api;
  Future<SmsScanResult>? _running;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> isEnabled() async => isSupported && await SmsPrefs.enabled();

  /// Asks for SMS access; on success turns the feature on and makes the
  /// first scan cover the last 30 days.
  Future<bool> enable() async {
    if (!isSupported) return false;
    final status = await Permission.sms.request();
    if (!status.isGranted) return false;
    // So background pick-ups can say so (Android 13+ asks).
    await Permission.notification.request();
    await SmsPrefs.setEnabled(true);
    if (await SmsPrefs.lastScan() == null) {
      await SmsPrefs.setLastScan(DateTime.now().subtract(_firstScanWindow));
    }
    await SmsBackground.schedule();
    return true;
  }

  Future<void> disable() async {
    await SmsPrefs.setEnabled(false);
    await SmsBackground.cancel();
  }

  /// Sends bank alerts received since the last scan, oldest first. Stops at
  /// the first network error so nothing is skipped; the next scan resumes.
  Future<SmsScanResult> scan() {
    // Callers (app resume, settings) can overlap: share one run.
    return _running ??= _scan().whenComplete(() => _running = null);
  }

  Future<SmsScanResult> _scan() async {
    if (!await isEnabled() || !await Permission.sms.isGranted) {
      return const SmsScanResult();
    }
    final since = await SmsPrefs.lastScan() ??
        DateTime.now().subtract(_firstScanWindow);
    final messages = await SmsInbox.read(since: since, limit: 300)
      ..sort((a, b) => a.date.compareTo(b.date));

    var recorded = 0, duplicates = 0, skipped = 0;
    var handledUpTo = since;
    for (final m in messages) {
      if (looksLikeBankAlert(m.body)) {
        try {
          final response = await _api.post(
            ApiConstants.parseSms,
            data: {'rawText': m.body},
          );
          final data = response.data['data'];
          if (data is Map && data['duplicate'] == true) {
            duplicates++;
          } else {
            recorded++;
          }
        } on DioException catch (e) {
          final status = e.response?.statusCode;
          if (status == 422 || status == 400) {
            skipped++; // not a transaction after all
          } else {
            break; // offline or server trouble: retry from here next time
          }
        }
      }
      handledUpTo = m.date;
    }
    await SmsPrefs.setLastScan(handledUpTo);
    return SmsScanResult(
      recorded: recorded,
      duplicates: duplicates,
      skipped: skipped,
    );
  }
}

final smsImportServiceProvider = Provider<SmsImportService>((ref) {
  return SmsImportService(ref.read(apiServiceProvider));
});
