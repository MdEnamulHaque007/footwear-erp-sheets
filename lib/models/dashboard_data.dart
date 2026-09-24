// lib/models/dashboard_data.dart
import 'po_progress.dart';
import 'stage_qty.dart';

/// Totals shown in the eight dashboard KPI cards.
class DashboardTotals {
  const DashboardTotals({
    required this.masterLc,
    required this.po,
    required this.cutting,
    required this.sewing,
    required this.lasting,
    required this.fgIssue,
    required this.export,
    required this.stock,
  });

  final int masterLc;
  final int po;
  final int cutting;
  final int sewing;
  final int lasting;
  final int fgIssue;
  final int export;
  final int stock;

  /// Converts the eight KPI values to JSON-compatible values.
  Map<String, Object?> toJson() => {
        'masterLc': masterLc,
        'po': po,
        'cutting': cutting,
        'sewing': sewing,
        'lasting': lasting,
        'fgIssue': fgIssue,
        'export': export,
        'stock': stock,
      };

  /// Restores the eight KPI values from persisted JSON.
  factory DashboardTotals.fromJson(Map<String, dynamic> json) =>
      DashboardTotals(
        masterLc: (json['masterLc'] as num).toInt(),
        po: (json['po'] as num).toInt(),
        cutting: (json['cutting'] as num).toInt(),
        sewing: (json['sewing'] as num).toInt(),
        lasting: (json['lasting'] as num).toInt(),
        fgIssue: (json['fgIssue'] as num).toInt(),
        export: (json['export'] as num).toInt(),
        stock: (json['stock'] as num).toInt(),
      );

  /// Returns new dashboard totals with selected values replaced.
  DashboardTotals copyWith({
    int? masterLc,
    int? po,
    int? cutting,
    int? sewing,
    int? lasting,
    int? fgIssue,
    int? export,
    int? stock,
  }) {
    return DashboardTotals(
      masterLc: masterLc ?? this.masterLc,
      po: po ?? this.po,
      cutting: cutting ?? this.cutting,
      sewing: sewing ?? this.sewing,
      lasting: lasting ?? this.lasting,
      fgIssue: fgIssue ?? this.fgIssue,
      export: export ?? this.export,
      stock: stock ?? this.stock,
    );
  }
}

/// Daily stage totals used by the production trend chart.
class DailyProduction {
  const DailyProduction({
    required this.date,
    required this.po,
    required this.cutting,
    required this.sewing,
    required this.lasting,
    required this.fgIssue,
    required this.export,
    required this.stock,
  });

  final DateTime date;
  final int po;
  final int cutting;
  final int sewing;
  final int lasting;
  final int fgIssue;
  final int export;
  final int stock;

  /// Converts one trend point to JSON-compatible values.
  Map<String, Object?> toJson() => {
        'date': date.toIso8601String(),
        'po': po,
        'cutting': cutting,
        'sewing': sewing,
        'lasting': lasting,
        'fgIssue': fgIssue,
        'export': export,
        'stock': stock,
      };

  /// Restores one trend point from persisted JSON.
  factory DailyProduction.fromJson(Map<String, dynamic> json) =>
      DailyProduction(
        date: DateTime.parse(json['date'] as String),
        po: (json['po'] as num).toInt(),
        cutting: (json['cutting'] as num).toInt(),
        sewing: (json['sewing'] as num).toInt(),
        lasting: (json['lasting'] as num).toInt(),
        fgIssue: (json['fgIssue'] as num).toInt(),
        export: (json['export'] as num).toInt(),
        stock: (json['stock'] as num).toInt(),
      );

  /// Returns a new daily trend point with selected values replaced.
  DailyProduction copyWith({
    DateTime? date,
    int? po,
    int? cutting,
    int? sewing,
    int? lasting,
    int? fgIssue,
    int? export,
    int? stock,
  }) {
    return DailyProduction(
      date: date ?? this.date,
      po: po ?? this.po,
      cutting: cutting ?? this.cutting,
      sewing: sewing ?? this.sewing,
      lasting: lasting ?? this.lasting,
      fgIssue: fgIssue ?? this.fgIssue,
      export: export ?? this.export,
      stock: stock ?? this.stock,
    );
  }
}

/// Severity for a business-rule violation or operational warning.
enum AlertSeverity { error, warning, info }

/// One alert, optionally attached to a specific production key.
class DashboardAlert {
  const DashboardAlert({
    required this.severity,
    required this.message,
    this.key,
  });

  final AlertSeverity severity;
  final String message;
  final ProductionKey? key;

  /// Converts an alert and its optional production key to JSON.
  Map<String, Object?> toJson() => {
        'severity': severity.name,
        'message': message,
        'key':
            key == null ? null : [key!.$1, key!.$2, key!.$3, key!.$4, key!.$5],
      };

  /// Restores an alert from persisted JSON.
  factory DashboardAlert.fromJson(Map<String, dynamic> json) {
    final parts = json['key'] as List<dynamic>?;
    if (parts != null && parts.length != 5) {
      throw const FormatException('Production key needs five parts.');
    }
    return DashboardAlert(
      severity: AlertSeverity.values.byName(json['severity'] as String),
      message: json['message'] as String,
      key: parts == null
          ? null
          : (
              parts[0] as String,
              parts[1] as String,
              parts[2] as String,
              parts[3] as String,
              parts[4] as String
            ),
    );
  }

