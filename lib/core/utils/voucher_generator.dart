// lib/core/utils/voucher_generator.dart
import 'date_utils.dart';

/// Generates PREFIX-YYYYMMDD-NNN from an existing daily entry count.
String generateDailyVoucher(String prefix, DateTime date, int existingCount) {
  final normalized = prefix.trim().toUpperCase();
  if (!RegExp(r'^[A-Z][A-Z0-9]*$').hasMatch(normalized)) {
    throw ArgumentError.value(prefix, 'prefix', 'Use letters and digits.');
  }
  if (existingCount < 0) {
    throw ArgumentError.value(existingCount, 'existingCount', 'Must be >= 0.');
  }
  final day = formatSheetDate(date).replaceAll('-', '');
  final sequence = (existingCount + 1).toString().padLeft(3, '0');
  return '$normalized-$day-$sequence';
}
