import '../../../core/database/cloud_data_service.dart';
import '../../../core/utils/market_prices.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/commodity_model.dart';
import '../../../shared/models/price_entry_model.dart';
import '../../../shared/models/store_model.dart';
import '../domain/market_display_models.dart';

class MarketDisplayRepository {
  MarketDisplayRepository({required CloudDataService cloudDataService})
    : _cloudDataService = cloudDataService;

  final CloudDataService _cloudDataService;
  static const Set<String> _publicBoardCategoryNames = {
    'rice',
    'eggs',
    'vegetables',
    'fish',
    'meat',
  };

  Stream<MarketDisplayData> watchLingayenMarketDisplayData() {
    return _watchLingayenMarketDisplayData();
  }

  Future<MarketDisplayData> getLingayenMarketDisplayData() async {
    final source = await _loadBoardSource();
    final entries =
        (await _cloudDataService.getCollectionWhereIn(
              'price_entries',
              field: 'store_id',
              values: source.storeIds,
            ))
            .map(PriceEntryModel.fromMap)
            .where((item) => source.storeIds.contains(item.storeId))
            .toList();
    return _buildDisplayData(source, entries);
  }

  Stream<MarketDisplayData> _watchLingayenMarketDisplayData() async* {
    final source = await _loadBoardSource();
    await for (final priceRows in _cloudDataService.watchCollectionWhereIn(
      'price_entries',
      field: 'store_id',
      values: source.storeIds,
    )) {
      final entries = priceRows
          .map(PriceEntryModel.fromMap)
          .where((item) => source.storeIds.contains(item.storeId))
          .toList();
      yield _buildDisplayData(source, entries);
    }
  }

  Future<_BoardSource> _loadBoardSource() async {
    final stores = (await _cloudDataService.getCollection(
      'stores',
    )).map(StoreModel.fromMap).where((item) => !item.isArchived).toList();
    final storeMatches = _lingayenStores(stores);
    final commodities = (await _cloudDataService.getCollection(
      'commodities',
    )).map(CommodityModel.fromMap).toList();
    final categories = (await _cloudDataService.getCollection(
      'categories',
    )).map(CategoryModel.fromMap).toList();
    return _BoardSource(
      stores: storeMatches,
      storeIds: storeMatches.map((item) => item.id).nonNulls.toList(),
      commodities: commodities,
      categories: categories,
    );
  }

  MarketDisplayData _buildDisplayData(
    _BoardSource source,
    List<PriceEntryModel> entries,
  ) {
    final store = source.stores.isEmpty
        ? _fallbackLingayenMarket()
        : _displayStoreForEntries(source.stores, entries);
    final categoryNames = {
      for (final category in source.categories) category.id: category.name,
    };
    final entriesByCommodity = <int, List<PriceEntryModel>>{};
    for (final entry in entries) {
      entriesByCommodity.putIfAbsent(entry.commodityId, () => []).add(entry);
    }

    final boardCommodities =
        source.commodities
            .where(
              (commodity) =>
                  commodity.id != null &&
                  _isPublicBoardCategory(categoryNames[commodity.categoryId]),
            )
            .toList()
          ..sort((a, b) {
            final categorySort = (categoryNames[a.categoryId] ?? '').compareTo(
              categoryNames[b.categoryId] ?? '',
            );
            return categorySort != 0 ? categorySort : a.name.compareTo(b.name);
          });

    DateTime? lastUpdatedAt;
    final items = boardCommodities.map((commodity) {
      // Each stall is compared with its own previous price, so differences
      // between stalls recorded on the same day never appear as movement.
      final market = currentMarketPrice(
        entriesByCommodity[commodity.id] ?? const [],
      );
      final recordedAt = market.latestRecordedAt;
      final recordedAtDate = recordedAt == null
          ? null
          : DateTime.tryParse(recordedAt);
      if (recordedAtDate != null &&
          (lastUpdatedAt == null || recordedAtDate.isAfter(lastUpdatedAt!))) {
        lastUpdatedAt = recordedAtDate;
      }
      return MarketDisplayPriceItem(
        commodityId: commodity.id!,
        commodityName: commodity.name,
        categoryName: categoryNames[commodity.categoryId] ?? 'Uncategorized',
        unit: commodity.unit,
        srp: commodity.srp,
        currentPrice: market.average ?? commodity.srp,
        previousPrice: market.previousAverage ?? commodity.srp,
        recordedAt: recordedAt ?? '',
        hasRecordedPrice: market.hasPrice,
        storeCount: market.storeCount,
        lowestPrice: market.lowest,
        highestPrice: market.highest,
      );
    }).toList();

    return MarketDisplayData(
      storeId: store.id ?? 0,
      storeName: store.name,
      marketName: store.marketName,
      address: store.address,
      city: store.city,
      lastUpdatedAt: (lastUpdatedAt ?? DateTime.now().toUtc())
          .toIso8601String(),
      items: items,
    );
  }

  bool _isPublicBoardCategory(String? categoryName) {
    return _publicBoardCategoryNames.contains(
      (categoryName ?? '').trim().toLowerCase(),
    );
  }

  List<StoreModel> _lingayenStores(List<StoreModel> stores) {
    return stores
        .where(
          (item) =>
              item.name.toLowerCase().contains('lingayen public market') ||
              (item.marketName ?? '').toLowerCase().contains('lingayen') ||
              (item.city ?? '').toLowerCase().contains('lingayen'),
        )
        .toList();
  }

  StoreModel _fallbackLingayenMarket() {
    return StoreModel(
      id: 0,
      name: 'Lingayen Public Market',
      marketName: 'Lingayen Public Market',
      address: 'Poblacion',
      city: 'Lingayen, Pangasinan',
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  StoreModel _displayStoreForEntries(
    List<StoreModel> stores,
    List<PriceEntryModel> entries,
  ) {
    if (stores.length == 1 || entries.isEmpty) {
      return stores.first;
    }

    final latestByStoreId = <int, String>{};
    for (final entry in entries) {
      final currentLatest = latestByStoreId[entry.storeId];
      if (currentLatest == null ||
          entry.recordedAt.compareTo(currentLatest) > 0) {
        latestByStoreId[entry.storeId] = entry.recordedAt;
      }
    }

    final sorted = [...stores]
      ..sort((left, right) {
        final leftLatest = latestByStoreId[left.id] ?? '';
        final rightLatest = latestByStoreId[right.id] ?? '';
        return rightLatest.compareTo(leftLatest);
      });
    return sorted.first;
  }
}

class _BoardSource {
  const _BoardSource({
    required this.stores,
    required this.storeIds,
    required this.commodities,
    required this.categories,
  });

  final List<StoreModel> stores;
  final List<int> storeIds;
  final List<CommodityModel> commodities;
  final List<CategoryModel> categories;
}
