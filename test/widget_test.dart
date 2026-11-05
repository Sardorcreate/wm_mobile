import 'package:flutter_test/flutter_test.dart';

import 'package:wm_mobile/core/web/web_auth_bridge.dart';
import 'package:wm_mobile/utils/url_validator.dart';

void main() {
  group('parseBrowsableUrl', () {
    test('accepts absolute http and https URLs', () {
      expect(
        parseBrowsableUrl('https://example.com/a?b=1').toString(),
        'https://example.com/a?b=1',
      );
      expect(parseBrowsableUrl('http://10.0.0.2:8080/x')?.host, '10.0.0.2');
    });

    test('assumes https for scheme-less payloads', () {
      expect(parseBrowsableUrl('example.com/path')?.scheme, 'https');
    });

    test('rejects empty, null and non-browsable payloads', () {
      expect(parseBrowsableUrl(null), isNull);
      expect(parseBrowsableUrl('   '), isNull);
      expect(parseBrowsableUrl('mailto://someone@example.com'), isNull);
    });
  });

  group('WebAuthBridge.origin', () {
    // The previous inline script always appended a port, because
    // `'$port' ? ... : ''` is truthy for the scheme's default port too.
    test('omits the port when it is the scheme default', () {
      expect(
        WebAuthBridge.origin(Uri.parse('https://wm.example.com/page')),
        'https://wm.example.com',
      );
      expect(
        WebAuthBridge.origin(Uri.parse('http://wm.example.com/page')),
        'http://wm.example.com',
      );
    });

    test('keeps an explicit non-default port', () {
      expect(
        WebAuthBridge.origin(Uri.parse('http://10.82.64.171:8080/exist.html')),
        'http://10.82.64.171:8080',
      );
    });
  });
}
