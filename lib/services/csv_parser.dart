// lib/services/csv_parser.dart
import 'package:csv/csv.dart';

import '../core/errors/sheet_exceptions.dart';
import '../models/sheet_data.dart';

/// Parses CSV into immutable sheet snapshots.
class CsvParser {
  /// Creates a parser with an injectable clock.
  CsvParser({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// Parses CSV and validates caller-supplied required headers.
  SheetData parseCsv(String csv,
      {required Uri source, Iterable<String> requiredHeaders = const []}) {
    try {
      if (csv.trim().isEmpty) {
        throw SheetParseException('CSV is empty.', uri: source);
      }
      final records =
          const CsvToListConverter(shouldParseNumbers: false, eol: '\n')
              .convert(csv.replaceAll('\r\n', '\n'));
      if (records.isEmpty) {
        throw SheetParseException('CSV has no header row.', uri: source);
      }
      final headers = records.first
          .map((cell) => cell.toString().replaceFirst('\uFEFF', '').trim())
          .toList();
      if (headers.any((header) => header.isEmpty) ||
          headers.toSet().length != headers.length) {
        throw SheetParseException('CSV headers must be nonempty and unique.',
            uri: source);
      }
      final missing =
          requiredHeaders.where((header) => !headers.contains(header)).toList();
      if (missing.isNotEmpty) {
        throw SheetMissingHeaderException(
            'Missing CSV headers: ${missing.join(', ')}.',
            missingHeaders: missing,
            uri: source);
      }
      final rows = <SheetRow>[];
      for (var index = 1; index < records.length; index++) {
        final cells =
            records[index].map((cell) => cell.toString().trim()).toList();
        if (cells.every((cell) => cell.isEmpty)) continue;
        if (cells.length > headers.length) {
          throw SheetParseException(
              'CSV row ${index + 1} has more cells than headers.',
              uri: source);
        }
        rows.add(SheetRow({
          for (var column = 0; column < headers.length; column++)
            headers[column]: column < cells.length ? cells[column] : '',
        }));
      }
      return SheetData(
          source: source,
          headers: headers,
          rows: rows,
          fetchedAt: _clock(),
          fromCache: false);
    } on SheetException {
      rethrow;
    } catch (error) {
      throw SheetParseException('Could not parse CSV.',
          cause: error, uri: source);
    }
  }
}
