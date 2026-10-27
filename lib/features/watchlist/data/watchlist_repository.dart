import '../../../core/database/cloud_data_service.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/market_prices.dart';
import '../../../shared/models/commodity_model.dart';
import '../../../shared/models/price_entry_model.dart';
import '../../../shared/models/store_model.dart';
import '../../../shared/models/watchlist_model.dart';
import '../../../shared/models/ui_models.dart';

class WatchlistRepository {
  WatchlistRepository({required CloudDataService cloudDataService})
    : _cloudDataService = cloudDataService;

  final CloudDataService _cloudDataService;

  Future<List<WatchlistViewData>> getWatchlist(int userId) async {
    final watchlists = await _watchlistsFor(userId);
    final commodities = (await _cloudDataService.getCollection(
      'commodities',
    )).map(CommodityModel.fromMap).toList();
    final entriesByCommodity = await _activeEntriesFor(watchlists);

    await _syncAlerts(userId, watchlists, commodities, entriesByCommodity);

    final data =
        watchlists
            .map((watch) {
              final watchId = watch.id;
              final commodity = commodities
                  .where((item) => item.id == watch.commodityId)
                  .firstOrNull;
              if (watchId == null || commodity == null) {
                return null;
              }
              final entries = entriesByCommodity[watch.commodityId] ?? [];
              final market = currentMarketPrice(entries);
              return WatchlistViewData(
                watchlistId: watchId,
                commodityId: watch.commodityId,
                commodityName: commodity.name,
                unit: commodity.unit,
                srp: commodity.srp,
                threshold: watch.priceThreshold,
                currentPrice: market.average ?? 0,
                previousPrice: market.previousAverage ?? 0,
                updatedAt: market.latestRecordedAt ?? '',
                history: _historyForCommodity(entries, watch.commodityId),
              );
            })
            .nonNulls
            .toList()
          ..sort((a, b) => a.commodityName.compareTo(b.commodityName));

    return data;
  }

  /// Creates notifications for prices recorded on the user's watched items
  /// since the last check, from any source (admin, vendor, CSV or survey).
  /// Runs on the user's own device, so no server function is needed.
  Future<void> syncWatchAlerts(int userId) async {
    final watchlists = await _watchlistsFor(userId);
    if (watchlists.isEmpty) return;
    final commodities = (await _cloudDataService.getCollection(
      'commodities',
    )).map(CommodityModel.fromMap).toList();
    await _syncAlerts(
      userId,
      watchlists,
      commodities,
      await _activeEntriesFor(watchlists),
    );
  }

  Future<List<WatchlistModel>> _watchlistsFor(int userId) async {
    return (await _cloudDataService.getCollectionWhere(
          'watchlists',
          field: 'user_id',
          value: userId,
        ))
        .map(WatchlistModel.fromMap)
        .where((item) => item.userId == userId)
        .toList();
  }

  /// Price entries of the watched commodities from active stores only.
  Future<Map<int, List<PriceEntryModel>>> _activeEntriesFor(
    List<WatchlistModel> watchlists,
  ) async {
    final commodityIds = watchlists
        .map((item) => item.commodityId)
        .toSet()
        .toList();
    final activeStoreIds = (await _cloudDataService.getCollection('stores'))
        .map(StoreModel.fromMap)
        .where((item) => !item.isArchived)
        .map((item) => item.id)
        .nonNulls
        .toSet();
    final rows = await _cloudDataService.getCollectionWhereIn(
      'price_entries',
      field: 'commodity_id',
      values: commodityIds,
    );
    final byCommodity = <int, List<PriceEntryModel>>{};
    for (final entry in rows.map(PriceEntryModel.fromMap)) {
      if (!commodityIds.contains(entry.commodityId) ||
          !activeStoreIds.contains(entry.storeId)) {
        continue;
      }
      byCommodity.putIfAbsent(entry.commodityId, () => []).add(entry);
    }
    return byCommodity;
  }

