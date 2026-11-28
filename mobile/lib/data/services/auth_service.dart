import 'package:bookie_ai/core/constants/api_constants.dart';
import 'package:bookie_ai/data/models/user_model.dart';
import 'package:bookie_ai/data/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiServiceProvider));
});

class AuthService {
  final ApiService _api;

  AuthService(this._api);

  /// [onboarding] carries choices made before the account existed
  /// (primaryCurrency, incomeStyle, financialPersonality).
  Future<User> register(
    String email,
    String fullName,
    String password, {
    Map<String, String> onboarding = const {},
  }) async {
    final response = await _api.post(
      ApiConstants.register,
      data: {
        ...onboarding,
        'email': email,
        'fullName': fullName,
        'password': password,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    await _api.setTokens(
      data['accessToken'] as String,
      data['refreshToken'] as String,
    );

    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User> login(String email, String password) async {
    final response = await _api.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    await _api.setTokens(
      data['accessToken'] as String,
      data['refreshToken'] as String,
    );

    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Revokes the refresh token on the server, then clears local tokens even
  /// if the request fails (e.g. offline).
  Future<void> logout() async {
    try {
      final refreshToken = await _api.getRefreshToken();
      if (refreshToken != null) {
        await _api.post(
          ApiConstants.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Best effort: the user is signed out locally regardless.
    } finally {
      await _api.clearTokens();
    }
  }

  Future<User> getCurrentUser() async {
    final response = await _api.get(ApiConstants.me);
    return User.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Stream<void> get onSessionExpired => _api.onSessionExpired;

  /// Emails a reset link if the account exists (the server never says).
  Future<void> requestPasswordReset(String email) async {
    await _api.post(ApiConstants.forgotPassword, data: {'email': email});
  }

  /// PATCH /users/me (fullName, country, language, primaryCurrency).
  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.patch(ApiConstants.userProfile, data: data);
    return User.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// PATCH /users/preferences (notificationMode, financialPersonality,
  /// fxPreference, incomeStyle).
  Future<User> updatePreferences(Map<String, dynamic> data) async {
    final response =
        await _api.patch(ApiConstants.userPreferences, data: data);
    return User.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<bool> isAuthenticated() => _api.hasValidToken();
}
