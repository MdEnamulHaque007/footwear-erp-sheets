// lib/services/cache_service.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/dashboard_data.dart';
import '../models/sheet_data.dart';

/// Stores last valid snapshots independently of user layout preferences.
class CacheService {
  /// Creates a cache with injectable storage and clock.
  CacheService(
      {required SharedPreferences preferences,
      DateTime Function()? clock,
      this.maxAge = AppConstants.cacheMaxAge})
      : _preferences = preferences,
        _clock = clock ?? DateTime.now;

  final SharedPreferences _preferences;
  final DateTime Function() _clock;

  /// Maximum age of a fresh snapshot.
  final Duration maxAge;

  String _key(String key) => 'sheet_cache_v1_$key';

  /// Saves a sheet; returns false if local storage fails.
  Future<bool> saveSheetData(String key, SheetData sheet) async {
    try {
      return await _preferences.setString(
          _key(key), jsonEncode(sheet.toJson()));
    } catch (_) {
      return false;
    }
  }

  /// Loads fresh data, or stale data when explicitly allowed.
  SheetData? loadSheetData(String key, {bool allowStale = false}) {
    try {
      final raw = _preferences.getString(_key(key));
      if (raw == null) return null;
      final sheet = SheetData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (!allowStale && sheet.isStale(maxAge, _clock())) return null;
      return sheet.copyWith(fromCache: true);
    } catch (_) {
      return null;
    }
  }

  /// Saves a dashboard snapshot; returns false on storage failure.
  Future<bool> saveDashboard(DashboardData dashboard) async {
    try {
      return await _preferences.setString(
          AppConstants.dashboardCachePreferenceKey,
          jsonEncode(dashboard.toJson()));
    } catch (_) {
      return false;
    }
  }

  /// Loads a dashboard snapshot; returns null for corrupt or expired data.
  DashboardData? loadDashboard({bool allowStale = false}) {
    try {
      final raw =
          _preferences.getString(AppConstants.dashboardCachePreferenceKey);
      if (raw == null) return null;
      final dashboard =
          DashboardData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (!allowStale && _clock().difference(dashboard.updatedAt) > maxAge)
        return null;
      return dashboard.copyWith(fromCache: true);
    } catch (_) {
      return null;
    }
  }

  /// Clears a single sheet snapshot without changing user preferences.
  Future<bool> clearSheetData(String key) async {
    try {
      return await _preferences.remove(_key(key));
    } catch (_) {
      return false;
    }
  }

  /// Clears all sheet and dashboard caches without changing layout settings.
  Future<bool> clearCache() async {
    try {
      final keys = _preferences
          .getKeys()
          .where((key) =>
              key.startsWith('sheet_cache_v1_') ||
              key == AppConstants.dashboardCachePreferenceKey)
          .toList();
      var success = true;
      for (final key in keys) {
        success = await _preferences.remove(key) && success;
      }
      return success;
    } catch (_) {
      return false;
    }
  }
}
