import '../../shared/models/price_entry_model.dart';

class PriceIncrease {
  const PriceIncrease(this.previous, this.current);
  final PriceEntryModel previous;
  final PriceEntryModel current;
  double get amount => current.price - previous.price;
  double? get percent =>
      previous.price > 0 ? amount / previous.price * 100 : null;
}

List<PriceIncrease> findPriceIncreases(List<PriceEntryModel> entries) {
  final sorted =
      entries.where((e) => DateTime.tryParse(e.recordedAt) != null).toList()
        ..sort((a, b) {
          final order = DateTime.parse(
            a.recordedAt,
          ).compareTo(DateTime.parse(b.recordedAt));
          return order != 0 ? order : (a.id ?? 0).compareTo(b.id ?? 0);
        });
  final previous = <(int, int), PriceEntryModel>{};
  final increases = <PriceIncrease>[];
  for (final entry in sorted) {
    final key = (entry.commodityId, entry.storeId);
    final last = previous[key];
    if (last != null &&
        DateTime.parse(
          entry.recordedAt,
        ).isAfter(DateTime.parse(last.recordedAt)) &&
        entry.price > last.price) {
      increases.add(PriceIncrease(last, entry));
    }
    previous[key] = entry;
  }
  return increases.reversed.toList();
}
