import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bookie_ai/data/models/user_model.dart';

const _userBoxName = 'user_box';
const _cacheBoxName = 'cache_box';
const _prefsBoxName = 'prefs_box';

const _userKey = 'current_user';
const _dashboardKey = 'dashboard_data';
const _onboardingKey = 'onboarding_completed';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  late Box<Map> _userBox;
  late Box<Map> _cacheBox;
  late Box _prefsBox;

  Future<void> init() async {
    _userBox = await Hive.openBox<Map>(_userBoxName);
    _cacheBox = await Hive.openBox<Map>(_cacheBoxName);
    _prefsBox = await Hive.openBox(_prefsBoxName);
  }

  Future<void> saveUser(User user) async {
    await _userBox.put(_userKey, user.toJson());
  }

  Future<User?> getUser() async {
    final data = _userBox.get(_userKey);
    if (data == null) return null;
    return User.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> saveDashboard(Map<String, dynamic> data) async {
    await _cacheBox.put(_dashboardKey, data);
  }

  Future<Map<String, dynamic>?> getDashboard() async {
    final data = _cacheBox.get(_dashboardKey);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<void> clearAll() async {
    await Future.wait([
      _userBox.clear(),
      _cacheBox.clear(),
      _prefsBox.clear(),
    ]);
  }

  Future<bool> isOnboardingCompleted() async {
    return _prefsBox.get(_onboardingKey, defaultValue: false) as bool;
  }

  Future<void> setOnboardingCompleted() async {
    await _prefsBox.put(_onboardingKey, true);
  }

  Future<void> saveOnboardingPreferences({
    required String currency,
    required String incomeStyle,
    required String financialPersonality,
  }) async {
    await Future.wait([
      _prefsBox.put('pref_currency', currency),
      _prefsBox.put('pref_income_style', incomeStyle),
      _prefsBox.put('pref_financial_personality', financialPersonality),
    ]);
  }

  String? getOnboardingPreference(String key) {
    return _prefsBox.get('pref_$key') as String?;
  }
}
