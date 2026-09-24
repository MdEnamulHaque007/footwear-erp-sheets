// test/step3_utils_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:footwear_erp_sheets/core/errors/sheet_exceptions.dart';
import 'package:footwear_erp_sheets/core/utils/date_utils.dart';
import 'package:footwear_erp_sheets/core/utils/voucher_generator.dart';
import 'package:footwear_erp_sheets/services/csv_parser.dart';

void main() {
  final source = Uri.parse('https://example.com/sheet.csv');
  group('CSV parsing', () {
    test('preserves Bangla and internal spaces; skips empty trailing rows', () {
      final sheet = CsvParser(clock: () => DateTime.utc(2026, 9, 24)).parseCsv(
          'Name,Color\r\n জুতা A , কালো রং \r\n,\r\n',
          source: source,
          requiredHeaders: ['Name', 'Color']);
      expect(sheet.rows, hasLength(1));
      expect(sheet.rows.single.valueOf('Name'), 'জুতা A');
      expect(sheet.rows.single.valueOf('Color'), 'কালো রং');
    });
    test('reports missing headers', () {
      expect(
          () => CsvParser()
              .parseCsv('Name\nA', source: source, requiredHeaders: ['Color']),
          throwsA(isA<SheetMissingHeaderException>()));
    });
    test('rejects empty input and extra cells', () {
      expect(() => CsvParser().parseCsv('', source: source),
          throwsA(isA<SheetParseException>()));
      expect(() => CsvParser().parseCsv('Name\nA,B', source: source),
          throwsA(isA<SheetParseException>()));
    });
  });
  test('date formats accept only specified unambiguous layouts', () {
    for (final value in ['2026-09-24', '24/09/2026', '24-09-2026']) {
      expect(formatSheetDate(parseSheetDate(value)), '2026-09-24');
    }
    for (final value in ['09/24/2026', '9/10/26', '2026/09/24', '31/02/2026']) {
      expect(() => parseSheetDate(value), throwsA(isA<SheetParseException>()));
    }
  });
  test('voucher numbering starts at one and continues past 999', () {
    final date = DateTime.utc(2026, 9, 24);
    expect(generateDailyVoucher('CUT', date, 0), 'CUT-20260924-001');
    expect(generateDailyVoucher('CUT', date, 1), 'CUT-20260924-002');
    expect(generateDailyVoucher('CUT', date, 999), 'CUT-20260924-1000');
  });
}
