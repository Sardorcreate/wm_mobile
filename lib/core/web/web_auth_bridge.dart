import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

/// Bridges the app's auth token into pages loaded in a [WebViewController].
///
/// Both WebView screens carried their own near-identical copy of this script,
/// which had already drifted apart (one patched `fetch`/`XHR`, the other only
/// set cookies). Two fixes came along with the merge:
///
/// * The origin is now computed in Dart. The old script did
///   `'$port' ? ':' + '$port' : ''`, which is always truthy because [Uri.port]
///   falls back to the scheme's default — so `https://host` became
///   `https://host:443`.
/// * Values are injected via [jsonEncode], so a token containing a quote can no
///   longer break out of the string literal and corrupt the script.
abstract final class WebAuthBridge {
  /// Whether [uri] uses its scheme's default port, in which case it should be
  /// left out of the origin.
  static bool _hasDefaultPort(Uri uri) =>
      (uri.scheme == 'http' && uri.port == 80) ||
      (uri.scheme == 'https' && uri.port == 443);

  static String origin(Uri uri) {
    final port = _hasDefaultPort(uri) ? '' : ':${uri.port}';
    return '${uri.scheme}://${uri.host}$port';
  }

  /// Injects the token as globals, cookies, storage entries, and as an
  /// `Authorization` header on every `fetch` / `XMLHttpRequest` the page makes.
  ///
  /// Safe to call repeatedly: the script guards against double-patching the
  /// network primitives, which the old version did not — every `onPageStarted`
  /// wrapped `fetch` again, stacking a new closure per navigation.
  static Future<void> inject(
    WebViewController controller, {
    required Uri uri,
    required String? token,
  }) async {
    if (token == null || token.isEmpty) return;

    final jsToken = jsonEncode(token);
    final jsOrigin = jsonEncode(origin(uri));
    final jsHost = jsonEncode(uri.host);

    await controller.runJavaScript('''
(function () {
  var token = $jsToken;
  var origin = $jsOrigin;
  var host = $jsHost;

  window.AUTH_TOKEN = token;
  window.API_BASE_URL = origin;

  var flags = '; path=/; max-age=2592000; SameSite=Lax';
  ['auth_token', 'token', 'session'].forEach(function (name) {
    document.cookie = name + '=' + token + flags;
  });

  try {
    ['auth_token', 'token', 'access_token'].forEach(function (key) {
      localStorage.setItem(key, token);
    });
    sessionStorage.setItem('auth_token', token);
  } catch (e) {}

  // Only patch the network primitives once per document.
  if (window.__wmAuthPatched) return;
  window.__wmAuthPatched = true;

  function absolutize(url) {
    if (typeof url !== 'string') return url;
    if (/^\\/(api|auth|tools)\\//.test(url)) return origin + url;
    if (url.indexOf('localhost') !== -1 || url.indexOf('127.0.0.1') !== -1) {
      return url.replace(/localhost|127\\.0\\.0\\.1/g, host);
    }
    return url;
  }

  var originalFetch = window.fetch;
  window.fetch = function (input, init) {
    init = init || {};
    var headers = new Headers(
      (init.headers) || (input instanceof Request ? input.headers : undefined)
    );
    headers.set('Authorization', 'Bearer ' + token);
    headers.set('X-Auth-Token', token);
    init.headers = headers;

    var target = input instanceof Request
      ? new Request(absolutize(input.url), input)
      : absolutize(input);

    return originalFetch.call(window, target, init);
  };

  var proto = XMLHttpRequest.prototype;
  var originalOpen = proto.open;
  var originalSend = proto.send;

  proto.open = function (method, url) {
    arguments[1] = absolutize(url);
    return originalOpen.apply(this, arguments);
  };

  proto.send = function (body) {
    try {
      this.setRequestHeader('Authorization', 'Bearer ' + token);
      this.setRequestHeader('X-Auth-Token', token);
    } catch (e) {}
    return originalSend.call(this, body);
  };
})();
''');
  }
}
