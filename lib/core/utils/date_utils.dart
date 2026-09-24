// lib/core/utils/date_utils.dart
import '../errors/sheet_exceptions.dart';

/// Parses YYYY-MM-DD, DD/MM/YYYY, or DD-MM-YYYY as a UTC calendar date.
DateTime parseSheetDate(String value) {
  final input = value.trim();
  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(input);
  final dayFirst =
      RegExp(r'^(\d{2})([/\-])(\d{2})\2(\d{4})$').firstMatch(input);
  if (iso == null && dayFirst == null) {
    throw SheetParseException('Ambiguous or unsupported date "$value". '
        'Use YYYY-MM-DD, DD/MM/YYYY, or DD-MM-YYYY.');
  }
  final year = int.parse(iso?.group(1) ?? dayFirst!.group(4)!);
  final month = int.parse(iso?.group(2) ?? dayFirst!.group(3)!);
  final day = int.parse(iso?.group(3) ?? dayFirst!.group(1)!);
  final result = DateTime.utc(year, month, day);
  if (result.year != year || result.month != month || result.day != day) {
    throw SheetParseException('Invalid calendar date "$value".');
  }
  return result;
}

/// Formats a date as YYYY-MM-DD.
String formatSheetDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
