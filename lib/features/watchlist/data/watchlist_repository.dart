import '../../../core/database/cloud_data_service.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/models/app_notification_model.dart';
import '../../../shared/models/commodity_model.dart';
import '../../../shared/models/price_entry_model.dart';
import '../../../shared/models/watchlist_model.dart';
import '../../../shared/models/ui_models.dart';

class WatchlistRepository {
  WatchlistRepository({required CloudDataService cloudDataService})
    : _cloudDataService = cloudDataService;

  final CloudDataService _cloudDataService;

  Future<List<WatchlistViewData>> getWatchlist(int userId) async {
    final watchlists =
        (await _cloudDataService.getCollectionWhere(
              'watchlists',
              field: 'user_id',
              value: userId,
            ))
            .map(WatchlistModel.fromMap)
            .where((item) => item.userId == userId)
            .toList();
    final commodities = (await _cloudDataService.getCollection(
      'commodities',
    )).map(CommodityModel.fromMap).toList();
    final priceEntries = (await _cloudDataService.getCollection(
      'price_entries',
    )).map(PriceEntryModel.fromMap).toList();

    await _syncThresholdAlerts(userId, watchlists, commodities, priceEntries);

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
              final current = _averageAtPosition(
                priceEntries,
                watch.commodityId,
                0,
              );
              final previous = _averageAtPosition(
                priceEntries,
                watch.commodityId,
                1,
              );
              final history = _historyForCommodity(
                priceEntries,
                watch.commodityId,
              );
              return WatchlistViewData(
                watchlistId: watchId,
                commodityId: watch.commodityId,
                commodityName: commodity.name,
                unit: commodity.unit,
                srp: commodity.srp,
                threshold: watch.priceThreshold,
                currentPrice: current.$1,
                previousPrice: previous.$1,
                updatedAt: current.$2,
                history: history,
              );
            })
            .nonNulls
            .toList()
          ..sort((a, b) => a.commodityName.compareTo(b.commodityName));

    return data;
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

  (double, String) _averageAtPosition(
    List<PriceEntryModel> entries,
    int commodityId,
    int offset,
  ) {
    final commodityEntries =
        entries.where((item) => item.commodityId == commodityId).toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final timestamps =
        commodityEntries.map((item) => item.recordedAt).toSet().toList()
          ..sort((a, b) => b.compareTo(a));
    if (offset >= timestamps.length) {
      return (0.0, '');
    }
    final timestamp = timestamps[offset];
    final atTimestamp = commodityEntries
        .where((item) => item.recordedAt == timestamp)
        .toList();
    final average =
        atTimestamp.map((item) => item.price).reduce((a, b) => a + b) /
        atTimestamp.length;
    return (average, timestamp);
  }

  Future<void> _syncThresholdAlerts(
    int userId,
    List<WatchlistModel> watchlists,
    List<CommodityModel> commodities,
    List<PriceEntryModel> priceEntries,
  ) async {
    final notifications =
        (await _cloudDataService.getCollectionWhere(
              'notifications',
              field: 'user_id',
              value: userId,
            ))
            .map(AppNotificationModel.fromMap)
            .where((item) => item.userId == userId)
            .toList();

    for (final watch in watchlists.where(
      (item) => item.priceThreshold != null,
    )) {
      final current = _averageAtPosition(priceEntries, watch.commodityId, 0);
      final threshold = watch.priceThreshold;
      if (threshold == null || current.$1 <= threshold) {
        continue;
      }

      final commodity = commodities
          .where((item) => item.id == watch.commodityId)
          .firstOrNull;
      if (commodity == null) {
        continue;
      }
      final title = 'Price threshold reached';
      final body =
          '${commodity.name} is at ${AppFormatters.currency(current.$1)}, above your alert threshold of ${AppFormatters.currency(threshold)}.';
      final exists = notifications.any(
        (item) =>
            item.title == title &&
            item.body == body &&
            item.type == 'price_increase',
      );
      if (exists) {
        continue;
      }

      final id = _cloudDataService.generateId();
      await _cloudDataService.setDocument('notifications', id, {
        'id': id,
        'user_id': userId,
        'title': title,
        'body': body,
        'type': 'price_increase',
        'is_read': 0,
        'created_at': DateTimeUtils.nowIso(),
      });
    }
  }
}
