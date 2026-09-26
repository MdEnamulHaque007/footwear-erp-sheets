import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:footwear_erp_sheets/core/errors/sheet_exceptions.dart';
import 'package:footwear_erp_sheets/services/ranged_sheet_reader.dart';

void main() {
  const source = SheetSource(
    spreadsheetId: 'test-id',
    sheetName: 'Cutting Records',
    dataRange: 'A2:B',
    headerRange: 'A1:B1',
  );

  test('reads separate header and data ranges by sheet name', () async {
    final requested = <Uri>[];
    final client = MockClient((request) async {
      requested.add(request.url);
      final isHeader = request.url.queryParameters['range'] == 'A1:B1';
      final rows = isHeader
          ? '[{"c":[{"v":"Date"},{"v":"Quantity"}]}]'
          : '[{"c":[{"v":"2026-09-26"},{"v":12}]},'
              '{"c":[{"v":"2026-09-27"},{"v":5}]}]';
      return http.Response(
        'google.visualization.Query.setResponse({"status":"ok",'
        '"table":{"cols":[{},{}],"rows":$rows}});',
        200,
      );
    });
    final result = await RangedSheetReader(client).read(source);
    expect(requested, hasLength(2));
    expect(requested.first.queryParameters['sheet'], 'Cutting Records');
    expect(result.headers, ['Date', 'Quantity']);
    expect(result.rows.map((row) => row.valueOf('Quantity')), ['12', '5']);
    client.close();
  });

  test('rejects mismatched columns and repeated header names', () async {
    expect(
      () => const SheetSource(
        spreadsheetId: 'test-id',
        sheetName: 'Cutting',
        dataRange: 'B2:C',
        headerRange: 'A1:B1',
      ).validate(),
      throwsA(isA<SheetConfigurationException>()),
    );
    final client = MockClient((_) async => http.Response(
        'google.visualization.Query.setResponse({"status":"ok",'
        '"table":{"cols":[{},{}],"rows":['
        '{"c":[{"v":"Date"},{"v":"Date"}]}]}});',
        200));
    await expectLater(RangedSheetReader(client).read(source),
        throwsA(isA<SheetParseException>()));
    client.close();
  });

  test('extracts spreadsheet ID from a pasted URL', () {
    expect(
        SheetSource.extractId(
            'https://docs.google.com/spreadsheets/d/abc_123/edit#gid=10'),
        'abc_123');
  });
}
