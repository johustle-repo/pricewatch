import '../../../core/database/cloud_data_service.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/commodity_model.dart';
import '../../../shared/models/price_entry_model.dart';
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
    final stores = await _cloudDataService.getCollection('stores');

    final userWatchlists = watchlists
        .where((item) => item.userId == userId)
        .toList();
    final watchedIds = userWatchlists.map((item) => item.commodityId).toSet();

    final featuredCommodities = [...commodities]
      ..sort((a, b) => b.srp.compareTo(a.srp));
    final featuredProducts = featuredCommodities
        .where((item) => item.id != null)
        .take(6)
        .map((commodity) {
          final commodityId = commodity.id;
          if (commodityId == null) {
            return null;
          }
          final category = categories
              .where((item) => item.id == commodity.categoryId)
              .firstOrNull;
          final latest = _latestAverageForCommodity(priceEntries, commodityId);
          return CommodityOverview(
            id: commodityId,
            categoryId: commodity.categoryId,
            categoryName: category?.name ?? 'Uncategorized',
            name: commodity.name,
            unit: commodity.unit,
            srp: commodity.srp,
            latestAveragePrice: latest.$1 == 0 ? commodity.srp : latest.$1,
            latestUpdatedAt: latest.$2,
            isWatched: watchedIds.contains(commodityId),
          );
        })
        .nonNulls
        .toList();

    final updates = [...priceEntries]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final latestUpdates = updates
        .map((entry) {
          final commodity = commodities
              .where((item) => item.id == entry.commodityId)
              .firstOrNull;
          final store = stores
              .where((item) => item['id'] == entry.storeId)
              .firstOrNull;
          if (commodity == null || store == null) {
            return null;
          }
          return PriceUpdateItem(
            commodityName: commodity.name,
            storeName: store['name'] as String? ?? 'Unknown store',
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
    );
  }

  (double, String) _latestAverageForCommodity(
    List<PriceEntryModel> entries,
    int commodityId,
  ) {
    final commodityEntries = entries
        .where((item) => item.commodityId == commodityId)
        .toList();
    if (commodityEntries.isEmpty) {
      return (0.0, '');
    }

    final latestByStore = <int, PriceEntryModel>{};
    for (final entry
        in commodityEntries
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt))) {
      latestByStore.putIfAbsent(entry.storeId, () => entry);
    }

    final latestEntries = latestByStore.values.toList();
    final average =
        latestEntries.map((item) => item.price).reduce((a, b) => a + b) /
        latestEntries.length;
    final latestRecordedAt = latestEntries
        .map((item) => item.recordedAt)
        .reduce((a, b) => a.compareTo(b) > 0 ? a : b);
    return (average, latestRecordedAt);
  }
}
