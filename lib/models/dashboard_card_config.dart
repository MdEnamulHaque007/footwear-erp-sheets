// lib/models/dashboard_card_config.dart
/// Stable IDs used to persist the layout of all dashboard cards.
enum DashboardCardId {
  masterLc,
  po,
  cutting,
  sewing,
  lasting,
  fgIssue,
  export,
  stock,
  stageProgress,
  trend,
  alerts,
  poSummary,
  recentEntries,
}

/// One card's visibility and drag-and-drop position.
class DashboardCardConfig {
  const DashboardCardConfig({
    required this.id,
    required this.order,
    this.visible = true,
  });

  final DashboardCardId id;
  final int order;
  final bool visible;

  /// Default layout with eight KPIs and five detailed cards.
  static const List<DashboardCardConfig> defaults = [
    DashboardCardConfig(id: DashboardCardId.masterLc, order: 0),
    DashboardCardConfig(id: DashboardCardId.po, order: 1),
    DashboardCardConfig(id: DashboardCardId.cutting, order: 2),
    DashboardCardConfig(id: DashboardCardId.sewing, order: 3),
    DashboardCardConfig(id: DashboardCardId.lasting, order: 4),
    DashboardCardConfig(id: DashboardCardId.fgIssue, order: 5),
    DashboardCardConfig(id: DashboardCardId.export, order: 6),
    DashboardCardConfig(id: DashboardCardId.stock, order: 7),
    DashboardCardConfig(id: DashboardCardId.stageProgress, order: 8),
    DashboardCardConfig(id: DashboardCardId.trend, order: 9),
    DashboardCardConfig(id: DashboardCardId.alerts, order: 10),
    DashboardCardConfig(id: DashboardCardId.poSummary, order: 11),
    DashboardCardConfig(id: DashboardCardId.recentEntries, order: 12),
  ];

  /// Returns a new card configuration with selected fields replaced.
  DashboardCardConfig copyWith({
    DashboardCardId? id,
    int? order,
    bool? visible,
  }) =>
      DashboardCardConfig(
        id: id ?? this.id,
        order: order ?? this.order,
        visible: visible ?? this.visible,
      );

  /// Converts the card preference to JSON-compatible values.
  Map<String, Object?> toJson() => {
        'id': id.name,
        'order': order,
        'visible': visible,
      };

  /// Restores one card preference from persisted JSON.
  factory DashboardCardConfig.fromJson(Map<String, dynamic> json) =>
      DashboardCardConfig(
        id: DashboardCardId.values.byName(json['id'] as String),
        order: (json['order'] as num).toInt(),
        visible: json['visible'] as bool,
      );
}
