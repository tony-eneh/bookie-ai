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

  AuthNotifier(this._authService, this._storageService)
      : super(const AuthState());

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
        error: e.error?.toString() ?? 'Login failed',
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
      final user = await _authService.register(email, fullName, password);
      await _storageService.saveUser(user);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on DioException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.error?.toString() ?? 'Registration failed',
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _authService.logout();
    } finally {
      await _storageService.clearAll();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
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
