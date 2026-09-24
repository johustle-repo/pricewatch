import 'package:flutter_test/flutter_test.dart';
import 'package:pricewatch_apk/core/utils/price_increases.dart';
import 'package:pricewatch_apk/shared/models/price_entry_model.dart';
import 'package:pricewatch_apk/shared/widgets/report_date_filter.dart';

PriceEntryModel entry(
  int id,
  int store,
  double price,
  String date, {
  int commodity = 1,
}) => PriceEntryModel(
  id: id,
  commodityId: commodity,
  storeId: store,
  price: price,
  recordedAt: date,
  source: 'manual',
);

void main() {
  test('compares chronological records only within a commodity and store', () {
    final increases = findPriceIncreases([
      entry(4, 1, 120, '2026-09-24T10:00:00'),
      entry(2, 2, 50, '2026-09-23T10:00:00'),
      entry(1, 1, 100, '2026-09-22T10:00:00'),
      entry(3, 1, 500, '2026-09-23T10:00:00', commodity: 2),
      entry(5, 1, 110, '2026-09-25T10:00:00'),
      entry(6, 1, 110, '2026-09-26T10:00:00'),
    ]);
    expect(increases, hasLength(1));
    expect(increases.single.previous.id, 1);
    expect(increases.single.current.id, 4);
    expect(increases.single.amount, 20);
    expect(increases.single.percent, 20);
  });

  test(
    'ignores invalid dates and does not infer increases at identical times',
    () {
      expect(
        findPriceIncreases([
          entry(1, 1, 100, 'invalid'),
          entry(2, 1, 120, '2026-09-24T10:00:00'),
          entry(3, 1, 130, '2026-09-24T10:00:00'),
        ]),
        isEmpty,
      );
      expect(findPriceIncreases([]), isEmpty);
    },
  );

  test('report filter matches the whole local calendar day and clears', () {
    final day = DateTime(2026, 9, 24);
    expect(matchesReportDate('2026-09-24T00:00:00', day), isTrue);
    expect(matchesReportDate('2026-09-24T23:59:59', day), isTrue);
    expect(matchesReportDate('2026-09-25T00:00:00', day), isFalse);
    expect(matchesReportDate('invalid', day), isFalse);
    expect(matchesReportDate('invalid', null), isTrue);
    expect(matchesReportDate(day.toUtc().toIso8601String(), day), isTrue);
  });
}
