import '../../shared/models/price_entry_model.dart';

/// A store's latest price counts toward a commodity's current price only when
/// it was recorded within this window of the commodity's newest record.
const Duration currentPriceWindow = Duration(days: 30);

/// A commodity whose newest price is older than this is flagged as stale.
const Duration stalePriceAge = Duration(days: 14);

/// The current market picture for one commodity: each contributing store's
/// latest price and that same store's previous price.
class CurrentMarketPrice {
  const CurrentMarketPrice({required this.latest, required this.previous});

  /// Latest entry per contributing store, cheapest first.
  final List<PriceEntryModel> latest;

  /// The previous entry of the same store, keyed by store id. Stores with a
  /// single record have no entry here.
  final Map<int, PriceEntryModel> previous;

  bool get hasPrice => latest.isNotEmpty;
  int get storeCount => latest.length;

  double? get average => latest.isEmpty
      ? null
      : latest.map((entry) => entry.price).reduce((a, b) => a + b) /
            latest.length;

  double? get lowest => latest.isEmpty ? null : latest.first.price;
  double? get highest => latest.isEmpty ? null : latest.last.price;

  /// Average of the same stores' previous prices, so a change reflects price
  /// movement within each store rather than differences between stores.
  /// Stores without an earlier record contribute their latest price.
  double? get previousAverage => latest.isEmpty
      ? null
      : latest
                .map((entry) => (previous[entry.storeId] ?? entry).price)
                .reduce((a, b) => a + b) /
            latest.length;

  String? get latestRecordedAt => latest.isEmpty
      ? null
      : latest
            .map((entry) => entry.recordedAt)
            .reduce((a, b) => a.compareTo(b) > 0 ? a : b);
}

/// Builds the current price of one commodity from its price [entries].
/// When [activeStoreIds] is given, entries from other stores are ignored.
CurrentMarketPrice currentMarketPrice(
  Iterable<PriceEntryModel> entries, {
  Set<int>? activeStoreIds,
}) {
  final sorted =
      entries
          .where(
            (entry) =>
                activeStoreIds == null ||
                activeStoreIds.contains(entry.storeId),
          )
          .where((entry) => DateTime.tryParse(entry.recordedAt) != null)
          .toList()
        ..sort((a, b) {
          final order = b.recordedAt.compareTo(a.recordedAt);
          return order != 0 ? order : (b.id ?? 0).compareTo(a.id ?? 0);
        });
  if (sorted.isEmpty) {
    return const CurrentMarketPrice(latest: [], previous: {});
  }

  final cutoff = DateTime.parse(
    sorted.first.recordedAt,
  ).subtract(currentPriceWindow);
  final latest = <int, PriceEntryModel>{};
  final previous = <int, PriceEntryModel>{};
  for (final entry in sorted) {
    final current = latest[entry.storeId];
    if (current == null) {
      if (!DateTime.parse(entry.recordedAt).isBefore(cutoff)) {
        latest[entry.storeId] = entry;
      }
    } else if (!previous.containsKey(entry.storeId) &&
        entry.recordedAt.compareTo(current.recordedAt) < 0) {
      previous[entry.storeId] = entry;
    }
  }
  return CurrentMarketPrice(
    latest: latest.values.toList()..sort((a, b) => a.price.compareTo(b.price)),
    previous: previous,
  );
}

/// Whether a price recorded at [recordedAt] is old enough to flag as stale.
bool isStalePrice(String recordedAt, {DateTime? now}) {
  final recorded = DateTime.tryParse(recordedAt);
  if (recorded == null) return false;
  return (now ?? DateTime.now()).difference(recorded) > stalePriceAge;
}
