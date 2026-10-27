import 'package:flutter_test/flutter_test.dart';
import 'package:pricewatch_apk/core/utils/market_prices.dart';
import 'package:pricewatch_apk/shared/models/price_entry_model.dart';

PriceEntryModel _entry(int id, int storeId, double price, String date) {
  return PriceEntryModel(
    id: id,
    commodityId: 1,
    storeId: storeId,
    price: price,
    recordedAt: '${date}T00:00:00.000Z',
    source: 'test',
  );
}

void main() {
  test('stores recorded on the same day are not treated as a price change', () {
    final market = currentMarketPrice([
      _entry(1, 1, 230, '2026-10-05'),
      _entry(2, 2, 240, '2026-10-05'),
      _entry(3, 3, 230, '2026-10-05'),
    ]);

    expect(market.storeCount, 3);
    expect(market.average, closeTo(233.33, 0.01));
    expect(market.previousAverage, market.average);
    expect(market.lowest, 230);
    expect(market.highest, 240);
  });

  test('each store is compared with its own previous price', () {
    final market = currentMarketPrice([
      _entry(1, 1, 200, '2026-09-01'),
      _entry(2, 1, 220, '2026-10-05'),
      _entry(3, 2, 300, '2026-10-05'),
    ]);

    expect(market.average, 260);
    // Store 1 moved 200 -> 220; store 2 has no history, so it adds no change.
    expect(market.previousAverage, 250);
  });

  test('stores whose latest price is outside the window are left out', () {
    final market = currentMarketPrice([
      _entry(1, 1, 100, '2026-08-01'),
      _entry(2, 2, 140, '2026-10-05'),
    ]);

    expect(market.storeCount, 1);
    expect(market.average, 140);
    expect(market.latestRecordedAt, '2026-10-05T00:00:00.000Z');
  });

  test('archived or unknown stores are ignored when active stores are given', () {
    final market = currentMarketPrice([
      _entry(1, 1, 100, '2026-10-05'),
      _entry(2, 9, 500, '2026-10-05'),
    ], activeStoreIds: {1});

    expect(market.average, 100);
  });

  test('no entries means no price rather than a fallback', () {
    final market = currentMarketPrice(const []);

    expect(market.hasPrice, isFalse);
    expect(market.average, isNull);
    expect(market.latestRecordedAt, isNull);
  });

  test('stale prices are flagged after the stale age', () {
    final now = DateTime.utc(2026, 10, 30);
    expect(isStalePrice('2026-10-05T00:00:00.000Z', now: now), isTrue);
    expect(isStalePrice('2026-10-25T00:00:00.000Z', now: now), isFalse);
  });
}
