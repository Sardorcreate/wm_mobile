import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Keys used in SharedPreferences.
abstract class _Keys {
  static const authToken = 'auth_token';
  static const rememberMe = 'remember_me';
  static const savedLogin = 'saved_login';
}

/// Centralised auth service. Use [AuthService.instance] everywhere.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _baseUrl = 'http://192.168.137.51:8080';

  // ── Token storage ────────────────────────────────────────────────────────

  /// Persists [token]. Saves login username too when [rememberMe] is true.
  Future<void> saveToken(
      String token, {
        required bool rememberMe,
        String? login,
      }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_Keys.authToken, token);
    await prefs.setBool(_Keys.rememberMe, rememberMe);
    if (rememberMe && login != null) {
      await prefs.setString(_Keys.savedLogin, login);
    } else {
      await prefs.remove(_Keys.savedLogin);
    }
  }

  /// Returns the stored token, or null if none exists.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_Keys.authToken);
  }

  /// Returns the username saved during a remember-me login, or null.
  Future<String?> getSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_Keys.savedLogin);
  }

  Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_Keys.rememberMe) ?? false;
  }

  /// Wipes token and remember-me data (call on logout / token expiry).
  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_Keys.authToken);
    await prefs.remove(_Keys.rememberMe);
    // Keep savedLogin so the username field can be pre-filled on next open.
  }

  // ── Token validation ─────────────────────────────────────────────────────

  /// Returns true if the backend confirms [token] is still valid.
  ///
  /// Treats network errors conservatively:
  ///   - SocketException / TimeoutException  → returns null (unknown; don't log out)
  ///   - 401 / 403                           → returns false (definitely expired)
  ///   - 200                                 → returns true
  Future<bool?> validateToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/validate_token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) return true;
      if (response.statusCode == 401 || response.statusCode == 403) return false;

      // Any other status — treat as unknown.
      debugPrint('AuthService: unexpected status ${response.statusCode}');
      return null;
    } on SocketException {
      debugPrint('AuthService: no network — skipping token validation');
      return null;
    } on TimeoutException {
      debugPrint('AuthService: validate timed out — skipping');
      return null;
    } catch (e) {
      debugPrint('AuthService: validate error — $e');
      return null;
    }
  }

  /// Checks rememberMe flag, retrieves stored token and validates it.
  ///
  /// Returns:
  ///   true  → remembered + valid token   (go to ScannerScreen)
  ///   false → not remembered / invalid   (go to LoginPage)
  Future<bool> shouldAutoLogin() async {
    final remembered = await isRememberMeEnabled();
    if (!remembered) return false;

    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    final valid = await validateToken(token);
    // null means network is down → give benefit of the doubt and let user in.
    // The AuthGuard will catch expiry once connectivity is restored.
    return valid != false;
  }

  // ── Login API call ───────────────────────────────────────────────────────

  /// Calls the login endpoint and returns the token on success.
  /// Throws a descriptive [AuthException] on any failure.
  Future<String> login(String username, String password) async {
    late http.Response response;

    try {
      response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'login': username, 'password': password}),
      ).timeout(const Duration(seconds: 15));
    } on SocketException {
      throw AuthException('Server topilmadi. Tarmoqni tekshiring.');
    } on TimeoutException {
      throw AuthException('Ulanish vaqti tugadi.');
    } on FormatException {
      throw AuthException("Server javobi noto'g'ri formatda.");
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token']
          ?? data['access_token']
          ?? data['accessToken']
          ?? data['jwt']
          ?? data['authorization'];

      if (token == null || (token as String).isEmpty) {
        throw AuthException('Login muvaffaqiyatli, lekin token topilmadi');
      }
      return token as String;
    }

    // Non-200 — extract server message if possible.
    String message = 'Login amalga oshmadi';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      message = (err['message'] ?? err['error'] ?? message) as String;
    } catch (_) {
      if (response.body.isNotEmpty) message = response.body;
    }
    throw AuthException(message);
  }
}

/// Typed exception carrying a user-friendly message.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}