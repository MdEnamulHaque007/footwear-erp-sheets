// lib/models/production_entry.dart
import 'stage_qty.dart';

/// Stage receiving a single quantity entry.
enum ProductionStage { cutting, sewing, lasting, fgIssue, export }

/// A dated production movement for one company/factory/PO/article/color key.
class ProductionEntry {
  const ProductionEntry({
    required this.id,
    required this.company,
    required this.factory,
    required this.poNo,
    required this.article,
    required this.color,
    required this.stage,
    required this.quantity,
    required this.date,
  });

  final String id;
  final String company;
  final String factory;
  final String poNo;
  final String article;
  final String color;
  final ProductionStage stage;
  final int quantity;
  final DateTime date;

  /// Unique cumulative grouping key for this entry.
  ProductionKey get key => (company, factory, poNo, article, color);

  /// Checks an entry against the preceding cumulative production stage.
  List<String> validationIssues(StageQty current) {
    final issues = <String>[];
    if (quantity == 0) issues.add('Entry quantity cannot be zero.');
    if (key != current.key) issues.add('Production key does not match.');
    final (alreadyDone, previousStage) = switch (stage) {
      ProductionStage.cutting => (current.cuttingQty, current.poQty),
      ProductionStage.sewing => (current.sewingQty, current.cuttingQty),
      ProductionStage.lasting => (current.lastingQty, current.sewingQty),
      ProductionStage.fgIssue => (current.fgIssueQty, current.lastingQty),
      ProductionStage.export => (current.exportQty, current.fgIssueQty),
    };
    final followingStage = switch (stage) {
      ProductionStage.cutting => current.sewingQty,
      ProductionStage.sewing => current.lastingQty,
      ProductionStage.lasting => current.fgIssueQty,
      ProductionStage.fgIssue => current.exportQty,
      ProductionStage.export => 0,
    };
    if (alreadyDone + quantity < 0) {
      issues.add('${stage.name} cumulative quantity cannot be negative.');
    }
    if (alreadyDone + quantity < followingStage) {
      issues.add('${stage.name} would fall below the following stage.');
    }
    // Cutting excess is allowed and reported separately in StageQty.
    if (stage != ProductionStage.cutting &&
        quantity > 0 &&
        alreadyDone + quantity > previousStage) {
      issues.add('${stage.name} exceeds the preceding stage.');
    }
    if (stage == ProductionStage.export && current.stockQty - quantity < 0) {
      issues.add('Export would make stock negative.');
    }
    return List.unmodifiable(issues);
  }

  /// Whether this movement can be added to the current cumulative snapshot.
  bool canApplyTo(StageQty current) => validationIssues(current).isEmpty;

  /// Returns an entry with selected fields replaced.
  ProductionEntry copyWith({
    String? id,
    String? company,
    String? factory,
    String? poNo,
    String? article,
    String? color,
    ProductionStage? stage,
    int? quantity,
    DateTime? date,
  }) =>
      ProductionEntry(
        id: id ?? this.id,
        company: company ?? this.company,
        factory: factory ?? this.factory,
        poNo: poNo ?? this.poNo,
        article: article ?? this.article,
        color: color ?? this.color,
        stage: stage ?? this.stage,
        quantity: quantity ?? this.quantity,
        date: date ?? this.date,
      );

  /// Converts a production movement to JSON-compatible values.
  Map<String, Object?> toJson() => {
        'id': id,
        'company': company,
        'factory': factory,
        'poNo': poNo,
        'article': article,
        'color': color,
        'stage': stage.name,
        'quantity': quantity,
        'date': date.toIso8601String(),
      };

  /// Restores a production movement from persisted JSON.
  factory ProductionEntry.fromJson(Map<String, dynamic> json) =>
      ProductionEntry(
        id: json['id'] as String,
        company: json['company'] as String,
        factory: json['factory'] as String,
        poNo: json['poNo'] as String,
        article: json['article'] as String,
        color: json['color'] as String,
        stage: ProductionStage.values.byName(json['stage'] as String),
        quantity: (json['quantity'] as num).toInt(),
        date: DateTime.parse(json['date'] as String),
      );
}