  /// Returns an alert with selected values replaced.
  DashboardAlert copyWith({
    AlertSeverity? severity,
    String? message,
    ProductionKey? key,
    bool clearKey = false,
  }) {
    return DashboardAlert(
      severity: severity ?? this.severity,
      message: message ?? this.message,
      key: clearKey ? null : key ?? this.key,
    );
  }
}

/// A compact transaction row for the recent-entries card.
class RecentTransaction {
  const RecentTransaction({
    required this.id,
    required this.stage,
    required this.date,
    required this.quantity,
    required this.factory,
  });

  final String id;
  final String stage;
  final DateTime date;
  final int quantity;
  final String factory;

  /// Converts a recent transaction to JSON-compatible values.
  Map<String, Object?> toJson() => {
        'id': id,
        'stage': stage,
        'date': date.toIso8601String(),
        'quantity': quantity,
        'factory': factory,
      };

  /// Restores a recent transaction from persisted JSON.
  factory RecentTransaction.fromJson(Map<String, dynamic> json) =>
      RecentTransaction(
        id: json['id'] as String,
        stage: json['stage'] as String,
        date: DateTime.parse(json['date'] as String),
        quantity: (json['quantity'] as num).toInt(),
        factory: json['factory'] as String,
      );

  /// Returns a new recent transaction with selected fields replaced.
  RecentTransaction copyWith({
    String? id,
    String? stage,
    DateTime? date,
    int? quantity,
    String? factory,
  }) =>
      RecentTransaction(
        id: id ?? this.id,
        stage: stage ?? this.stage,
        date: date ?? this.date,
        quantity: quantity ?? this.quantity,
        factory: factory ?? this.factory,
      );
}

/// An immutable snapshot ready for dashboard presentation.
class DashboardData {
  DashboardData({
    required this.totals,
    required List<POProgress> purchaseOrders,
    required List<DailyProduction> trend,
    required List<DashboardAlert> alerts,
    required List<RecentTransaction> recentEntries,
    required this.updatedAt,
    required this.fromCache,
  })  : purchaseOrders = List.unmodifiable(purchaseOrders),
        trend = List.unmodifiable(trend),
        alerts = List.unmodifiable(alerts),
        recentEntries = List.unmodifiable(recentEntries);

  final DashboardTotals totals;
  final List<POProgress> purchaseOrders;
  final List<DailyProduction> trend;
  final List<DashboardAlert> alerts;
  final List<RecentTransaction> recentEntries;
  final DateTime updatedAt;
  final bool fromCache;

  /// Whether any source rule violation or explicit error alert exists.
  bool get hasErrors =>
      alerts.any((alert) => alert.severity == AlertSeverity.error) ||
      purchaseOrders.any((po) => po.validationIssues.isNotEmpty) ||
      totals.stock < 0;

  /// Converts a dashboard snapshot to JSON-compatible values.
  Map<String, Object?> toJson() => {
        'totals': totals.toJson(),
        'purchaseOrders': purchaseOrders.map((po) => po.toJson()).toList(),
        'trend': trend.map((day) => day.toJson()).toList(),
        'alerts': alerts.map((alert) => alert.toJson()).toList(),
        'recentEntries': recentEntries.map((entry) => entry.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
        'fromCache': fromCache,
      };

  /// Restores a dashboard snapshot from persisted JSON.
  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        totals: DashboardTotals.fromJson(
          json['totals'] as Map<String, dynamic>,
        ),
        purchaseOrders: (json['purchaseOrders'] as List<dynamic>)
            .map((item) => POProgress.fromJson(item as Map<String, dynamic>))
            .toList(),
        trend: (json['trend'] as List<dynamic>)
            .map((item) =>
                DailyProduction.fromJson(item as Map<String, dynamic>))
            .toList(),
        alerts: (json['alerts'] as List<dynamic>)
            .map(
                (item) => DashboardAlert.fromJson(item as Map<String, dynamic>))
            .toList(),
        recentEntries: (json['recentEntries'] as List<dynamic>)
            .map((item) =>
                RecentTransaction.fromJson(item as Map<String, dynamic>))
            .toList(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        fromCache: json['fromCache'] as bool,
      );

  /// Returns a new dashboard snapshot with selected fields replaced.
  DashboardData copyWith({
    DashboardTotals? totals,
    List<POProgress>? purchaseOrders,
    List<DailyProduction>? trend,
    List<DashboardAlert>? alerts,
    List<RecentTransaction>? recentEntries,
    DateTime? updatedAt,
    bool? fromCache,
  }) {
    return DashboardData(
      totals: totals ?? this.totals,
      purchaseOrders: purchaseOrders ?? this.purchaseOrders,
      trend: trend ?? this.trend,
      alerts: alerts ?? this.alerts,
      recentEntries: recentEntries ?? this.recentEntries,
      updatedAt: updatedAt ?? this.updatedAt,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}
