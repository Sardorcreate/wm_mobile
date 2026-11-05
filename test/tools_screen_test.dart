import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wm_mobile/core/theme/app_theme.dart';
import 'package:wm_mobile/core/widgets/animated_background.dart';
import 'package:wm_mobile/features/auth/controller/auth_service.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/tools/data/tools_api.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/tools/presentation/pages/tools_screen.dart';

http.Response json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, Object?> tool(int id, {String status = 'RESERVE'}) => {
  'id': id,
  'tool': 'Noutbuk $id',
  'model': 'T14',
  'inventoryId': '10$id',
  'createdAt': '2026-02-01',
  'status': status,
};

/// A stand-in for the backend that records what it was asked.
class FakeBackend {
  final List<http.Request> requests = [];
  http.Response Function(http.Request)? handler;

  ToolsApi get api => ToolsApi(
    AuthService(
      client: MockClient((request) async {
        requests.add(request);
        return handler!(request);
      }),
    ).api,
  );

  Map<String, dynamic> get lastBody =>
      jsonDecode(requests.last.body) as Map<String, dynamic>;
}

void main() {
  late FakeBackend backend;

  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'A'});
    backend = FakeBackend();
    backend.handler = (request) {
      final page = int.tryParse(request.url.pathSegments.last) ?? 1;
      if (request.url.path.startsWith('/tools/tool/')) {
        return json({
          'data': [for (var i = 1; i <= 10; i++) tool((page - 1) * 10 + i)],
          'totalItems': 25,
          'totalPages': 3,
        });
      }
      if (request.url.path.startsWith('/tools/order/') ||
          request.url.path.startsWith('/tools/outcome/')) {
        return json({
          'data': [
            {'id': 42, 'createdAt': '2026-03-04'},
          ],
          'totalItems': 1,
          'totalPages': 1,
        });
      }
      return json({
        'data': [
          {
            'toolName': 'sichqoncha',
            'count': 4,
            'model': 'M1',
            'price': 150000,
            'status': 'RESERVE',
            'createdAt': '2026-01-01',
            'updatedAt': '2026-01-02',
          },
        ],
        'totalItems': 1,
        'totalPages': 1,
      });
    };
  });

  /// Runs out entrance delays. `pumpAndSettle` can't be used: the skeleton and
  /// the primary button's sheen animate forever.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: AnimatedBackground(animate: false, child: child!),
        ),
        home: Scaffold(body: ToolsScreen(api: backend.api)),
      ),
    );
    await tester.pump();
  }

  testWidgets('asks for a type first and sends nothing until then', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Iltimos, avval qurilma turini tanlang.'), findsOneWidget);
    expect(backend.requests, isEmpty);
  });

  testWidgets('choosing a type searches it and shows the rows', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Jihozlar'));
    await settle(tester);

    expect(backend.requests.single.url.path, '/tools/tool/1');
    expect(find.text('Noutbuk 1'), findsOneWidget);
    expect(find.text('Omborda'), findsWidgets);
    expect(find.text('Batafsil'), findsWidgets);
  });

  testWidgets('applied filters are sent and listed as removable chips', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Jihozlar'));
    await settle(tester);

    await tester.tap(find.text('Filtrlar'));
    await settle(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Modelni kiriting'),
      'T14',
    );
    await tester.tap(find.text('Foydalanishda'));
    await tester.pump();
    await tester.ensureVisible(find.text('dan'));
    await tester.enterText(find.widgetWithText(TextFormField, 'dan'), '100');
    await tester.enterText(find.widgetWithText(TextFormField, 'gacha'), '200');

    await tester.tap(find.text("Qo'llash"));
    await settle(tester);

    expect(backend.lastBody['model'], 'T14');
    expect(backend.lastBody['status'], 'IN_USAGE');
    expect(backend.lastBody['minPrice'], 100);
    expect(backend.lastBody['maxPrice'], 200);
    expect(
      find.textContaining('100 – 200', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Narxi filtrini olib tashlash'));
    await settle(tester);

    expect(backend.lastBody['minPrice'], isNull);
    expect(backend.lastBody['maxPrice'], isNull);
    expect(backend.lastBody['model'], 'T14');

    await tester.tap(find.text('Barchasini tozalash'));
    await settle(tester);

    expect(backend.lastBody['model'], isNull);
    expect(find.text('Barchasini tozalash'), findsNothing);
  });

  testWidgets('an invalid filter keeps the sheet open and searches nothing', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Jihozlar'));
    await settle(tester);
    final before = backend.requests.length;

    await tester.tap(find.text('Filtrlar'));
    await settle(tester);
    await tester.ensureVisible(find.text('dan'));
    await tester.enterText(find.widgetWithText(TextFormField, 'dan'), '500');
    await tester.enterText(find.widgetWithText(TextFormField, 'gacha'), '100');
    await tester.tap(find.text("Qo'llash"));
    await settle(tester);

    expect(
      find.text("Eng kam narx eng ko'p narxdan katta bo'lmasligi kerak"),
      findsOneWidget,
    );
    expect(backend.requests.length, before);
  });

  testWidgets('cancelling the sheet discards what was typed', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Jihozlar'));
    await settle(tester);
    final before = backend.requests.length;

    await tester.tap(find.text('Filtrlar'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Modelni kiriting'),
      'T14',
    );
    await tester.tap(find.text('Bekor qilish'));
    await settle(tester);

    expect(backend.requests.length, before);
    expect(find.text('Barchasini tozalash'), findsNothing);
  });

  testWidgets('switching type clears filters and the name', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Jihozlar'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Jihoz nomini kiriting'),
      'nout',
    );
    await tester.tap(find.text('Qidirish'));
    await settle(tester);
    expect(backend.lastBody['tool'], 'nout');

    await tester.tap(find.text('Tez eskiruvchilar'));
    await settle(tester);

    expect(backend.requests.last.url.path, '/tools/simp/1');
    expect(backend.lastBody['name'], isNull);
    expect(find.text('Sichqoncha'), findsOneWidget);
    // Lots have nothing to open or delete.
    expect(find.text('Batafsil'), findsNothing);
    expect(find.text("O'chirish"), findsNothing);
  });

  testWidgets('pagination moves through pages and numbers rows across them', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Jihozlar'));
    await settle(tester);

    expect(find.text('1–10 / 25 ta'), findsOneWidget);
    expect(find.byTooltip('Oldingi sahifa'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Keyingi sahifa'));
    await tester.pump();
    await tester.tap(find.byTooltip('Keyingi sahifa'));
    await settle(tester);

    expect(backend.requests.last.url.path, '/tools/tool/2');
    expect(find.text('11–20 / 25 ta'), findsOneWidget);
    expect(find.text('Noutbuk 11'), findsOneWidget);
    expect(find.text('11'), findsWidgets);
  });

  testWidgets('outcomes offer no delete; orders do, behind a confirmation', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Chiqim'));
    await settle(tester);
    expect(find.text('04.03.2026'), findsOneWidget);
    expect(find.text('Yuklab olish'), findsOneWidget);
    expect(find.text("O'chirish"), findsNothing);

    await tester.tap(find.text('Kirim'));
    await settle(tester);
    await tester.tap(find.text("O'chirish"));
    await settle(tester);
    expect(
      find.text("Siz buni rostdan ham o'chirmoqchimisiz?"),
      findsOneWidget,
    );

    // Cancelling must not delete anything.
    await tester.tap(find.text('Bekor qilish'));
    await settle(tester);
    expect(backend.requests.any((r) => r.method == 'DELETE'), isFalse);

    backend.handler = (request) => request.method == 'DELETE'
        ? http.Response("Muvaffaqqiyatli o'chirildi!", 200)
        : json({'data': [], 'totalItems': 0, 'totalPages': 0});

    await tester.tap(find.text("O'chirish"));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, "O'chirish"));
    await settle(tester);

    final deletion = backend.requests.firstWhere((r) => r.method == 'DELETE');
    expect(deletion.url.path, '/tools/order/delete');
    expect(deletion.url.queryParameters['id'], '42');
    expect(find.text('Hech narsa topilmadi'), findsOneWidget);
  });

  testWidgets('a server failure says so and can be retried', (tester) async {
    backend.handler = (_) => json({'message': 'Baza ishlamayapti'}, 500);
    await pumpScreen(tester);

    await tester.tap(find.text('Jihozlar'));
    await settle(tester);

    expect(find.text('Baza ishlamayapti'), findsOneWidget);
    expect(find.text('Hech narsa topilmadi'), findsNothing);

    backend.handler = (_) => json({
      'data': [tool(1)],
      'totalItems': 1,
      'totalPages': 1,
    });
    await tester.tap(find.text('Qayta urinish'));
    await settle(tester);

    expect(find.text('Noutbuk 1'), findsOneWidget);
  });

  testWidgets('a slow earlier response cannot replace a newer search', (
    tester,
  ) async {
    backend.handler = (request) => json({
      'data': [tool(request.url.path.contains('/tool/') ? 1 : 2)],
      'totalItems': 1,
      'totalPages': 1,
    });
    await pumpScreen(tester);

    await tester.tap(find.text('Jihozlar'));
    await tester.tap(find.text('Kirim'));
    await settle(tester);

    // Kirim was the last choice, so its row is what must be on screen.
    expect(find.text('Noutbuk 1'), findsNothing);
    expect(find.text('Yuklab olish'), findsOneWidget);
  });

  testWidgets('tapping Batafsil opens the details of that tool', (
    tester,
  ) async {
    backend.handler = (request) {
      if (request.url.path == '/tools/tool/get_one') {
        return json({
          ...tool(7, status: 'IN_USAGE'),
          'owner': 'Jasur',
          'price': 1500000,
          'currentValue': 750000.5,
          'whereFrom': 'Toshkent',
          'currentPlace': 'IT bo\'limi',
          'description': 'Yangi',
        });
      }
      return json({
        'data': [tool(7)],
        'totalItems': 1,
        'totalPages': 1,
      });
    };
    await pumpScreen(tester);
    await tester.tap(find.text('Jihozlar'));
    await settle(tester);

    await tester.tap(find.text('Batafsil'));
    await settle(tester);

    expect(backend.requests.last.url.queryParameters['id'], '7');
    expect(find.text('Jasur'), findsOneWidget);
    expect(find.text('1 500 000,00'), findsOneWidget);
    expect(find.text('750 000,50'), findsOneWidget);
    expect(find.text("Qurilmani Jasurdan olib qo'yish"), findsOneWidget);
  });

  group('layout never overflows', () {
    for (final (name, size, scale) in [
      ('a small phone', const Size(320, 568), 1.0),
      ('large system text', const Size(360, 740), 1.6),
    ]) {
      testWidgets('on $name', (tester) async {
        await pumpScreen(tester, size: size, textScale: scale);
        expect(tester.takeException(), isNull);

        for (final label in ['Jihozlar', 'Tez eskiruvchilar', 'Chiqim']) {
          await tester.tap(find.text(label));
          await settle(tester);
          expect(tester.takeException(), isNull, reason: label);
        }

        await tester.tap(find.text('Jihozlar'));
        await settle(tester);
        await tester.tap(find.text('Filtrlar'));
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'filter sheet');
      });
    }
  });
}
