// lib/models/po_progress.dart
import 'stage_qty.dart';

/// One purchase order and its company/factory/article/color variants.
class POProgress {
  POProgress({
    required this.poNo,
    required this.brand,
    required this.tagNo,
    required this.deliveryDate,
    required List<StageQty> variants,
  }) : variants = List.unmodifiable(variants);

  final String poNo;
  final String brand;
  final String tagNo;
  final DateTime deliveryDate;
  final List<StageQty> variants;

  /// Total ordered pairs across the variants in this PO.
  int get orderedQty => variants.fold(0, (sum, item) => sum + item.poQty);

  /// Total exported pairs across the variants in this PO.
  int get exportedQty => variants.fold(0, (sum, item) => sum + item.exportQty);

  /// Remaining pairs; a negative number exposes over-export in source data.
  int get remainingQty => orderedQty - exportedQty;

  /// Export-to-order ratio, or zero for an empty order.
  double get completionRatio => orderedQty == 0 ? 0 : exportedQty / orderedQty;

  /// Days from the supplied date to the PO delivery date.
  int daysUntilDelivery(DateTime asOf) {
    final due = DateTime.utc(
      deliveryDate.year,
      deliveryDate.month,
      deliveryDate.day,
    );
    final today = DateTime.utc(asOf.year, asOf.month, asOf.day);
    return due.difference(today).inDays;
  }

  /// Validation issues, including duplicate variants and mismatched PO keys.
  List<String> get validationIssues {
    final issues = <String>[];
    final seen = <ProductionKey>{};
    for (final variant in variants) {
      if (variant.poNo != poNo) {
        issues.add('Variant ${variant.key} belongs to another PO.');
      }
      if (!seen.add(variant.key)) {
        issues.add('Duplicate variant ${variant.key}.');
      }
      for (final issue in variant.validationIssues) {
        issues.add('${variant.key}: $issue');
      }
    }
    return List.unmodifiable(issues);
  }

  /// Serializes this PO and its size variants for offline storage.
  Map<String, Object?> toJson() => {
        'poNo': poNo,
        'brand': brand,
        'tagNo': tagNo,
        'deliveryDate': deliveryDate.toIso8601String(),
        'variants': variants.map((variant) => variant.toJson()).toList(),
      };

  /// Restores a PO and its size variants from persisted JSON.
  factory POProgress.fromJson(Map<String, dynamic> json) => POProgress(
        poNo: json['poNo'] as String,
        brand: json['brand'] as String,
        tagNo: json['tagNo'] as String,
        deliveryDate: DateTime.parse(json['deliveryDate'] as String),
        variants: (json['variants'] as List<dynamic>)
            .map((item) => StageQty.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  /// Returns a new PO snapshot with the supplied fields replaced.
  POProgress copyWith({
    String? poNo,
    String? brand,
    String? tagNo,
    DateTime? deliveryDate,
    List<StageQty>? variants,
  }) {
    return POProgress(
      poNo: poNo ?? this.poNo,
      brand: brand ?? this.brand,
      tagNo: tagNo ?? this.tagNo,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      variants: variants ?? this.variants,
    );
  }
}
