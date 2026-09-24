// lib/services/sheet_service.dart
import '../core/errors/sheet_exceptions.dart';
import '../models/sheet_data.dart';
import 'cache_service.dart';
import 'sheet_repository.dart';

/// Coordinates cached and live CSV snapshots for each tab.
class SheetService {
  /// Creates a coordinator with injectable repository and cache.
  SheetService(
      {required SheetRepository repository, required CacheService cache})
      : _repository = repository,
        _cache = cache;

  final SheetRepository _repository;
  final CacheService _cache;
  final Map<SheetTab, Future<SheetData>> _inFlight = {};

  /// Returns fresh cache or live data; offline errors use the last snapshot.
  ///
  /// Concurrent requests for the same tab share one in-flight operation.
  Future<T> fetch<T extends SheetData>(SheetTab tab,
      {bool forceRefresh = false}) async {
    try {
      final existing = _inFlight[tab];
      if (existing != null) return await existing as T;
      final request = _load(tab, forceRefresh: forceRefresh);
      _inFlight[tab] = request;
      try {
        return await request as T;
      } finally {
        if (identical(_inFlight[tab], request)) _inFlight.remove(tab);
      }
    } on SheetException {
      rethrow;
    } catch (error) {
      throw SheetParseException('Could not load ${tab.name}.', cause: error);
    }
  }

  Future<SheetData> _load(SheetTab tab, {required bool forceRefresh}) async {
    if (!forceRefresh) {
      final fresh = _cache.loadSheetData(tab.name);
      if (fresh != null) return fresh;
    }
    try {
      final sheet = await _repository.fetchTab(tab);
      await _cache.saveSheetData(tab.name, sheet);
      return sheet;
    } on SheetNetworkException {
      final fallback = _cache.loadSheetData(tab.name, allowStale: true);
      if (fallback != null) return fallback;
      rethrow;
    } on SheetTimeoutException {
      final fallback = _cache.loadSheetData(tab.name, allowStale: true);
      if (fallback != null) return fallback;
      rethrow;
    } on SheetException {
      rethrow;
    } catch (error) {
      throw SheetParseException('Could not load ${tab.name}.', cause: error);
    }
  }
}
