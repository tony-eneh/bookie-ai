import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bookie_ai/core/constants/api_constants.dart';
import 'package:bookie_ai/data/services/api_service.dart';
import 'package:bookie_ai/data/services/storage_service.dart';

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
  SmsImportService(this._api, this._storage);

  static const _channel = MethodChannel('bookie_ai/sms');
  static const _firstScanWindow = Duration(days: 30);

  final ApiService _api;
  final StorageService _storage;
  Future<SmsScanResult>? _running;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get isEnabled => isSupported && _storage.smsImportEnabled;

  /// Asks for SMS access; on success turns the feature on and makes the
  /// first scan cover the last 30 days.
  Future<bool> enable() async {
    if (!isSupported) return false;
    final status = await Permission.sms.request();
    if (!status.isGranted) return false;
    await _storage.setSmsImportEnabled(true);
    if (_storage.smsLastScan == null) {
      await _storage.setSmsLastScan(DateTime.now().subtract(_firstScanWindow));
    }
    return true;
  }

  Future<void> disable() => _storage.setSmsImportEnabled(false);

  /// Sends bank alerts received since the last scan, oldest first. Stops at
  /// the first network error so nothing is skipped; the next scan resumes.
  Future<SmsScanResult> scan() {
    // Callers (app resume, settings) can overlap: share one run.
    return _running ??= _scan().whenComplete(() => _running = null);
  }

  Future<SmsScanResult> _scan() async {
    if (!isEnabled || !await Permission.sms.isGranted) {
      return const SmsScanResult();
    }
    final since = _storage.smsLastScan ??
        DateTime.now().subtract(_firstScanWindow);
    final raw = await _channel.invokeListMethod<Map>('readInbox', {
      'since': since.millisecondsSinceEpoch,
      'limit': 300,
    });
    final messages = (raw ?? const [])
        .map((m) => (
              body: m['body'] as String? ?? '',
              date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
            ))
        .toList()
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
    await _storage.setSmsLastScan(handledUpTo);
    return SmsScanResult(
      recorded: recorded,
      duplicates: duplicates,
      skipped: skipped,
    );
  }
}

final smsImportServiceProvider = Provider<SmsImportService>((ref) {
  return SmsImportService(
    ref.read(apiServiceProvider),
    ref.read(storageServiceProvider),
  );
});
