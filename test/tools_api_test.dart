import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wm_mobile/core/config/app_config.dart';
import 'package:wm_mobile/core/files/file_export.dart';
import 'package:wm_mobile/core/network/api_client.dart';
import 'package:wm_mobile/features/auth/controller/auth_service.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/tools/data/tools_api.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/tools/data/tools_models.dart';
import 'package:wm_mobile/utils/formatters.dart';

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

/// Spring's JSON: UTF-8 bytes and no charset in the content type.
http.Response utf8Response(String body) => http.Response.bytes(
  utf8.encode(body),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('signIn', () {
    test('reads the access and refresh tokens the backend returns', () async {
      late http.Request sent;
      final auth = AuthService(
        client: MockClient((request) async {
          sent = request;
          return jsonResponse({
            'access': 'A1',
            'refresh': 'R1',
            'userDto': {'id': 1, 'login': 'jasur'},
          });
        }),
      );

      await auth.signIn('jasur', 'secret', rememberMe: true);

      expect(sent.url, AppConfig.loginUri);
      expect(jsonDecode(sent.body), {'login': 'jasur', 'password': 'secret'});
      expect(await auth.getToken(), 'A1');
      expect(await auth.getSavedLogin(), 'jasur');
      expect(await auth.isRememberMeEnabled(), isTrue);
    });

    test('shows the server message for a wrong password', () async {
      final auth = AuthService(
        client: MockClient(
          (_) async =>
              jsonResponse({'message': "Parol noto'g'ri kiritildi!"}, 409),
        ),
      );

      await expectLater(
        auth.signIn('jasur', 'bad', rememberMe: false),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            "Parol noto'g'ri kiritildi!",
          ),
        ),
      );
    });

    test("never shows a proxy's HTML error page", () async {
      final auth = AuthService(
        client: MockClient(
          (_) async => http.Response('<!DOCTYPE html><h1>404</h1>', 404),
        ),
      );

      await expectLater(
        auth.signIn('jasur', 'x', rememberMe: false),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            "Server manzili noto'g'ri: kirish sahifasi topilmadi (404).",
          ),
        ),
      );
    });
  });

  group('connection errors say what failed and where', () {
    Future<String> loginError(Object failure) async {
      final auth = AuthService(client: MockClient((_) async => throw failure));
      try {
        await auth.signIn('a', 'b', rememberMe: false);
      } on AuthException catch (e) {
        return e.message;
      }
      fail('signIn should have thrown');
    }

    final target = '${AppConfig.loginUri.host}:${AppConfig.loginUri.port}';

    test('https against a plain http port', () async {
      final message = await loginError(
        const HandshakeException(
          'Handshake error',
          OSError('WRONG_VERSION_NUMBER(tls_record.cc:127)'),
        ),
      );
      expect(message, contains("HTTPS'ni qo'llamaydi"));
      expect(message, contains(target));
    });

    test('a bad certificate', () async {
      final message = await loginError(
        const HandshakeException(
          'Handshake error',
          OSError('CERTIFICATE_VERIFY_FAILED'),
        ),
      );
      expect(message, contains('sertifikati yaroqsiz'));
      expect(message, contains('Administratorga murojaat qiling'));
    });

    test('any other TLS failure still says what to check', () async {
      final message = await loginError(
        const HandshakeException('Connection terminated during handshake'),
      );
      expect(message, contains("HTTPS orqali ulanib bo'lmadi"));
      expect(message, contains(target));
      expect(message, contains('Manzil va tarmoqni tekshiring'));
    });

    test('nothing listening, or no route', () async {
      final message = await loginError(
        const SocketException('Connection refused'),
      );
      expect(message, contains("ulanib bo'lmadi"));
      expect(message, contains(target));
    });

    test('a proxy 5xx is reported as a server fault', () async {
      final auth = AuthService(
        client: MockClient(
          (_) async => http.Response('<html>Bad Gateway</html>', 502),
        ),
      );
      await expectLater(
        auth.signIn('a', 'b', rememberMe: false),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Serverda xatolik yuz berdi (502).',
          ),
        ),
      );
    });
  });

  group('shouldAutoLogin', () {
    const remembered = {
      'auth_token': 'old-access',
      'refresh_token': 'old-refresh',
      'remember_me': true,
    };

    test('never signed in: stays on the login screen', () async {
      var requests = 0;
      final auth = AuthService(
        client: MockClient((_) async {
          requests++;
          return http.Response('true', 200);
        }),
      );
      expect(await auth.shouldAutoLogin(), isFalse);
      expect(requests, 0);
    });

    test('remember-me off: stays on the login screen', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'A'});
      final auth = AuthService(
        client: MockClient((_) async => http.Response('true', 200)),
      );
      expect(await auth.shouldAutoLogin(), isFalse);
    });

    test('confirmed by the server: skips the login screen', () async {
      SharedPreferences.setMockInitialValues(remembered);
      final auth = AuthService(
        client: MockClient((_) async => http.Response('true', 200)),
      );
      expect(await auth.shouldAutoLogin(), isTrue);
    });

    test('server unreachable: login screen, but tokens survive', () async {
      SharedPreferences.setMockInitialValues(remembered);
      final auth = AuthService(
        client: MockClient((_) async => throw http.ClientException('down')),
      );
      expect(await auth.shouldAutoLogin(), isFalse);
      expect(await auth.getToken(), 'old-access');
    });

    test('server hangs: the splash screen does not wait for it', () async {
      SharedPreferences.setMockInitialValues(remembered);
      final auth = AuthService(
        client: MockClient((_) => Completer<http.Response>().future),
        autoLoginTimeout: const Duration(milliseconds: 30),
      );
      expect(await auth.shouldAutoLogin(), isFalse);
    });

    test('server fault: login screen', () async {
      SharedPreferences.setMockInitialValues(remembered);
      final auth = AuthService(
        client: MockClient((_) async => http.Response('oops', 500)),
      );
      expect(await auth.shouldAutoLogin(), isFalse);
    });

    test('expired session that cannot refresh: login screen', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'old-access',
        'remember_me': true,
      });
      final auth = AuthService(
        client: MockClient((_) async => http.Response('', 401)),
      );
      expect(await auth.shouldAutoLogin(), isFalse);
      expect(await auth.getToken(), isNull);
    });

    test('expired access token, valid refresh token: signs in', () async {
      SharedPreferences.setMockInitialValues(remembered);
      final auth = AuthService(
        client: MockClient((request) async {
          if (request.url == AppConfig.refreshUri) {
            return jsonResponse({'access': 'new', 'refresh': 'new-r'});
          }
          return request.headers['Authorization'] == 'Bearer new'
              ? http.Response('true', 200)
              : http.Response('', 401);
        }),
      );
      expect(await auth.shouldAutoLogin(), isTrue);
    });
  });

  group('session refresh', () {
    setUp(
      () => SharedPreferences.setMockInitialValues({
        'auth_token': 'old-access',
        'refresh_token': 'old-refresh',
      }),
    );

    bool isRefresh(http.BaseRequest r) => r.url == AppConfig.refreshUri;

    test('401 refreshes once and replays with the new token', () async {
      final seenTokens = <String?>[];
      final auth = AuthService(
        client: MockClient((request) async {
          if (isRefresh(request)) {
            expect(jsonDecode(request.body), {'refreshToken': 'old-refresh'});
            return jsonResponse({'access': 'new-access', 'refresh': 'new-r'});
          }
          seenTokens.add(request.headers['Authorization']);
          return request.headers['Authorization'] == 'Bearer new-access'
              ? http.Response('true', 200)
              : http.Response('', 401);
        }),
      );

      expect(await auth.validateSession(), isTrue);
      expect(seenTokens, ['Bearer old-access', 'Bearer new-access']);
      expect(await auth.getToken(), 'new-access');
    });

    test('concurrent 401s redeem the refresh token only once', () async {
      // A second redemption of a rotated token revokes every session.
      var refreshes = 0;
      final refreshGate = Completer<void>();
      final auth = AuthService(
        client: MockClient((request) async {
          if (isRefresh(request)) {
            refreshes++;
            await refreshGate.future;
            return jsonResponse({'access': 'new-access', 'refresh': 'new-r'});
          }
          return request.headers['Authorization'] == 'Bearer new-access'
              ? http.Response('ok', 200)
              : http.Response('', 401);
        }),
      );

      final calls = [
        auth.api.get(AppConfig.endpoint('/a')),
        auth.api.get(AppConfig.endpoint('/b')),
        auth.api.get(AppConfig.endpoint('/c')),
      ];
      await Future<void>.delayed(const Duration(milliseconds: 20));
      refreshGate.complete();

      final responses = await Future.wait(calls);
      expect(responses.map((r) => r.statusCode), everyElement(200));
      expect(refreshes, 1);
    });

    test('a rejected refresh ends the session', () async {
      final auth = AuthService(
        client: MockClient((request) async {
          if (isRefresh(request)) {
            return jsonResponse({'message': 'Refresh token yaroqsiz'}, 409);
          }
          return http.Response('', 401);
        }),
      );
      var expiredEvents = 0;
      auth.onSessionExpired.listen((_) => expiredEvents++);

      await expectLater(
        auth.api.get(AppConfig.endpoint('/a')),
        throwsA(isA<SessionExpiredException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(await auth.getToken(), isNull);
      expect(expiredEvents, 1);
    });

    test('a server fault during refresh keeps the session', () async {
      final auth = AuthService(
        client: MockClient((request) async {
          if (isRefresh(request)) return http.Response('oops', 503);
          return http.Response('', 401);
        }),
      );

      final result = await auth.validateSession();

      expect(result, isNull);
      expect(await auth.getToken(), 'old-access');
    });

    test('being offline keeps the session', () async {
      final auth = AuthService(
        client: MockClient((_) async => throw http.ClientException('down')),
      );

      expect(await auth.validateSession(), isNull);
      expect(await auth.getToken(), 'old-access');
    });
  });

  test('changePassword sends the password in the body, not the URL', () async {
    SharedPreferences.setMockInitialValues({'auth_token': 'A'});
    late http.Request sent;
    final auth = AuthService(
      client: MockClient((request) async {
        sent = request;
        return http.Response('ok', 200);
      }),
    );

    await auth.changePassword('new-secret');

    expect(sent.method, 'PUT');
    expect(sent.url.query, isEmpty);
    expect(jsonDecode(sent.body), {'password': 'new-secret'});
  });

  group('ToolsApi.search', () {
    ToolsApi apiWith(http.Response Function(http.Request) handler) =>
        ToolsApi(AuthService(client: MockClient((r) async => handler(r))).api);

    test('sends the tool filter DTO and parses the page', () async {
      late http.Request sent;
      final api = apiWith((request) {
        sent = request;
        return jsonResponse({
          'data': [
            {
              'id': 7,
              'tool': 'Noutbuk',
              'model': 'T14',
              'inventoryId': '123',
              'createdAt': '2026-02-01',
              'status': 'IN_USAGE',
            },
          ],
          'totalItems': 21,
          'totalPages': 3,
        });
      });

      final page = await api.search(
        StockType.tool,
        const StockFilters(
          createdAt: '2026-02-01',
          status: ToolStatus.reserve,
          minPrice: 100,
          maxPrice: 200.5,
          yearsSinceIncome: 4,
          model: 'T14',
          inventoryId: '9',
        ),
        name: 'nout',
        page: 2,
      );

      expect(sent.method, 'POST');
      expect(sent.url.path, '/tools/tool/2');
      expect(jsonDecode(sent.body), {
        'createdAt': '2026-02-01',
        'tool': 'nout',
        'inventoryId': '9',
        'status': 'RESERVE',
        'model': 'T14',
        'minPrice': 100,
        'maxPrice': 200.5,
        'yearsSinceIncome': 4,
      });

      final item = page.items.single as ToolItem;
      expect(item.id, 7);
      expect(item.status, ToolStatus.inUsage);
      expect(page.totalItems, 21);
      expect(page.totalPages, 3);
    });

    test('simps search by name, and lots parse without an id', () async {
      late http.Request sent;
      final api = apiWith((request) {
        sent = request;
        return jsonResponse({
          'data': [
            {
              'toolName': 'sichqoncha',
              'count': 4,
              'price': 150000.5,
              'status': 'RESERVE',
            },
          ],
          'totalItems': 1,
          'totalPages': 1,
        });
      });

      final page = await api.search(
        StockType.simp,
        const StockFilters(model: 'M1'),
        name: 'sich',
      );

      expect(jsonDecode(sent.body), {
        'createdAt': null,
        'name': 'sich',
        'status': null,
        'model': 'M1',
      });
      final lot = page.items.single as SimpItem;
      expect(lot.count, 4);
      expect(lot.price, 150000.5);
    });

    test('documents only filter by date', () async {
      late http.Request sent;
      final api = apiWith((request) {
        sent = request;
        return jsonResponse({
          'data': [
            {'id': 3, 'createdAt': '2026-01-05'},
          ],
          'totalItems': 1,
          'totalPages': 1,
        });
      });

      final page = await api.search(
        StockType.outcome,
        const StockFilters(createdAt: '2026-01-05'),
      );

      expect(sent.url.path, '/tools/outcome/1');
      expect(jsonDecode(sent.body), {'createdAt': '2026-01-05'});
      expect((page.items.single as DocumentItem).id, 3);
    });

    test('a 404 means nothing matched', () async {
      final api = apiWith((_) => http.Response('', 404));
      final page = await api.search(StockType.tool, StockFilters.none);
      expect(page.items, isEmpty);
    });

    test('a server fault is an error, not an empty result', () async {
      final api = apiWith((_) => jsonResponse({'message': 'Xatolik'}, 500));
      await expectLater(
        api.search(StockType.tool, StockFilters.none),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message', 'Xatolik'),
        ),
      );
    });

    test('decodes Cyrillic even when no charset is declared', () async {
      final api = apiWith(
        (_) => utf8Response(
          '{"data":[{"id":1,"tool":"Принтер"}],"totalItems":1,"totalPages":1}',
        ),
      );
      final page = await api.search(StockType.tool, StockFilters.none);
      expect((page.items.single as ToolItem).name, 'Принтер');
    });

    test('a malformed response is an error, not a crash', () async {
      final api = apiWith((_) => http.Response('<html></html>', 200));
      await expectLater(
        api.search(StockType.tool, StockFilters.none),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('ToolsApi details', () {
    test('parses the tool and hides the backend placeholder place', () async {
      final api = ToolsApi(
        AuthService(
          client: MockClient(
            (r) async => jsonResponse({
              'id': 5,
              'tool': 'Monitor',
              'currentPlace': "Chiqim joyi noma'lum",
              'price': 1000,
              'currentValue': 250.5,
              'status': 'INACTIVE',
            }),
          ),
        ).api,
      );

      final tool = await api.getTool(5);

      expect(tool.currentPlace, isNull);
      expect(tool.currentValue, 250.5);
      expect(tool.status, ToolStatus.inactive);
    });

    test('the QR sheet refuses anything that is not a PDF', () async {
      final api = ToolsApi(
        AuthService(
          client: MockClient(
            (r) async => http.Response(
              '<html>',
              200,
              headers: {'content-type': 'text/html'},
            ),
          ),
        ).api,
      );

      await expectLater(api.qrSheet(5), throwsA(isA<ApiException>()));
    });

    test('downloads keep the server file name and bytes', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final api = ToolsApi(
        AuthService(
          client: MockClient(
            (r) async => http.Response.bytes(
              bytes,
              200,
              headers: {
                'content-disposition': 'attachment; filename="kirim_12.xlsx"',
              },
            ),
          ),
        ).api,
      );

      final file = await api.downloadDocument(StockType.order, 12);

      expect(file.name, 'kirim_12.xlsx');
      expect(file.bytes, bytes);
    });
  });

  group('FilterDraft', () {
    test('accepts an empty draft', () {
      expect(FilterDraft().validate(StockType.tool), isNull);
      expect(FilterDraft().toFilters(StockType.tool).applied, isEmpty);
    });

    test('rejects an inverted price range', () {
      final draft = FilterDraft(minPrice: '200', maxPrice: '100');
      expect(
        draft.validate(StockType.tool),
        "Eng kam narx eng ko'p narxdan katta bo'lmasligi kerak",
      );
    });

    test('rejects unparseable numbers instead of ignoring them', () {
      final draft = FilterDraft(minPrice: '1.2.3');
      expect(draft.validate(StockType.tool), "Son noto'g'ri kiritilgan");
    });

    test('rejects a fractional year count', () {
      final draft = FilterDraft(years: '1.5');
      expect(
        draft.validate(StockType.tool),
        "Yillar soni 0 yoki undan katta butun son bo'lishi kerak",
      );
    });

    test('accepts a decimal comma', () {
      final draft = FilterDraft(minPrice: '1500,5');
      expect(draft.validate(StockType.tool), isNull);
      expect(draft.toFilters(StockType.tool).minPrice, 1500.5);
    });

    test('drops fields that do not belong to the type', () {
      final draft = FilterDraft(
        createdAt: '2026-01-01',
        model: 'M',
        status: ToolStatus.reserve,
        inventoryId: '9',
        minPrice: '5',
        years: '2',
      );

      final simp = draft.toFilters(StockType.simp);
      expect(simp.model, 'M');
      expect(simp.inventoryId, isNull);
      expect(simp.minPrice, isNull);

      final order = draft.toFilters(StockType.order);
      expect(order.createdAt, '2026-01-01');
      expect(order.model, isNull);
      expect(order.status, isNull);
    });
  });

  group('StockFilters', () {
    test('the price range reads as a single chip', () {
      const filters = StockFilters(minPrice: 1500000, maxPrice: 2000000);
      final chip = filters.applied.single;
      expect(chip.text, '1 500 000 – 2 000 000');

      expect(filters.without(FilterKey.price).applied, isEmpty);
    });

    test('open-ended ranges say which end they are', () {
      expect(const StockFilters(minPrice: 100).applied.single.text, '≥ 100');
      expect(const StockFilters(maxPrice: 100).applied.single.text, '≤ 100');
    });
  });

  test('"Faol emas" is only offered for tools', () {
    expect(StockType.tool.statuses, contains(ToolStatus.inactive));
    expect(StockType.simp.statuses, isNot(contains(ToolStatus.inactive)));
  });

  test('outcomes cannot be deleted, because the backend has no endpoint', () {
    expect(StockType.outcome.canDelete, isFalse);
    expect(StockType.simp.canDelete, isFalse);
    expect(StockType.tool.canDelete, isTrue);
    expect(StockType.order.canDelete, isTrue);
  });

  group('formatters', () {
    test('dates are never shifted by a timezone', () {
      expect(formatDate('2026-02-01'), '01.02.2026');
      expect(formatDate('2026-02-01T23:59:59'), '01.02.2026');
      expect(formatDate(null), '-');
      expect(formatDate('nonsense'), '-');
    });

    test('prices match the web formatting', () {
      expect(formatPrice(1234567.5), '1 234 567,50');
      expect(formatPrice(0), '0,00');
      expect(formatPrice(999), '999,00');
      expect(formatPrice(null), '-');
    });

    test('sums drop trailing zeros', () {
      expect(formatSum(1500000), '1 500 000');
      expect(formatSum(1500.5), '1 500,5');
      expect(formatSum(100.25), '100,25');
      expect(formatSum(1000.0), '1 000');
    });

    test('capitalize', () {
      expect(capitalize('sichqoncha'), 'Sichqoncha');
      expect(capitalize(''), '-');
      expect(capitalize(null), '-');
    });

    test('iso dates round trip', () {
      expect(isoDate(DateTime(2026, 2, 1)), '2026-02-01');
      expect(parseIsoDate('2026-02-01'), DateTime(2026, 2, 1));
    });
  });

  group('FileExport.fileNameFrom', () {
    test('reads quoted, bare and encoded names', () {
      expect(
        FileExport.fileNameFrom('attachment; filename="a b.xlsx"', 'x'),
        'a b.xlsx',
      );
      expect(
        FileExport.fileNameFrom('attachment; filename=a.pdf', 'x'),
        'a.pdf',
      );
      expect(
        FileExport.fileNameFrom(
          "attachment; filename*=UTF-8''%D0%90.xlsx",
          'x',
        ),
        'А.xlsx',
      );
    });

    test('cannot escape the temp folder', () {
      expect(
        FileExport.fileNameFrom('attachment; filename="../../evil.sh"', 'x'),
        '_.._evil.sh',
      );
      expect(
        FileExport.fileNameFrom('attachment; filename=hisobot_14:30.xlsx', 'x'),
        'hisobot_14_30.xlsx',
      );
    });

    test('falls back when there is no usable name', () {
      expect(FileExport.fileNameFrom(null, 'fallback.xlsx'), 'fallback.xlsx');
      expect(
        FileExport.fileNameFrom('attachment', 'fallback.xlsx'),
        'fallback.xlsx',
      );
    });
  });
}
