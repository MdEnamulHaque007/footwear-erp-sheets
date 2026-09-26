import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/errors/sheet_exceptions.dart';
import '../models/sheet_data.dart';

/// A public Google Sheet source. Ranges use A1 notation, such as A1:H1 and A2:H.
class SheetSource {
  const SheetSource({
    required this.spreadsheetId,
    required this.sheetName,
    required this.dataRange,
    required this.headerRange,
  });

  final String spreadsheetId;
  final String sheetName;
  final String dataRange;
  final String headerRange;

  static String extractId(String input) {
    final value = input.trim();
    final match = RegExp(r'/spreadsheets/d/([a-zA-Z0-9_-]+)').firstMatch(value);
    return match?.group(1) ?? value;
  }

  void validate() {
    final headerMatch =
        RegExp(r'^([A-Za-z]+)([1-9][0-9]*):([A-Za-z]+)([1-9][0-9]*)$')
            .firstMatch(headerRange);
    final dataMatch =
        RegExp(r'^([A-Za-z]+)([1-9][0-9]*):([A-Za-z]+)([1-9][0-9]*)?$')
            .firstMatch(dataRange);
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(spreadsheetId) ||
        sheetName.trim().isEmpty ||
        headerMatch == null ||
        dataMatch == null) {
      throw const SheetConfigurationException(
          'Enter a valid spreadsheet URL/ID, sheet name, header range (A1:H1), and data range (A2:H).');
    }
    if (headerMatch.group(1)!.toUpperCase() !=
            dataMatch.group(1)!.toUpperCase() ||
        headerMatch.group(3)!.toUpperCase() !=
            dataMatch.group(3)!.toUpperCase() ||
        headerMatch.group(2) != headerMatch.group(4) ||
        int.parse(dataMatch.group(2)!) <= int.parse(headerMatch.group(2)!)) {
      throw const SheetConfigurationException(
          'Use the same columns, one header row, and data rows below the header.');
    }
  }
}

/// Reads selected ranges from a sheet shared publicly for viewing.
class RangedSheetReader {
  const RangedSheetReader(this.client);

  final http.Client client;

  Future<SheetData> read(SheetSource source) async {
    source.validate();
    final headerUri = _uri(source, source.headerRange);
    final dataUri = _uri(source, source.dataRange);
    final headerRows = await _rows(headerUri);
    if (headerRows.length != 1 || headerRows.single.isEmpty) {
      throw SheetParseException('Header range must contain exactly one row.',
          uri: headerUri);
    }
    final headers = headerRows.single.map((cell) => cell.trim()).toList();
    if (headers.any((header) => header.isEmpty) ||
        headers.toSet().length != headers.length) {
      throw SheetParseException('Headers must be nonempty and unique.',
          uri: headerUri);
    }
    final dataRows = await _rows(dataUri);
    final rows = <SheetRow>[];
    for (final cells in dataRows) {
      if (cells.every((cell) => cell.trim().isEmpty)) continue;
      if (cells.length > headers.length) {
        throw SheetParseException(
            'Data has more columns than the header range.',
            uri: dataUri);
      }
      rows.add(SheetRow({
        for (var i = 0; i < headers.length; i++)
          headers[i]: i < cells.length ? cells[i] : '',
      }));
    }
    return SheetData(
        source: dataUri,
        headers: headers,
        rows: rows,
        fetchedAt: DateTime.now(),
        fromCache: false);
  }

  Uri _uri(SheetSource source, String range) => Uri.https(
        'docs.google.com',
        '/spreadsheets/d/${source.spreadsheetId}/gviz/tq',
        {
          'sheet': source.sheetName.trim(),
          'range': range.toUpperCase(),
          'headers': '0',
          'tqx': 'out:json',
        },
      );

  Future<List<List<String>>> _rows(Uri uri) async {
    http.Response response;
    try {
      response = await client.get(uri).timeout(AppConstants.requestTimeout);
    } catch (error) {
      throw SheetNetworkException('Could not load the Google Sheet.',
          cause: error, uri: uri);
    }
    if (response.statusCode != 200) {
      throw SheetNetworkException(
          'Google Sheets returned HTTP ${response.statusCode}. Check sharing and sheet details.',
          uri: uri);
    }
    try {
      final body = utf8.decode(response.bodyBytes);
      const marker = 'google.visualization.Query.setResponse(';
      final start = body.indexOf(marker);
      final end = body.lastIndexOf(');');
      if (start < 0 || end <= start)
        throw const FormatException('Invalid response');
      final payload = jsonDecode(body.substring(start + marker.length, end))
          as Map<String, dynamic>;
      if (payload['status'] == 'error') {
        final errors = payload['errors'] as List<dynamic>?;
        final detail = errors?.isNotEmpty == true
            ? (errors!.first as Map<String, dynamic>)['detailed_message'] ??
                (errors.first as Map<String, dynamic>)['message']
            : null;
        throw SheetParseException(
            'Google Sheets rejected the range or sheet name: ${detail ?? 'unknown error'}.',
            uri: uri);
      }
      final table = payload['table'] as Map<String, dynamic>;
      final columns = (table['cols'] as List<dynamic>).length;
      return (table['rows'] as List<dynamic>).map((row) {
        final cells = (row as Map<String, dynamic>)['c'] as List<dynamic>;
        return List<String>.generate(columns, (i) {
          if (i >= cells.length || cells[i] == null) return '';
          final cell = cells[i] as Map<String, dynamic>;
          return (cell['f'] ?? cell['v'] ?? '').toString();
        });
      }).toList();
    } on SheetException {
      rethrow;
    } catch (error) {
      throw SheetParseException('Could not read the Google Sheets response.',
          cause: error, uri: uri);
    }
  }
}
