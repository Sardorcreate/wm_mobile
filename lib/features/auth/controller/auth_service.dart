import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wm_mobile/core/config/app_config.dart';
import 'package:wm_mobile/core/network/api_client.dart';

/// Keys used in SharedPreferences.
abstract class _Keys {
  static const authToken = 'auth_token';
  static const refreshToken = 'refresh_token';
  static const rememberMe = 'remember_me';
  static const savedLogin = 'saved_login';
}

/// Owns the stored tokens and the refresh handshake.
/// Use [AuthService.instance] everywhere; tests build their own.
///
/// The API issues a short-lived access token and a long-lived refresh token.
/// Refresh tokens rotate: each one may be redeemed exactly once, and presenting
/// a used one is treated as theft and revokes every session of that user. That
/// makes [refreshSession]'s single-flight guard a correctness requirement, and
/// is also why the refresh token must never be handed to a WebView, whose own
/// session.js would rotate it behind the app's back.
class AuthService implements SessionDelegate {
  AuthService({
    http.Client? client,
    this.autoLoginTimeout = const Duration(seconds: 6),
  }) {
    api = ApiClient(this, client: client);
  }

  /// How long the splash screen waits for the server before giving up on
  /// skipping the login screen.
  final Duration autoLoginTimeout;

  static final AuthService instance = AuthService();

  /// Authenticated client for the whole app.
  late final ApiClient api;

  final StreamController<void> _expired = StreamController<void>.broadcast();
  Future<bool>? _refreshInFlight;

  /// Fires when the session ends without the user asking for it.
  Stream<void> get onSessionExpired => _expired.stream;

  // ── Token storage ────────────────────────────────────────────────────────

