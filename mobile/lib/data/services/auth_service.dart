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

  Future<User> register(
    String email,
    String fullName,
    String password,
  ) async {
    final response = await _api.post(
      ApiConstants.register,
      data: {
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

  Future<void> logout() async {
    try {
      await _api.post(ApiConstants.logout);
    } finally {
      await _api.clearTokens();
    }
  }

  Future<User> getCurrentUser() async {
    final response = await _api.get(ApiConstants.me);
    return User.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> refreshToken() async {
    await _api.hasValidToken();
  }

  Future<bool> isAuthenticated() => _api.hasValidToken();
}
