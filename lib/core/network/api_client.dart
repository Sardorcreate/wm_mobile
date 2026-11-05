import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A failure with a message that is safe to show to the user.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// The session cannot be recovered. Distinct from a network failure, which must
/// never sign anyone out.
class SessionExpiredException extends ApiException {
  const SessionExpiredException([
    super.message = 'Sessiya tugadi. Iltimos, qaytadan kiring.',
  ]);
}

/// What [ApiClient] needs from whoever owns the tokens.
abstract interface class SessionDelegate {
  Future<String?> accessToken();

  /// Trades the refresh token for a new pair.
  ///
  /// Returns false when the server rejected it, meaning the session is over.
  /// Throws [ApiException] when the outcome is unknown (offline, server fault).
  Future<bool> refreshSession();

  Future<void> endSession();
}

extension ApiResponse on http.Response {
  bool get isOk => statusCode >= 200 && statusCode < 300;

  /// The body, always as UTF-8.
  ///
  /// [http.Response.body] falls back to Latin-1 when the `Content-Type` has no
  /// charset, which is how Spring sends `application/json`. That would garble
  /// every Cyrillic tool name and department.
  String get text => utf8.decode(bodyBytes, allowMalformed: true);

  /// The server's own message if it sent a usable one, otherwise [fallback].
  ///
  /// HTML is never returned: a proxy's error page must not end up in a snackbar.
  String errorMessage(String fallback) {
    final body = text.trim();
    if (body.isEmpty) return fallback;

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        for (final key in const ['message', 'error']) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) return value;
        }
      }
      return fallback;
    } on FormatException {
      final isPlainText = !body.startsWith('<') && body.length <= 200;
      return isPlainText ? body : fallback;
    }
  }
}

/// HTTP client that carries the access token and recovers from a single expiry:
/// 401 -> refresh -> replay. Mirrors `authFetch` in the web client's session.js.
class ApiClient {
  ApiClient(
    this._session, {
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  final SessionDelegate _session;
  final http.Client _client;
  final Duration timeout;

  Future<http.Response> get(Uri uri) => _authed('GET', uri);

  Future<http.Response> post(Uri uri, {Object? json}) =>
      _authed('POST', uri, json: json);

  Future<http.Response> put(Uri uri, {Object? json}) =>
      _authed('PUT', uri, json: json);

  Future<http.Response> delete(Uri uri) => _authed('DELETE', uri);

  /// For the endpoints that take no bearer token (login, refresh, logout).
  Future<http.Response> postPublic(Uri uri, Object json) =>
      _send('POST', uri, json: json);

  Future<http.Response> _authed(String method, Uri uri, {Object? json}) async {
    final usedToken = await _session.accessToken();
    var response = await _send(method, uri, json: json, token: usedToken);
    if (response.statusCode != 401) return response;

    // Another request may have refreshed while this one was in the air. Its new
    // token is already stored, so there is no reason to rotate a second time.
    if (await _session.accessToken() == usedToken) {
      if (!await _session.refreshSession()) await _expire();
    }

    response = await _send(
      method,
      uri,
      json: json,
      token: await _session.accessToken(),
    );
    if (response.statusCode == 401) await _expire();
    return response;
  }

  Future<Never> _expire() async {
    await _session.endSession();
    throw const SessionExpiredException();
  }

  Future<http.Response> _send(
    String method,
    Uri uri, {
    Object? json,
    String? token,
  }) async {
    final request = http.Request(method, uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (json != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(json);
    }

    try {
      final streamed = await _client.send(request).timeout(timeout);
      return await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw ApiException(
        'Server javob bermadi (${_target(uri)}). '
        'Manzil va tarmoqni tekshiring.',
      );
    } on TlsException catch (e) {
      _logFailure(method, uri, e);
      throw ApiException(_tlsMessage(e, uri));
    } on IOException catch (e) {
      _logFailure(method, uri, e);
      throw ApiException(_unreachableMessage(uri));
    } on http.ClientException catch (e) {
      _logFailure(method, uri, e);
      throw ApiException(_unreachableMessage(uri));
    }
  }

  /// The address is part of the message: when the app can't reach a server,
  /// which server it was trying is the first thing anyone needs to know.
  static String _target(Uri uri) => '${uri.host}:${uri.port}';

  static String _unreachableMessage(Uri uri) =>
      "Serverga ulanib bo'lmadi (${_target(uri)}). "
      'Server ishlayotganini va tarmoqni tekshiring.';

  static String _tlsMessage(TlsException error, Uri uri) {
    final detail = error.toString();
    if (detail.contains('WRONG_VERSION_NUMBER')) {
      return "Bu manzil HTTPS'ni qo'llamaydi (${_target(uri)}). "
          "Manzil http:// bilan boshlanishi kerak bo'lishi mumkin.";
    }
    if (detail.contains('CERTIFICATE_VERIFY_FAILED')) {
      return 'Server sertifikati yaroqsiz yoki muddati tugagan '
          '(${_target(uri)}). Administratorga murojaat qiling.';
    }
    return "Serverga HTTPS orqali ulanib bo'lmadi (${_target(uri)}). "
        'Manzil va tarmoqni tekshiring.';
  }

  static void _logFailure(String method, Uri uri, Object error) {
    if (kDebugMode) debugPrint('API $method ${uri.origin}${uri.path}: $error');
  }
}
