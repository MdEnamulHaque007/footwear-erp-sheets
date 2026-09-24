// lib/models/sheet_data.dart
/// One CSV row indexed by its header names.
class SheetRow {
  SheetRow(Map<String, String> values) : _values = Map.unmodifiable(values);

  final Map<String, String> _values;

  /// Read-only view of the header-to-cell mapping.
  Map<String, String> get values => _values;

  /// Returns the cell for a header, or null when the header is absent.
  String? valueOf(String header) => _values[header];

  /// Returns a JSON-compatible copy of this row.
  Map<String, Object?> toJson() => Map.of(_values);

  /// Restores a row from persisted JSON cell text.
  factory SheetRow.fromJson(Map<String, dynamic> json) => SheetRow(
        json.map((header, value) => MapEntry(header, value as String)),
      );

  /// Returns a new row with selected header values replaced.
  SheetRow copyWith(Map<String, String> replacements) {
    return SheetRow({..._values, ...replacements});
  }
}

/// A CSV sheet snapshot, retaining UTF-8 cell text and cache provenance.
class SheetData {
  SheetData({
    required this.source,
    required List<String> headers,
    required List<SheetRow> rows,
    required this.fetchedAt,
    required this.fromCache,
  })  : headers = List.unmodifiable(headers),
        rows = List.unmodifiable(rows);

  final Uri source;
  final List<String> headers;
  final List<SheetRow> rows;
  final DateTime fetchedAt;
  final bool fromCache;

  /// Whether every required column is present in the CSV header.
  bool hasHeaders(Iterable<String> requiredHeaders) =>
      requiredHeaders.every(headers.contains);

  /// Whether the cached snapshot is older than the permitted age.
  bool isStale(Duration maxAge, DateTime now) =>
      now.difference(fetchedAt) > maxAge;

  /// Converts a sheet snapshot to JSON-compatible values.
  Map<String, Object?> toJson() => {
        'source': source.toString(),
        'headers': headers,
        'rows': rows.map((row) => row.toJson()).toList(),
        'fetchedAt': fetchedAt.toIso8601String(),
        'fromCache': fromCache,
      };

  /// Restores a CSV snapshot from persisted JSON.
  factory SheetData.fromJson(Map<String, dynamic> json) => SheetData(
        source: Uri.parse(json['source'] as String),
        headers: (json['headers'] as List<dynamic>).cast<String>(),
        rows: (json['rows'] as List<dynamic>)
            .map((item) => SheetRow.fromJson(item as Map<String, dynamic>))
            .toList(),
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
        fromCache: json['fromCache'] as bool,
      );

  /// Returns a new sheet snapshot with selected fields replaced.
  SheetData copyWith({
    Uri? source,
    List<String>? headers,
    List<SheetRow>? rows,
    DateTime? fetchedAt,
    bool? fromCache,
  }) {
    return SheetData(
      source: source ?? this.source,
      headers: headers ?? this.headers,
      rows: rows ?? this.rows,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}
