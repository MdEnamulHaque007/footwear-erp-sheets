// lib/services/sheet_repository.dart
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/sheet_exceptions.dart';
import '../models/sheet_data.dart';
import 'csv_parser.dart';
import 'sheet_client.dart';

/// CSV tabs in the manufacturing workbook.
enum SheetTab {
  masterData,
  masterLc,
  po,
  cutting,
  sewing,
  production,
  issue,
  export
}

/// Configuration and schema for one Google Sheets tab.
class SheetTabSpec {
  /// Creates a tab specification with defensive header copying.
  SheetTabSpec(this.gid, List<String> requiredHeaders)
      : requiredHeaders = List.unmodifiable(requiredHeaders);

  /// Google Sheets tab GID.
  final int gid;

  /// Columns required to parse this tab.
  final List<String> requiredHeaders;
}

/// Retrieves typed CSV snapshots with per-tab header validation.
class SheetRepository {
  /// Creates a repository whose dependencies and tab definitions are injectable.
  SheetRepository(
      {required SheetClient client,
      required CsvParser parser,
      String sheetId = AppConstants.googleSheetId,
      Map<SheetTab, SheetTabSpec>? tabSpecs})
      : _client = client,
        _parser = parser,
        _sheetId = sheetId,
        _tabSpecs = Map.unmodifiable(tabSpecs ?? defaultTabSpecs);

  final SheetClient _client;
  final CsvParser _parser;
  final String _sheetId;
  final Map<SheetTab, SheetTabSpec> _tabSpecs;

  /// Default tab definitions; override header names for a different workbook.
  static final Map<SheetTab, SheetTabSpec> defaultTabSpecs = Map.unmodifiable({
    SheetTab.masterData:
        SheetTabSpec(AppConstants.masterDataSheetGid, ['Company', 'Factory']),
    SheetTab.masterLc: SheetTabSpec(
        AppConstants.masterLcSheetGid, ['LC No', 'Company', 'Quantity']),
    SheetTab.po: SheetTabSpec(
        AppConstants.poSheetGid, ['PO No', 'Article', 'Color', 'Quantity']),
    for (final tab in [
      SheetTab.cutting,
      SheetTab.sewing,
      SheetTab.production,
      SheetTab.issue,
      SheetTab.export
    ])
      tab: SheetTabSpec(
          switch (tab) {
            SheetTab.cutting => AppConstants.cuttingSheetGid,
            SheetTab.sewing => AppConstants.sewingSheetGid,
            SheetTab.production => AppConstants.productionSheetGid,
            SheetTab.issue => AppConstants.issueSheetGid,
            SheetTab.export => AppConstants.exportSheetGid,
            _ => -1,
          },
          ['Date', 'PO No', 'Article', 'Color', 'Quantity']),
  });

  /// Fetches a configured CSV tab.
  Future<SheetData> fetchTab(SheetTab tab) async {
    final spec = _tabSpecs[tab];
    if (spec == null || _sheetId.isEmpty || spec.gid < 0) {
      throw SheetConfigurationException(
          'Configure sheet ID and ${tab.name} GID.');
    }
    final uri = Uri.https('docs.google.com', '/spreadsheets/d/$_sheetId/export',
        {'format': 'csv', 'gid': spec.gid.toString()});
    final timer = Stopwatch()..start();
    try {
      final csv = await _client.fetchCsv(uri);
      return _parser.parseCsv(csv,
          source: uri, requiredHeaders: spec.requiredHeaders);
    } on SheetException {
      rethrow;
    } catch (error) {
      throw SheetParseException('Could not read ${tab.name}.',
          cause: error, uri: uri);
    } finally {
      timer.stop();
      debugPrint('Sheet ${tab.name}: ${timer.elapsedMilliseconds} ms');
    }
  }

  /// Fetches MasterData CSV.
  Future<SheetData> fetchMasterData() async => fetchTab(SheetTab.masterData);

  /// Fetches MasterLC CSV.
  Future<SheetData> fetchMasterLc() async => fetchTab(SheetTab.masterLc);

  /// Fetches PO CSV.
  Future<SheetData> fetchPo() async => fetchTab(SheetTab.po);

  /// Fetches Cutting CSV.
  Future<SheetData> fetchCutting() async => fetchTab(SheetTab.cutting);

  /// Fetches Sewing CSV.
  Future<SheetData> fetchSewing() async => fetchTab(SheetTab.sewing);

  /// Fetches Production CSV.
  Future<SheetData> fetchProduction() async => fetchTab(SheetTab.production);

  /// Fetches Issue CSV.
  Future<SheetData> fetchIssue() async => fetchTab(SheetTab.issue);

  /// Fetches Export CSV.
  Future<SheetData> fetchExport() async => fetchTab(SheetTab.export);
}
