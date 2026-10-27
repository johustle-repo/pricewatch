import 'package:flutter_test/flutter_test.dart';
import 'package:pricewatch_apk/shared/models/ui_models.dart';

CommodityOverview _commodity(int id, double price, {String updatedAt = ''}) {
  return CommodityOverview(
    id: id,
    categoryId: 4,
    categoryName: 'Fish',
    subcategoryId: 1,
    subcategoryName: 'Bangus',
    name: 'Bangus $id',
    unit: 'kg',
    srp: 240,
    latestAveragePrice: price,
    latestUpdatedAt: updatedAt,
    isWatched: false,
  );
}

void main() {
  test('summarizes recorded prices and ignores SRP-only fallbacks', () {
    final summary = SubcategoryPriceSummary.fromCommodities(
      subcategoryId: 1,
      name: 'Bangus',
      commodities: [
        _commodity(1, 230, updatedAt: '2026-10-05T00:00:00Z'),
        _commodity(2, 214, updatedAt: '2026-10-05T00:00:00Z'),
        _commodity(3, 240),
      ],
    );

    expect(summary.commodityCount, 3);
    expect(summary.pricedCount, 2);
    expect(summary.lowestPrice, 214);
    expect(summary.highestPrice, 230);
    expect(summary.averagePrice, 222);
  });

  test('reports no prices when nothing is recorded', () {
    final summary = SubcategoryPriceSummary.fromCommodities(
      subcategoryId: 1,
      name: 'Bangus',
      commodities: [_commodity(1, 240)],
    );

    expect(summary.pricedCount, 0);
    expect(summary.lowestPrice, isNull);
    expect(summary.averagePrice, isNull);
  });
}
