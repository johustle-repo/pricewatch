import '../../../core/database/cloud_data_service.dart';
import '../../../core/utils/market_prices.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/commodity_model.dart';
import '../../../shared/models/price_entry_model.dart';
import '../../../shared/models/store_model.dart';
import '../../../shared/models/ui_models.dart';
import '../../../shared/models/watchlist_model.dart';

class HomeRepository {
  HomeRepository({required CloudDataService cloudDataService})
    : _cloudDataService = cloudDataService;

  final CloudDataService _cloudDataService;

  Future<DashboardData> getDashboard(int userId) async {
    final categories =
        (await _cloudDataService.getCollection(
            'categories',
          )).map(CategoryModel.fromMap).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final commodities = (await _cloudDataService.getCollection(
      'commodities',
    )).map(CommodityModel.fromMap).toList();
    final priceEntries = (await _cloudDataService.getCollection(
      'price_entries',
    )).map(PriceEntryModel.fromMap).toList();
    final notifications = await _cloudDataService.getCollectionWhere(
      'notifications',
      field: 'user_id',
      value: userId,
    );
    final watchlists = (await _cloudDataService.getCollectionWhere(
      'watchlists',
      field: 'user_id',
      value: userId,
    )).map(WatchlistModel.fromMap).toList();
    final reports = await _cloudDataService.getCollectionWhere(
      'reports',
      field: 'user_id',
      value: userId,
    );
    final stores = (await _cloudDataService.getCollection(
      'stores',
    )).map(StoreModel.fromMap).where((item) => !item.isArchived).toList();
    final activeStoreIds = stores.map((item) => item.id).nonNulls.toSet();
    final activeEntries = priceEntries
        .where((entry) => activeStoreIds.contains(entry.storeId))
        .toList();

    final userWatchlists = watchlists
        .where((item) => item.userId == userId)
        .toList();
    final watchedIds = userWatchlists.map((item) => item.commodityId).toSet();

    final entriesByCommodity = <int, List<PriceEntryModel>>{};
    for (final entry in activeEntries) {
      entriesByCommodity.putIfAbsent(entry.commodityId, () => []).add(entry);
    }
    final overviews = commodities.where((item) => item.id != null).map((
      commodity,
    ) {
      final category = categories
          .where((item) => item.id == commodity.categoryId)
          .firstOrNull;
      final market = currentMarketPrice(
        entriesByCommodity[commodity.id] ?? const [],
      );
      return CommodityOverview(
        id: commodity.id!,
        categoryId: commodity.categoryId,
        categoryName: category?.name ?? 'Uncategorized',
        name: commodity.name,
        unit: commodity.unit,
        srp: commodity.srp,
        latestAveragePrice: market.average ?? commodity.srp,
        latestUpdatedAt: market.latestRecordedAt ?? '',
        storeCount: market.storeCount,
        isWatched: watchedIds.contains(commodity.id),
      );
    }).toList();
    // Feature the most recently priced commodities; unpriced ones come last.
    overviews.sort((a, b) {
      final byDate = b.latestUpdatedAt.compareTo(a.latestUpdatedAt);
      return byDate != 0 ? byDate : b.srp.compareTo(a.srp);
    });
    final featuredProducts = overviews.take(6).toList();

    final updates = [...activeEntries]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final latestUpdates = updates
        .map((entry) {
          final commodity = commodities
              .where((item) => item.id == entry.commodityId)
              .firstOrNull;
          final store = stores
              .where((item) => item.id == entry.storeId)
              .firstOrNull;
          if (commodity == null || store == null) {
            return null;
          }
          return PriceUpdateItem(
            commodityId: commodity.id,
            commodityName: commodity.name,
            storeName: store.name,
            price: entry.price,
            recordedAt: entry.recordedAt,
          );
        })
        .nonNulls
        .take(8)
        .toList();

    return DashboardData(
      categories: categories,
      featuredProducts: featuredProducts,
      latestUpdates: latestUpdates,
      unreadNotifications: notifications
          .where((item) => item['user_id'] == userId && item['is_read'] == 0)
          .length,
      watchlistCount: userWatchlists.length,
      reportsCount: reports.where((item) => item['user_id'] == userId).length,
      storeCount: stores.length,
      commodityCounts: {
        for (final category in categories)
          if (category.id != null)
            category.id!: commodities
                .where((item) => item.categoryId == category.id)
                .length,
      },
    );
  }
}
