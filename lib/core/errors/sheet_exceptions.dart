// lib/core/errors/sheet_exceptions.dart
/// A typed failure while fetching or interpreting a Google Sheet.
sealed class SheetException implements Exception {
  /// Creates a sheet failure with optional source details.
  const SheetException(this.message, {this.cause, this.uri});

  /// Human-readable explanation.
  final String message;

  /// Underlying exception, when available.
  final Object? cause;

  /// Source URI, when available.
  final Uri? uri;

  @override
  String toString() => '$runtimeType: $message${uri == null ? '' : ' ($uri)'}';
}

/// Network transport or HTTP failure.
final class SheetNetworkException extends SheetException {
  /// Creates a network error.
  const SheetNetworkException(super.message, {super.cause, super.uri});
}

/// Request timeout failure.
final class SheetTimeoutException extends SheetException {
  /// Creates a timeout error.
  const SheetTimeoutException(super.message, {super.cause, super.uri});
}

/// Invalid CSV, UTF-8, or date content.
final class SheetParseException extends SheetException {
  /// Creates a parsing error.
  const SheetParseException(super.message, {super.cause, super.uri});
}

/// One or more required CSV headers are absent.
final class SheetMissingHeaderException extends SheetException {
  /// Creates a missing header error.
  SheetMissingHeaderException(super.message,
      {required List<String> missingHeaders, super.cause, super.uri})
      : missingHeaders = List.unmodifiable(missingHeaders);

  /// Absent column names.
  final List<String> missingHeaders;
}

/// A sheet ID or tab GID is not configured.
final class SheetConfigurationException extends SheetException {
  /// Creates a configuration error.
  const SheetConfigurationException(super.message, {super.cause, super.uri});
}
