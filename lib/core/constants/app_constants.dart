import 'package:flutter/material.dart';

/// Shared presentation and public Google Sheets CSV configuration.
abstract final class AppConstants {
  static const String appName = 'Footwear ERP';

  static const Color primaryColor = Color(0xFF1E40AF);
  static const Color poColor = Color(0xFF1E40AF);
  static const Color cuttingColor = Color(0xFF9333EA);
  static const Color sewingColor = Color(0xFF0891B2);
  static const Color lastingColor = Color(0xFFEA580C);
  static const Color fgIssueColor = Color(0xFF16A34A);
  static const Color exportColor = Color(0xFFDC2626);
  static const Color stockColor = Color(0xFF059669);

  static const List<Locale> supportedLocales = [Locale('en'), Locale('bn')];
  static const double cardRadius = 16;
  static const double pagePadding = 16;
  static const Duration requestTimeout = Duration(seconds: 20);
  static const Duration cacheMaxAge = Duration(hours: 24);

  static const String dashboardLayoutPreferenceKey = 'dashboard_layout_v1';
  static const String dashboardCachePreferenceKey = 'dashboard_cache_v1';

  static const String googleSheetId = String.fromEnvironment('GOOGLE_SHEET_ID');
  static const int masterDataSheetGid = int.fromEnvironment(
    'MASTER_DATA_SHEET_GID',
    defaultValue: -1,
  );
  static const int masterLcSheetGid = int.fromEnvironment(
    'MASTER_LC_SHEET_GID',
    defaultValue: -1,
  );
  static const int poSheetGid = int.fromEnvironment(
    'PO_SHEET_GID',
    defaultValue: -1,
  );
  static const int productionSheetGid = int.fromEnvironment(
    'PRODUCTION_SHEET_GID',
    defaultValue: -1,
  );
  static const int cuttingSheetGid = int.fromEnvironment(
    'CUTTING_SHEET_GID',
    defaultValue: -1,
  );
  static const int sewingSheetGid = int.fromEnvironment(
    'SEWING_SHEET_GID',
    defaultValue: -1,
  );
  static const int issueSheetGid = int.fromEnvironment(
    'ISSUE_SHEET_GID',
    defaultValue: -1,
  );
  static const int exportSheetGid = int.fromEnvironment(
    'EXPORT_SHEET_GID',
    defaultValue: -1,
  );
  static const int stockSheetGid = int.fromEnvironment(
    'STOCK_SHEET_GID',
    defaultValue: -1,
  );

  /// Builds a public CSV export URL for a configured Google Sheets tab.
  static Uri csvExportUri(int sheetGid) {
    if (googleSheetId.isEmpty || sheetGid < 0) {
      throw StateError('Configure GOOGLE_SHEET_ID and the sheet GID.');
    }
    return Uri.https(
      'docs.google.com',
      '/spreadsheets/d/$googleSheetId/export',
      {'format': 'csv', 'gid': sheetGid.toString()},
    );
  }
}
