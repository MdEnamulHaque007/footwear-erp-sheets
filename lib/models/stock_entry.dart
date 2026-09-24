// lib/models/stock_entry.dart
import 'stage_qty.dart';

/// Direction of a finished-goods stock ledger movement.
enum StockMovementType { inbound, outbound }

/// One dated stock movement for one production key.
class StockEntry {
  const StockEntry({
    required this.id,
    required this.company,
    required this.factory,
    required this.poNo,
    required this.article,
    required this.color,
    required this.type,
    required this.quantity,
    required this.date,
  });

  final String id;
  final String company;
  final String factory;
  final String poNo;
  final String article;
  final String color;
  final StockMovementType type;
  final int quantity;
  final DateTime date;

  /// Unique stock-ledger grouping key.
  ProductionKey get key => (company, factory, poNo, article, color);

  /// Signed change in stock; negative quantities can reverse prior entries.
  int get signedChange =>
      type == StockMovementType.inbound ? quantity : -quantity;

  /// Returns issues that would prevent applying this ledger movement.
  List<String> validationIssues(int currentBalance) {
    final issues = <String>[];
    if (quantity == 0) issues.add('Movement quantity cannot be zero.');
    if (currentBalance < 0) issues.add('Current stock cannot be negative.');
    if (currentBalance + signedChange < 0) {
      issues.add('Movement would make stock negative.');
    }
    return List.unmodifiable(issues);
  }

  /// Applies this movement, rejecting invalid or negative resulting stock.
  int balanceAfter(int currentBalance) {
    final issues = validationIssues(currentBalance);
    if (issues.isNotEmpty) throw StateError(issues.join(' '));
    return currentBalance + signedChange;
  }

  /// Returns a movement with selected fields replaced.
  StockEntry copyWith({
    String? id,
    String? company,
    String? factory,
    String? poNo,
    String? article,
    String? color,
    StockMovementType? type,
    int? quantity,
    DateTime? date,
  }) =>
      StockEntry(
        id: id ?? this.id,
        company: company ?? this.company,
        factory: factory ?? this.factory,
        poNo: poNo ?? this.poNo,
        article: article ?? this.article,
        color: color ?? this.color,
        type: type ?? this.type,
        quantity: quantity ?? this.quantity,
        date: date ?? this.date,
      );

  /// Converts a ledger movement to JSON-compatible values.
  Map<String, Object?> toJson() => {
        'id': id,
        'company': company,
        'factory': factory,
        'poNo': poNo,
        'article': article,
        'color': color,
        'type': type.name,
        'quantity': quantity,
        'date': date.toIso8601String(),
      };

  /// Restores a ledger movement from persisted JSON.
  factory StockEntry.fromJson(Map<String, dynamic> json) => StockEntry(
        id: json['id'] as String,
        company: json['company'] as String,
        factory: json['factory'] as String,
        poNo: json['poNo'] as String,
        article: json['article'] as String,
        color: json['color'] as String,
        type: StockMovementType.values.byName(json['type'] as String),
        quantity: (json['quantity'] as num).toInt(),
        date: DateTime.parse(json['date'] as String),
      );
}
