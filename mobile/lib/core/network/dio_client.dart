import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  final _storage = const FlutterSecureStorage();

  Future<String?> getAccess() => _storage.read(key: _accessKey);
  Future<String?> getRefresh() => _storage.read(key: _refreshKey);

  Future<void> save(String access, String refresh) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> saveAccess(String access) =>
      _storage.write(key: _accessKey, value: access);

  Future<void> saveBoth(String access, String refresh) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

/// Notified when refresh fails permanently and user must re-login.
typedef OnAuthFailed = void Function();

class DioClient {
  final TokenStorage tokens;
  late final Dio dio;
  OnAuthFailed? onAuthFailed;

  // Single in-flight refresh to prevent race conditions
  Future<String?>? _refreshFuture;

  DioClient(this.tokens) {
    dio = Dio(
      BaseOptions(
        baseUrl: '${ApiConstants.baseUrl}${ApiConstants.apiPath}',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokens.getAccess();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (err, handler) async {
          final isAuthEndpoint =
              err.requestOptions.path == ApiConstants.refresh ||
                  err.requestOptions.path == ApiConstants.login;
          if (err.response?.statusCode != 401 || isAuthEndpoint) {
            return handler.next(err);
          }

          // Don't retry FormData/multipart - the body stream is consumed
          if (err.requestOptions.data is FormData) {
            return handler.next(err);
          }

          final newAccess = await _refreshIfNeeded();
          if (newAccess == null) {
            // refresh failed - tokens cleared, notify auth listener
            onAuthFailed?.call();
            return handler.next(err);
          }

          // Retry original request with new token
          try {
            final retry = err.requestOptions;
            retry.headers['Authorization'] = 'Bearer $newAccess';
            final response = await dio.fetch(retry);
            return handler.resolve(response);
          } catch (e) {
            return handler.next(err);
          }
        },
      ),
    );
  }

  /// Returns new access token, or null if refresh failed.
  /// Coalesces concurrent calls into a single in-flight refresh.
  Future<String?> _refreshIfNeeded() {
    return _refreshFuture ??= _doRefresh().whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<String?> _doRefresh() async {
    final refresh = await tokens.getRefresh();
    if (refresh == null || refresh.isEmpty) return null;
    try {
      final freshDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      final res = await freshDio.post(
        '${ApiConstants.baseUrl}${ApiConstants.apiPath}${ApiConstants.refresh}',
        data: {'refreshToken': refresh},
      );
      final newAccess = res.data['accessToken'] as String;
      final newRefresh = res.data['refreshToken'] as String?;
      if (newRefresh != null) {
        await tokens.saveBoth(newAccess, newRefresh);
      } else {
        await tokens.saveAccess(newAccess);
      }
      return newAccess;
    } catch (_) {
      await tokens.clear();
      return null;
    }
  }
}
