// lib/models/stage_qty.dart
/// A unique company, factory, PO, article and color combination.
typedef ProductionKey = (String, String, String, String, String);

/// Cumulative pair quantities for one production key.
///
/// Imported values remain intact, including invalid or negative values, so
/// the dashboard can report source errors rather than silently hide them.
class StageQty {
  const StageQty({
    required this.company,
    required this.factory,
    required this.poNo,
    required this.article,
    required this.color,
    required this.poQty,
    required this.cuttingQty,
    required this.sewingQty,
    required this.lastingQty,
    required this.fgIssueQty,
    required this.exportQty,
    required this.stockQty,
  });

  final String company;
  final String factory;
  final String poNo;
  final String article;
  final String color;
  final int poQty;
  final int cuttingQty;
  final int sewingQty;
  final int lastingQty;
  final int fgIssueQty;
  final int exportQty;
  final int stockQty;

  /// The exact grouping key used across all cumulative production stages.
  ProductionKey get key => (company, factory, poNo, article, color);

  /// Cutting above ordered pairs, displayed as an orange warning.
  int get excessCuttingQty => cuttingQty > poQty ? cuttingQty - poQty : 0;

  /// FG issued minus exported pairs, before any opening stock adjustment.
  int get expectedStockQty => fgIssueQty - exportQty;

  /// Blocking rule violations for this exact production key.
  List<String> get validationIssues {
    final issues = <String>[];
    if ([
      poQty,
      cuttingQty,
      sewingQty,
      lastingQty,
      fgIssueQty,
      exportQty,
      stockQty,
    ].any((quantity) => quantity < 0)) {
      issues.add('Quantities cannot be negative.');
    }
    if (sewingQty > cuttingQty) issues.add('Sewing exceeds cutting.');
    if (lastingQty > sewingQty) issues.add('Lasting exceeds sewing.');
    if (fgIssueQty > lastingQty) issues.add('FG issue exceeds lasting.');
    if (exportQty > fgIssueQty) issues.add('Export exceeds FG issue.');
    if (stockQty != expectedStockQty) {
      issues.add('Stock does not equal FG issue minus export.');
    }
    return List.unmodifiable(issues);
  }

  /// Whether all cumulative stage rules and the stock floor hold.
  bool get isValid => validationIssues.isEmpty;

  /// Converts this immutable snapshot to JSON-compatible values.
  Map<String, Object?> toJson() => {
        'company': company,
        'factory': factory,
        'poNo': poNo,
        'article': article,
        'color': color,
        'poQty': poQty,
        'cuttingQty': cuttingQty,
        'sewingQty': sewingQty,
        'lastingQty': lastingQty,
        'fgIssueQty': fgIssueQty,
        'exportQty': exportQty,
        'stockQty': stockQty,
      };

  /// Restores a cumulative quantity snapshot from persisted JSON.
  factory StageQty.fromJson(Map<String, dynamic> json) => StageQty(
        company: json['company'] as String,
        factory: json['factory'] as String,
        poNo: json['poNo'] as String,
        article: json['article'] as String,
        color: json['color'] as String,
        poQty: (json['poQty'] as num).toInt(),
        cuttingQty: (json['cuttingQty'] as num).toInt(),
        sewingQty: (json['sewingQty'] as num).toInt(),
        lastingQty: (json['lastingQty'] as num).toInt(),
        fgIssueQty: (json['fgIssueQty'] as num).toInt(),
        exportQty: (json['exportQty'] as num).toInt(),
        stockQty: (json['stockQty'] as num).toInt(),
      );

  /// Returns a new quantity snapshot with the supplied fields replaced.
  StageQty copyWith({
    String? company,
    String? factory,
    String? poNo,
    String? article,
    String? color,
    int? poQty,
    int? cuttingQty,
    int? sewingQty,
    int? lastingQty,
    int? fgIssueQty,
    int? exportQty,
    int? stockQty,
  }) {
    return StageQty(
      company: company ?? this.company,
      factory: factory ?? this.factory,
      poNo: poNo ?? this.poNo,
      article: article ?? this.article,
      color: color ?? this.color,
      poQty: poQty ?? this.poQty,
      cuttingQty: cuttingQty ?? this.cuttingQty,
      sewingQty: sewingQty ?? this.sewingQty,
      lastingQty: lastingQty ?? this.lastingQty,
      fgIssueQty: fgIssueQty ?? this.fgIssueQty,
      exportQty: exportQty ?? this.exportQty,
      stockQty: stockQty ?? this.stockQty,
    );
  }
}
