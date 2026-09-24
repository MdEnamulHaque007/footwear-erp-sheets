import 'package:flutter_test/flutter_test.dart';
import 'package:footwear_erp_sheets/models/dashboard_card_config.dart';
import 'package:footwear_erp_sheets/models/po_progress.dart';
import 'package:footwear_erp_sheets/models/production_entry.dart';
import 'package:footwear_erp_sheets/models/sheet_data.dart';
import 'package:footwear_erp_sheets/models/stage_qty.dart';
import 'package:footwear_erp_sheets/models/stock_entry.dart';

void main() {
  const stage = StageQty(
    company: 'AFL',
    factory: 'AFL',
    poNo: 'PO-1',
    article: 'A',
    color: 'কালো',
    poQty: 100,
    cuttingQty: 80,
    sewingQty: 70,
    lastingQty: 60,
    fgIssueQty: 50,
    exportQty: 30,
    stockQty: 20,
  );

  test('stage validation and JSON preserve the exact production key', () {
    expect(stage.isValid, isTrue);
    expect(StageQty.fromJson(stage.toJson()).key, stage.key);
    expect(stage.copyWith(sewingQty: 90).validationIssues,
        contains('Sewing exceeds cutting.'));
    expect(stage.copyWith(stockQty: -1).isValid, isFalse);
    expect(stage.copyWith(cuttingQty: 110).isValid, isTrue);
    expect(stage.copyWith(cuttingQty: 110).excessCuttingQty, 10);
  });

  test('PO validates duplicates and protects its variant list', () {
    final source = [stage];
    final po = POProgress(
      poNo: 'PO-1',
      brand: 'Brand',
      tagNo: 'TAG-1',
      deliveryDate: DateTime.utc(2026, 10),
      variants: source,
    );
    source.add(stage);
    expect(po.variants.length, 1);
    expect(() => po.variants.add(stage), throwsUnsupportedError);
    expect(po.completionRatio, 0.3);
    expect(POProgress.fromJson(po.toJson()).orderedQty, 100);
    expect(
      po.copyWith(variants: [stage, stage]).validationIssues.any(
            (issue) => issue.contains('Duplicate variant'),
          ),
      isTrue,
    );
  });

  test('production entry observes cumulative prior-stage and stock limits', () {
    final sewing = ProductionEntry(
      id: '1',
      company: 'AFL',
      factory: 'AFL',
      poNo: 'PO-1',
      article: 'A',
      color: 'কালো',
      stage: ProductionStage.sewing,
      quantity: 11,
      date: DateTime.utc(2026, 9, 24),
    );
    expect(sewing.canApplyTo(stage), isFalse);
    expect(sewing.copyWith(quantity: 10).canApplyTo(stage), isTrue);
    expect(ProductionEntry.fromJson(sewing.toJson()).stage,
        ProductionStage.sewing);
    expect(
        sewing
            .copyWith(stage: ProductionStage.cutting, quantity: 30)
            .canApplyTo(stage),
        isTrue);
  });

  test('stock movement never results in a negative balance', () {
    final outbound = StockEntry(
      id: '1',
      company: 'AFL',
      factory: 'AFL',
      poNo: 'PO-1',
      article: 'A',
      color: 'কালো',
      type: StockMovementType.outbound,
      quantity: 21,
      date: DateTime.utc(2026, 9, 24),
    );
    expect(() => outbound.balanceAfter(20), throwsStateError);
    expect(outbound.copyWith(quantity: 20).balanceAfter(20), 0);
    expect(outbound.copyWith(quantity: -10).balanceAfter(20), 30);
    expect(StockEntry.fromJson(outbound.toJson()).type,
        StockMovementType.outbound);
  });

  test('CSV row keeps Bangla text and card configuration round-trips', () {
    final cells = {'Article': 'জুতা'};
    final sheet = SheetData(
      source: Uri.https('example.com', '/stock.csv'),
      headers: ['Article'],
      rows: [SheetRow(cells)],
      fetchedAt: DateTime.utc(2026, 9, 24),
      fromCache: true,
    );
    cells['Article'] = 'changed';
    expect(SheetData.fromJson(sheet.toJson()).rows.single.valueOf('Article'),
        'জুতা');
    expect(DashboardCardConfig.defaults.length, 13);
    expect(
        DashboardCardConfig.fromJson(
          DashboardCardConfig.defaults.first.toJson(),
        ).id,
        DashboardCardId.masterLc);
  });
}
