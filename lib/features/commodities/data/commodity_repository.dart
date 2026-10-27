import '../../../core/database/cloud_data_service.dart';
import '../../../core/utils/market_prices.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/commodity_model.dart';
import '../../../shared/models/price_entry_model.dart';
import '../../../shared/models/store_model.dart';
import '../../../shared/models/subcategory_model.dart';
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

  Future<List<SubcategoryModel>> getSubcategories({int? categoryId}) async {
    final rows =
        (await _cloudDataService.getCollection('subcategories'))
            .map(SubcategoryModel.fromMap)
            .where(
              (item) => categoryId == null || item.categoryId == categoryId,
            )
            .toList()
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
    final subcategoryNames = {
      for (final item in await getSubcategories()) item.id: item.name,
    };
    final activeStoreIds = await _activeStoreIds();
    final entriesByCommodity = <int, List<PriceEntryModel>>{};
    for (final entry in (await _cloudDataService.getCollection(
      'price_entries',
    )).map(PriceEntryModel.fromMap)) {
      entriesByCommodity.putIfAbsent(entry.commodityId, () => []).add(entry);
    }
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
      final subcategoryName = subcategoryNames[item.subcategoryId] ?? '';
      final matchesQuery =
          normalized.isEmpty ||
          item.name.toLowerCase().contains(normalized) ||
          subcategoryName.toLowerCase().contains(normalized);
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
          final market = currentMarketPrice(
            entriesByCommodity[commodityId] ?? const [],
            activeStoreIds: activeStoreIds,
          );
          return CommodityOverview(
            id: commodityId,
            categoryId: commodity.categoryId,
            categoryName: category?.name ?? 'Uncategorized',
            subcategoryId: subcategoryNames.containsKey(commodity.subcategoryId)
                ? commodity.subcategoryId
                : null,
            subcategoryName: subcategoryNames[commodity.subcategoryId],
            name: commodity.name,
            unit: commodity.unit,
            srp: commodity.srp,
            latestAveragePrice: market.average ?? commodity.srp,
            latestUpdatedAt: market.latestRecordedAt ?? '',
            storeCount: market.storeCount,
            isWatched: watchedIds.contains(commodityId),
          );
        })
        .nonNulls
        .toList();
  }

  Future<Set<int>> _activeStoreIds() async {
    return (await _cloudDataService.getCollection('stores'))
        .map(StoreModel.fromMap)
        .where((item) => !item.isArchived)
        .map((item) => item.id)
        .nonNulls
        .toSet();
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
    final subcategoryName = commodity.subcategoryId == null
        ? null
        : (await getSubcategories(categoryId: commodity.categoryId))
              .where((item) => item.id == commodity.subcategoryId)
              .firstOrNull
              ?.name;
    final stores = (await _cloudDataService.getCollection(
      'stores',
    )).map(StoreModel.fromMap).where((item) => !item.isArchived).toList();
    final activeStoreIds = stores.map((item) => item.id).nonNulls.toSet();
    final entries =
        (await _cloudDataService.getCollectionWhere(
              'price_entries',
              field: 'commodity_id',
              value: commodityId,
            ))
            .map(PriceEntryModel.fromMap)
            .where(
              (item) =>
                  item.commodityId == commodityId &&
                  activeStoreIds.contains(item.storeId),
            )
            .toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final market = currentMarketPrice(entries);

    final snapshots =
        market.latest
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
      subcategoryName: subcategoryName,
      latestStorePrices: snapshots,
      priceEntries: entries,
      history: history,
      hasRecordedPrice: market.hasPrice,
      latestRecordedAt: market.latestRecordedAt,
      averagePrice: market.average ?? commodity.srp,
      lowestPrice: market.lowest ?? commodity.srp,
      highestPrice: market.highest ?? commodity.srp,
      isWatched: watchInfo?.isNotEmpty == true,
      watchThreshold: watchInfo?.firstOrNull?.priceThreshold,
    );
  }
}
