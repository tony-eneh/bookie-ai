import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bookie_ai/core/constants/api_constants.dart';
import 'package:bookie_ai/core/constants/app_constants.dart';

const _accessTokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref);
});

class ApiService {
  late final Dio _dio;
  final Ref _ref;
  bool _isRefreshing = false;
  final _refreshQueue = <({Completer<Response> completer, RequestOptions options})>[];

  ApiService(this._ref) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: AppConstants.requestTimeout,
        receiveTimeout: AppConstants.requestTimeout,
        sendTimeout: AppConstants.requestTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _authInterceptor(),
      _errorInterceptor(),
    ]);
  }

  FlutterSecureStorage get _storage => _ref.read(secureStorageProvider);

  // --- HTTP Methods ---

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  // --- Token Management ---

  Future<void> setTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> _getRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // --- Interceptors ---

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.contains(ApiConstants.login) &&
            !error.requestOptions.path.contains(ApiConstants.refresh)) {
          try {
            final response = await _handleTokenRefresh(error.requestOptions);
            handler.resolve(response);
          } on DioException catch (e) {
            handler.next(e);
          }
        } else {
          handler.next(error);
        }
      },
    );
  }

  Future<Response> _handleTokenRefresh(RequestOptions failedRequest) async {
    if (_isRefreshing) {
      final completer = Completer<Response>();
      _refreshQueue.add((completer: completer, options: failedRequest));
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) {
        throw DioException(
          requestOptions: failedRequest,
          type: DioExceptionType.cancel,
          error: 'No refresh token available',
        );
      }

      final refreshDio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: AppConstants.requestTimeout,
        receiveTimeout: AppConstants.requestTimeout,
        sendTimeout: AppConstants.requestTimeout,
      ));
      final response = await refreshDio.post(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken = response.data['data']['accessToken'] as String;
      final newRefreshToken = response.data['data']['refreshToken'] as String;
      await setTokens(newAccessToken, newRefreshToken);

      failedRequest.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _dio.fetch(failedRequest);

      for (final entry in _refreshQueue) {
        try {
          entry.options.headers['Authorization'] = 'Bearer $newAccessToken';
          final queuedResponse = await _dio.fetch(entry.options);
          entry.completer.complete(queuedResponse);
        } catch (e) {
          entry.completer.completeError(e);
        }
      }

      return retryResponse;
    } catch (e) {
      await clearTokens();
      for (final entry in _refreshQueue) {
        entry.completer.completeError(e);
      }
      rethrow;
    } finally {
      _isRefreshing = false;
      _refreshQueue.clear();
    }
  }

  InterceptorsWrapper _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        final message = _extractErrorMessage(error);
        handler.next(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: message,
          ),
        );
      },
    );
  }

  String _extractErrorMessage(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      return data['error'] as String? ??
          data['message'] as String? ??
          'An unexpected error occurred';
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Connection timed out. Please try again.',
      DioExceptionType.connectionError =>
        'No internet connection. Please check your network.',
      _ => error.message ?? 'An unexpected error occurred',
    };
  }
}