  /// Returns the stored access token, or null if none exists.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_Keys.authToken);
  }

  @override
  Future<String?> accessToken() => getToken();

  /// Returns the username saved during a remember-me login, or null.
  Future<String?> getSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_Keys.savedLogin);
  }

  Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_Keys.rememberMe) ?? false;
  }

  /// Wipes tokens and the remember-me flag. The saved username stays, so the
  /// login form can still be pre-filled.
  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_Keys.authToken);
    await prefs.remove(_Keys.refreshToken);
    await prefs.remove(_Keys.rememberMe);
  }

  Future<void> _storeTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_Keys.authToken, access);
    await prefs.setString(_Keys.refreshToken, refresh);
  }

  // ── Sign in / out ────────────────────────────────────────────────────────

  /// Signs in and stores the session. Throws [AuthException] on any failure.
  Future<void> signIn(
    String username,
    String password, {
    required bool rememberMe,
  }) async {
    final http.Response response;
    try {
      response = await api.postPublic(AppConfig.loginUri, {
        'login': username,
        'password': password,
      });
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }

    if (!response.isOk) {
      throw AuthException(response.errorMessage(_loginFailure(response)));
    }

    final tokens = _parseTokens(response);
    if (tokens == null) {
      throw const AuthException("Server javobi noto'g'ri formatda.");
    }

    await _storeTokens(tokens.access, tokens.refresh);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_Keys.rememberMe, rememberMe);
    if (rememberMe) {
      await prefs.setString(_Keys.savedLogin, username);
    } else {
      await prefs.remove(_Keys.savedLogin);
    }
  }

  /// What to say when the server gave no usable message of its own. The backend
  /// answers a bad login with JSON, so reaching this means something else
  /// answered: most often a proxy, or the wrong address.
  String _loginFailure(http.Response response) {
    final code = response.statusCode;
    if (code == 404) {
      return "Server manzili noto'g'ri: kirish sahifasi topilmadi (404).";
    }
    if (code >= 500) return 'Serverda xatolik yuz berdi ($code).';
    return 'Login amalga oshmadi ($code).';
  }

  /// Revokes the refresh token on the server, best effort, then signs out
  /// locally. Local sign-out has to happen either way.
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString(_Keys.refreshToken);
    if (refresh != null) {
      try {
        await api
            .postPublic(AppConfig.logoutUri, {'refreshToken': refresh})
            .timeout(const Duration(seconds: 5));
      } on Exception {
        // Offline, or already revoked: nothing more to do.
      }
    }
    await clearAuth();
  }

  /// Both `/auth/login` and `/auth/refresh` answer with `access` and `refresh`.
  ({String access, String refresh})? _parseTokens(http.Response response) {
    try {
      final data = jsonDecode(response.text);
      if (data is! Map) return null;
      final access = data['access'];
      final refresh = data['refresh'];
      if (access is! String || access.isEmpty) return null;
      if (refresh is! String || refresh.isEmpty) return null;
      return (access: access, refresh: refresh);
    } on FormatException {
      return null;
    }
  }

  // ── Refresh ──────────────────────────────────────────────────────────────

  @override
  Future<bool> refreshSession() {
    return _refreshInFlight ??= _redeemRefreshToken().whenComplete(
      () => _refreshInFlight = null,
    );
  }

  Future<bool> _redeemRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString(_Keys.refreshToken);
    if (current == null || current.isEmpty) return false;

    final response = await api.postPublic(AppConfig.refreshUri, {
      'refreshToken': current,
    });

    if (response.isOk) {
      final tokens = _parseTokens(response);
      if (tokens == null) {
        throw const ApiException("Server javobi noto'g'ri formatda.");
      }
      await _storeTokens(tokens.access, tokens.refresh);
      return true;
    }

    // The backend reports a bad refresh token as 409. Only an explicit rejection
    // ends the session: a 5xx, or a proxy's 404, says nothing about the token,
    // and a blip must not sign anyone out mid-shift.
    const rejected = {400, 401, 403, 409};
    if (rejected.contains(response.statusCode)) return false;

    throw ApiException(
      response.errorMessage('Server xatoligi (${response.statusCode})'),
      statusCode: response.statusCode,
    );
  }

  @override
  Future<void> endSession() async {
    await clearAuth();
    _expired.add(null);
  }

  // ── Validation ───────────────────────────────────────────────────────────

  /// Whether the session is still good, refreshing it if the access token has
  /// expired.
  ///
  /// Returns true (valid), false (definitely over), or null (could not tell, so
  /// the caller should not sign anyone out).
  Future<bool?> validateSession() async {
    try {
      final response = await api.get(AppConfig.validateTokenUri);
      if (response.isOk) return true;
      // Signed in, but not an account this API accepts.
      if (response.statusCode == 403) return false;
      return null;
    } on SessionExpiredException {
      return false;
    } on ApiException {
      return null;
    }
  }

  /// Whether the app may skip the login screen on launch.
  ///
  /// Only a session the server has just confirmed may. If the server can't be
  /// reached the answer is no, since nothing in the app works without it anyway
  /// and leftover tokens prove nothing. The tokens are kept, so the next launch
  /// with a working connection still signs in on its own.
  Future<bool> shouldAutoLogin() async {
    if (!await isRememberMeEnabled()) return false;

    final prefs = await SharedPreferences.getInstance();
    final hasSession =
        (prefs.getString(_Keys.authToken)?.isNotEmpty ?? false) ||
        (prefs.getString(_Keys.refreshToken)?.isNotEmpty ?? false);
    if (!hasSession) return false;

    final valid = await validateSession().timeout(
      autoLoginTimeout,
      onTimeout: () => null,
    );
    return valid == true;
  }

  // ── Credentials ──────────────────────────────────────────────────────────

  /// Changes the signed-in user's password. The server also revokes the user's
  /// refresh tokens, so the app asks to sign in again once the access token
  /// runs out.
  Future<void> changePassword(String newPassword) async {
    final http.Response response;
    try {
      response = await api.put(
        AppConfig.changeCredentialsUri,
        json: {'password': newPassword},
      );
    } on SessionExpiredException {
      throw const AuthException('Sessiya tugagan, qaytadan kiring');
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }

    if (response.isOk) return;

    if (response.statusCode == 403) {
      throw const AuthException('Sessiya tugagan, qaytadan kiring');
    }

    throw AuthException(response.errorMessage("Parolni o'zgartirib bo'lmadi"));
  }
}

/// Typed exception carrying a user-friendly message.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
