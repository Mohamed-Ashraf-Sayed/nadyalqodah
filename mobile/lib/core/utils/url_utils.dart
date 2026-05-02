import '../constants/api_constants.dart';

/// URL helpers for consistent API URL building.
class AppUrl {
  AppUrl._();

  /// Builds full API URL: baseUrl + /api + path
  /// Example: AppUrl.api('/auth/login') -> https://judges.etqanly.com/api/auth/login
  static String api(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    return '${ApiConstants.baseUrl}${ApiConstants.apiPath}$p';
  }

  /// Builds file URL: baseUrl + path
  /// Used for /api/files/* endpoints (the path comes from the server already
  /// containing /api/files/...).
  static String file(String path) {
    if (path.startsWith('http')) return path;
    final p = path.startsWith('/') ? path : '/$path';
    return '${ApiConstants.baseUrl}$p';
  }
}
