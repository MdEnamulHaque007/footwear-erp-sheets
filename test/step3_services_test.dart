// test/step3_services_test.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:footwear_erp_sheets/core/errors/sheet_exceptions.dart';
import 'package:footwear_erp_sheets/models/dashboard_data.dart';
import 'package:footwear_erp_sheets/models/sheet_data.dart';
import 'package:footwear_erp_sheets/services/cache_service.dart';
import 'package:footwear_erp_sheets/services/csv_parser.dart';
import 'package:footwear_erp_sheets/services/sheet_client.dart';
import 'package:footwear_erp_sheets/services/sheet_repository.dart';
import 'package:footwear_erp_sheets/services/sheet_service.dart';

/// Hand-written HTTP fake with explicit response control.
class FakeHttpClient extends http.BaseClient {
  FakeHttpClient(this.handler);

  final Future<http.Response> Function(http.BaseRequest request) handler;
  int calls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls++;
    final response = await handler(request);
    return http.StreamedResponse(
        Stream.value(response.bodyBytes), response.statusCode,
        headers: response.headers);
  }
}

void main() {
  final uri = Uri.parse('https://example.com/sheet.csv');
  final now = DateTime.utc(2026, 9, 24);
  const csv = 'PO No,Article,Color,Quantity\nPO-1,A,কালো,10';
  SheetData snapshot() => SheetData(
      source: uri,
      headers: ['PO No'],
      rows: [
        SheetRow({'PO No': 'PO-1'})
      ],
      fetchedAt: now,
      fromCache: false);
  SheetRepository repository(FakeHttpClient client) => SheetRepository(
          client: SheetClient(client: client, retryDelay: Duration.zero),
          parser: CsvParser(clock: () => now),
          sheetId: 'test-sheet',
          tabSpecs: {
            SheetTab.po:
                SheetTabSpec(42, ['PO No', 'Article', 'Color', 'Quantity'])
          });

  group('HTTP client', () {
    test('reads UTF-8 Bangla', () async {
      final client = FakeHttpClient((_) async => http.Response.bytes(
          utf8.encode(csv), 200,
          headers: {'content-type': 'text/csv; charset=utf-8'}));
      expect(await SheetClient(client: client).fetchCsv(uri), contains('কালো'));
    });
    test('reports timeout', () async {
      final client = FakeHttpClient((_) => Completer<http.Response>().future);
      await expectLater(
          SheetClient(client: client, timeout: const Duration(milliseconds: 1))
              .fetchCsv(uri),
          throwsA(isA<SheetTimeoutException>()));
    });
    test('retries twice on 5xx, never on 404', () async {
      final failing = FakeHttpClient((_) async => http.Response('', 500));
      await expectLater(
          SheetClient(client: failing, retryDelay: Duration.zero).fetchCsv(uri),
          throwsA(isA<SheetNetworkException>()));
      expect(failing.calls, 3);
      final missing = FakeHttpClient((_) async => http.Response('', 404));
      await expectLater(SheetClient(client: missing).fetchCsv(uri),
          throwsA(isA<SheetNetworkException>()));
      expect(missing.calls, 1);
    });
    test('recovers after a server error', () async {
      var attempts = 0;
      final client = FakeHttpClient((_) async {
        attempts++;
        return attempts == 1
            ? http.Response('', 503)
            : http.Response.bytes(utf8.encode(csv), 200);
      });
      expect(
          await SheetClient(client: client, retryDelay: Duration.zero)
              .fetchCsv(uri),
          contains('PO-1'));
      expect(client.calls, 2);
    });
  });

  group('cache and orchestration', () {
    late SharedPreferences preferences;
    late CacheService cache;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = await SharedPreferences.getInstance();
      cache = CacheService(preferences: preferences, clock: () => now);
    });
    test('reads cached data and ignores corrupted JSON', () async {
      expect(await cache.saveSheetData('po', snapshot()), isTrue);
      expect(cache.loadSheetData('po')!.fromCache, isTrue);
      await preferences.setString('sheet_cache_v1_po', '{broken');
      expect(cache.loadSheetData('po'), isNull);
    });
    test('stale data is available for offline fallback', () async {
      await cache.saveSheetData(
          'po',
          snapshot()
              .copyWith(fetchedAt: now.subtract(const Duration(days: 2))));
      expect(cache.loadSheetData('po'), isNull);
      expect(cache.loadSheetData('po', allowStale: true)!.fromCache, isTrue);
    });
    test('dashboard roundtrip and cache reset', () async {
      final dashboard = DashboardData(
          totals: const DashboardTotals(
              masterLc: 1,
              po: 10,
              cutting: 9,
              sewing: 8,
              lasting: 7,
              fgIssue: 6,
              export: 5,
              stock: 1),
          purchaseOrders: [],
          trend: [],
          alerts: [],
          recentEntries: [],
          updatedAt: now,
          fromCache: false);
      expect(await cache.saveDashboard(dashboard), isTrue);
      expect(cache.loadDashboard()!.fromCache, isTrue);
      expect(await cache.clearCache(), isTrue);
      expect(cache.loadDashboard(), isNull);
    });
    test('fresh cache hit avoids HTTP', () async {
      await cache.saveSheetData('po', snapshot());
      final client = FakeHttpClient(
          (_) async => http.Response.bytes(utf8.encode(csv), 200));
      final service =
          SheetService(repository: repository(client), cache: cache);
      expect((await service.fetch<SheetData>(SheetTab.po)).fromCache, isTrue);
      expect(client.calls, 0);
    });
    test('cache miss fetches and stores CSV', () async {
      final client = FakeHttpClient(
          (_) async => http.Response.bytes(utf8.encode(csv), 200));
      final service =
          SheetService(repository: repository(client), cache: cache);
      expect((await service.fetch<SheetData>(SheetTab.po)).fromCache, isFalse);
      expect(client.calls, 1);
      expect(cache.loadSheetData('po')!.rows, hasLength(1));
    });
    test('offline failure falls back to stale cache', () async {
      await cache.saveSheetData(
          'po',
          snapshot()
              .copyWith(fetchedAt: now.subtract(const Duration(days: 2))));
      final client = FakeHttpClient((_) async => http.Response('', 404));
      final service =
          SheetService(repository: repository(client), cache: cache);
      expect((await service.fetch<SheetData>(SheetTab.po)).fromCache, isTrue);
      expect(client.calls, 1);
    });
    test('simultaneous calls share a request', () async {
      final response = Completer<http.Response>();
      final client = FakeHttpClient((_) => response.future);
      final service =
          SheetService(repository: repository(client), cache: cache);
      final first = service.fetch<SheetData>(SheetTab.po);
      final second = service.fetch<SheetData>(SheetTab.po);
      response.complete(http.Response.bytes(utf8.encode(csv), 200));
      expect(await Future.wait([first, second]), hasLength(2));
      expect(client.calls, 1);
    });
  });
}
