import 'package:flutter/foundation.dart';
import '../storage/safe_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static String? _customBaseUrl;

  static void setCustomBaseUrl(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      var clean = url.trim();
      while (clean.endsWith('/')) {
        clean = clean.substring(0, clean.length - 1);
      }
      if (!clean.endsWith('/api')) {
        clean = '$clean/api';
      }
      _customBaseUrl = clean;
    } else {
      _customBaseUrl = null;
    }
  }

  // Dynamic baseUrl:
  // - If custom URL was saved by the user, use it.
  // - If passed via --dart-define=API_BASE_URL=..., use it.
  // - On Web: derives host from browser window (Uri.base) and uses port 8080.
  // - On Android/iOS: connects to the server IP via port 8080 (http://192.168.5.139:8080/api)
  //   where Nginx reverse proxies /api/ -> 5002.
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }

    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '192.168.5.139';
      if (Uri.base.port == 8080) {
        return '${Uri.base.origin}/api';
      }
      return 'http://$host:8080/api';
    }

    return 'http://192.168.5.139:8080/api';
  }

  static String get authLogin => '$baseUrl/auth/login';
  static String get employeeProfile => '$baseUrl/employees/profile';
  static String get attendance => '$baseUrl/attendance';
  static String get leaves => '$baseUrl/leaves';
  static String get permits => '$baseUrl/permits';
  static String get tasks => '$baseUrl/requests';
  static String get support => '$baseUrl/support';
  static const SafeStorage _storage = SafeStorage();

  static Future<void> saveToken(String token) =>
      _storage.write(key: 'authToken', value: token);

  static Future<void> clearToken() => _storage.delete(key: 'authToken');

  static Future<Map<String, String>> _headers(
    Map<String, String>? headers,
  ) async {
    final result = <String, String>{...?headers};
    final token = await _storage.read(key: 'authToken');
    if (token != null && token.isNotEmpty) {
      result['Authorization'] = 'Bearer $token';
    }
    return result;
  }

  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
  }) async =>
      http.get(uri, headers: await _headers(headers)).timeout(const Duration(seconds: 15));

  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async =>
      http.post(uri, headers: await _headers(headers), body: body).timeout(const Duration(seconds: 15));

  static Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async =>
      http.put(uri, headers: await _headers(headers), body: body).timeout(const Duration(seconds: 15));

  static Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async =>
      http.delete(uri, headers: await _headers(headers), body: body).timeout(const Duration(seconds: 15));

  static Future<Map<String, String>> authorizationHeaders() => _headers(null);

  static String assetUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    final uri = Uri.tryParse(path);
    if (uri != null && uri.hasScheme) return path;
    return Uri.parse(baseUrl).resolve(path).toString();
  }
}
