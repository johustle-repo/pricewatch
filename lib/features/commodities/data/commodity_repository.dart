import '../../../core/database/cloud_data_service.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/commodity_model.dart';
import '../../../shared/models/price_entry_model.dart';
import '../../../shared/models/store_model.dart';
import '../../../shared/models/watchlist_model.dart';
import '../../../shared/models/ui_models.dart';

class CommodityRepository {
  CommodityRepository({required CloudDataService cloudDataService})
    : _cloudDataService = cloudDataService;

  final CloudDataService _cloudDataService;

  Future<List<CategoryModel>> getCategories() async {
    final rows =
        (await _cloudDataService.getCollection(
            'categories',
          )).map(CategoryModel.fromMap).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return rows;
  }

  Future<List<CommodityModel>> getAllCommodities() async {
    final rows =
        (await _cloudDataService.getCollection(
            'commodities',
          )).map(CommodityModel.fromMap).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return rows;
  }

  Future<List<CommodityOverview>> getCommodities({
    String query = '',
    int? categoryId,
    int? userId,
  }) async {
    final commodities = await getAllCommodities();
    final categories = await getCategories();
    final priceEntries = (await _cloudDataService.getCollection(
      'price_entries',
    )).map(PriceEntryModel.fromMap).toList();
    final watchedIds = userId == null
        ? <int>{}
        : ((await _cloudDataService.getCollectionWhere(
                    'watchlists',
                    field: 'user_id',
                    value: userId,
                  ))
                  .map(WatchlistModel.fromMap)
                  .where((item) => item.userId == userId)
                  .map((item) => item.commodityId))
              .toSet();

    final normalized = query.trim().toLowerCase();
    final filtered = commodities.where((item) {
      final matchesQuery =
          normalized.isEmpty || item.name.toLowerCase().contains(normalized);
      final matchesCategory =
          categoryId == null || item.categoryId == categoryId;
      return matchesQuery && matchesCategory;
    });

    return filtered
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
  }

  Future<CommodityDetailData?> getCommodityDetail(
    int commodityId, {
    int? userId,
  }) async {
    final commodities = await getAllCommodities();
    final commodityMatches = commodities
        .where((item) => item.id == commodityId)
        .toList();
    if (commodityMatches.isEmpty) {
      return null;
    }
    final commodity = commodityMatches.first;
    final categories = await getCategories();
    final category = categories
        .where((item) => item.id == commodity.categoryId)
        .firstOrNull;
    final stores = (await _cloudDataService.getCollection(
      'stores',
    )).map(StoreModel.fromMap).where((item) => !item.isArchived).toList();
    final entries =
        (await _cloudDataService.getCollection('price_entries'))
            .map(PriceEntryModel.fromMap)
            .where((item) => item.commodityId == commodityId)
            .toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final latestByStore = <int, PriceEntryModel>{};
    for (final entry in entries) {
      latestByStore.putIfAbsent(entry.storeId, () => entry);
    }

    final snapshots =
        latestByStore.values
            .map((entry) {
              final store = stores
                  .where((item) => item.id == entry.storeId)
                  .firstOrNull;
              final storeId = store?.id;
              if (store == null || storeId == null) {
                return null;
              }
              return StorePriceSnapshot(
                storeId: storeId,
                storeName: store.name,
                marketName: store.marketName,
                address: store.address,
                city: store.city,
                price: entry.price,
                recordedAt: entry.recordedAt,
                differenceFromSrp: entry.price - commodity.srp,
              );
            })
            .nonNulls
            .toList()
          ..sort((a, b) => a.price.compareTo(b.price));

    final groupedByDay = <String, List<PriceEntryModel>>{};
    for (final entry in entries) {
      final day = entry.recordedAt.substring(0, 10);
      groupedByDay.putIfAbsent(day, () => []).add(entry);
    }
    final history = groupedByDay.entries.map((item) {
      final average =
          item.value.map((entry) => entry.price).reduce((a, b) => a + b) /
          item.value.length;
      return PriceHistoryPoint(
        date: DateTime.parse('${item.key}T00:00:00'),
        value: average,
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    final watchInfo = userId == null
        ? null
        : (await _cloudDataService.getCollectionWhere(
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

    final average = snapshots.isEmpty
        ? commodity.srp
        : snapshots.map((e) => e.price).reduce((a, b) => a + b) /
              snapshots.length;
    final lowest = snapshots.isEmpty
        ? commodity.srp
        : snapshots.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    final highest = snapshots.isEmpty
        ? commodity.srp
        : snapshots.map((e) => e.price).reduce((a, b) => a > b ? a : b);

    return CommodityDetailData(
      commodity: commodity,
      category:
          category ??
          CategoryModel(
            id: commodity.categoryId,
            name: 'Uncategorized',
            icon: 'category',
            createdAt: '',
          ),
      latestStorePrices: snapshots,
      history: history,
      averagePrice: average,
      lowestPrice: lowest,
      highestPrice: highest,
      isWatched: watchInfo?.isNotEmpty == true,
      watchThreshold: watchInfo?.firstOrNull?.priceThreshold,
    );
  }

  (double, String) _latestAverageForCommodity(
    List<PriceEntryModel> entries,
    int commodityId,
  ) {
    final commodityEntries =
        entries.where((item) => item.commodityId == commodityId).toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    if (commodityEntries.isEmpty) {
      return (0, '');
    }

    final latestByStore = <int, PriceEntryModel>{};
    for (final entry in commodityEntries) {
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
