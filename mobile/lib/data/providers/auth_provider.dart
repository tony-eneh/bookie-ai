import 'dart:async';

import 'package:bookie_ai/data/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/data/models/user_model.dart';
import 'package:bookie_ai/data/services/auth_service.dart';
import 'package:bookie_ai/data/services/storage_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final StorageService _storageService;

  late final StreamSubscription<void> _sessionSub;

  AuthNotifier(this._authService, this._storageService)
      : super(const AuthState()) {
    _sessionSub = _authService.onSessionExpired.listen((_) => _signedOut(
          message: 'Your session has expired. Please sign in again.',
        ));
  }

  @override
  void dispose() {
    _sessionSub.cancel();
    super.dispose();
  }

  Future<void> _signedOut({String? message}) async {
    await _storageService.clearSession();
    state = AuthState(status: AuthStatus.unauthenticated, error: message);
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final isAuth = await _authService.isAuthenticated();
      if (!isAuth) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      final user = await _authService.getCurrentUser();
      await _storageService.saveUser(user);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on DioException {
      // A failed refresh clears the tokens: the session is gone. Otherwise
      // this is most likely a network problem, so fall back to the cache.
      if (!await _authService.isAuthenticated()) {
        await _signedOut();
        return;
      }
      final cachedUser = await _storageService.getUser();
      if (cachedUser != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: cachedUser,
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _authService.login(email, password);
      await _storageService.saveUser(user);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on DioException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: friendlyError(e),
      );
    }
  }

  Future<void> register(
    String email,
    String fullName,
    String password,
  ) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final onboarding = <String, String>{
        for (final (key, field) in const [
          ('currency', 'primaryCurrency'),
          ('income_style', 'incomeStyle'),
          ('financial_personality', 'financialPersonality'),
        ])
          if (_storageService.getOnboardingPreference(key) case final value?)
            field: value,
      };
      final user = await _authService.register(
        email,
        fullName,
        password,
        onboarding: onboarding,
      );
      await _storageService.saveUser(user);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on DioException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: friendlyError(e),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _authService.logout();
    } finally {
      await _signedOut();
    }
  }

  /// Saves profile fields (e.g. primaryCurrency) to the server.
  Future<void> updateProfile(Map<String, dynamic> data) async {
    await updateUser(await _authService.updateProfile(data));
  }

  /// Saves preference fields (e.g. notificationMode) to the server.
  Future<void> updatePreferences(Map<String, dynamic> data) async {
    await updateUser(await _authService.updatePreferences(data));
  }

  Future<void> updateUser(User user) async {
    await _storageService.saveUser(user);
    state = state.copyWith(user: user);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(storageServiceProvider),
  );
});