  List<PriceHistoryPoint> _historyForCommodity(
    List<PriceEntryModel> entries,
    int commodityId,
  ) {
    final daily = <DateTime, List<double>>{};
    for (final entry in entries.where(
      (item) => item.commodityId == commodityId,
    )) {
      final parsed = DateTime.tryParse(entry.recordedAt)?.toLocal();
      if (parsed == null) continue;
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      daily.putIfAbsent(day, () => []).add(entry.price);
    }
    final points =
        daily.entries
            .map(
              (entry) => PriceHistoryPoint(
                date: entry.key,
                value: entry.value.reduce((a, b) => a + b) / entry.value.length,
              ),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return points.length <= 30 ? points : points.sublist(points.length - 30);
  }

  Future<WatchlistModel?> getWatchEntry({
    required int userId,
    required int commodityId,
  }) async {
    final watchlists =
        (await _cloudDataService.getCollectionWhere(
              'watchlists',
              field: 'user_id',
              value: userId,
            ))
            .map(WatchlistModel.fromMap)
            .where(
              (item) =>
                  item.userId == userId && item.commodityId == commodityId,
            )
            .toList();
    return watchlists.isEmpty ? null : watchlists.first;
  }

  Future<void> toggleWatchlist({
    required int userId,
    required int commodityId,
    double? threshold,
  }) async {
    final existing = await getWatchEntry(
      userId: userId,
      commodityId: commodityId,
    );
    if (existing == null) {
      final id = _cloudDataService.generateId();
      await _cloudDataService.setDocument('watchlists', id, {
        'id': id,
        'user_id': userId,
        'commodity_id': commodityId,
        'price_threshold': threshold,
        'created_at': DateTimeUtils.nowIso(),
      });
    } else {
      final existingId = existing.id;
      if (existingId != null) {
        await _cloudDataService.deleteDocument('watchlists', existingId);
      }
    }
  }

  Future<void> updateThreshold({
    required int watchlistId,
    double? threshold,
  }) async {
    final existing = await _cloudDataService.getDocument(
      'watchlists',
      watchlistId,
    );
    if (existing == null) {
      return;
    }
    await _cloudDataService.setDocument('watchlists', watchlistId, {
      ...existing,
      'price_threshold': threshold,
    });
  }

  Future<void> removeWatchlist(int watchlistId) async {
    await _cloudDataService.deleteDocument('watchlists', watchlistId);
  }

  Future<void> _syncAlerts(
    int userId,
    List<WatchlistModel> watchlists,
    List<CommodityModel> commodities,
    Map<int, List<PriceEntryModel>> entriesByCommodity,
  ) async {
    for (final watch in watchlists) {
      final watchId = watch.id;
      final commodity = commodities
          .where((item) => item.id == watch.commodityId)
          .firstOrNull;
      if (watchId == null || commodity == null) continue;

      final entries = entriesByCommodity[watch.commodityId] ?? const [];
      final checkedUntil = watch.lastAlertedAt ?? watch.createdAt;
      final newEntries = entries
          .where((entry) => entry.recordedAt.compareTo(checkedUntil) > 0)
          .toList();
      if (newEntries.isEmpty) continue;

      final market = currentMarketPrice(entries);
      final average = market.average;
      final count = newEntries.length;
      await _notify(
        userId,
        title: 'Watched item updated',
        body: average == null
            ? '${commodity.name}: $count new price${count == 1 ? '' : 's'} recorded.'
            : '${commodity.name}: $count new price${count == 1 ? '' : 's'} recorded. '
                  'Market average is now ${AppFormatters.currency(average)} '
                  'across ${market.storeCount} store${market.storeCount == 1 ? '' : 's'}.',
        type: 'watched_item_updated',
      );

      final threshold = watch.priceThreshold;
      if (threshold != null && average != null && average > threshold) {
        await _notify(
          userId,
          title: 'Price threshold reached',
          body:
              '${commodity.name} is at ${AppFormatters.currency(average)}, above your alert threshold of ${AppFormatters.currency(threshold)}.',
          type: 'price_increase',
        );
      }

      final newest = newEntries
          .map((entry) => entry.recordedAt)
          .reduce((a, b) => a.compareTo(b) > 0 ? a : b);
      final existing = await _cloudDataService.getDocument(
        'watchlists',
        watchId,
      );
      if (existing != null) {
        await _cloudDataService.setDocument('watchlists', watchId, {
          ...existing,
          'last_alerted_at': newest,
        });
      }
    }
  }

  Future<void> _notify(
    int userId, {
    required String title,
    required String body,
    required String type,
  }) async {
    final id = _cloudDataService.generateId();
    await _cloudDataService.setDocument('notifications', id, {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': 0,
      'created_at': DateTimeUtils.nowIso(),
    });
  }
}
