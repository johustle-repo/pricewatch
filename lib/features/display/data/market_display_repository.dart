import '../../../core/database/cloud_data_service.dart';
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
    final stores = (await _cloudDataService.getCollection(
      'stores',
    )).map(StoreModel.fromMap).where((item) => !item.isArchived).toList();
    final storeMatches = _lingayenStores(stores);
    final storeIds = storeMatches.map((item) => item.id).nonNulls.toSet();

    final commodities = (await _cloudDataService.getCollection(
      'commodities',
    )).map(CommodityModel.fromMap).toList();
    final categories = (await _cloudDataService.getCollection(
      'categories',
    )).map(CategoryModel.fromMap).toList();
    final entries = (await _cloudDataService.getCollection('price_entries'))
        .map(PriceEntryModel.fromMap)
        .where((item) => storeIds.contains(item.storeId))
        .toList();
    final store = storeMatches.isEmpty
        ? _fallbackLingayenMarket()
        : _displayStoreForEntries(storeMatches, entries);
    final storeId = store.id ?? 0;

    return _buildDisplayData(
      store: store,
      storeId: storeId,
      commodities: commodities,
      categories: categories,
      entries: entries,
    );
  }

  Stream<MarketDisplayData> _watchLingayenMarketDisplayData() async* {
    final stores = (await _cloudDataService.getCollection(
      'stores',
    )).map(StoreModel.fromMap).where((item) => !item.isArchived).toList();
    final storeMatches = _lingayenStores(stores);
    final storeIds = storeMatches.map((item) => item.id).nonNulls.toSet();

    final commodities = (await _cloudDataService.getCollection(
      'commodities',
    )).map(CommodityModel.fromMap).toList();
    final categories = (await _cloudDataService.getCollection(
      'categories',
    )).map(CategoryModel.fromMap).toList();

    await for (final priceRows in _cloudDataService.watchCollection(
      'price_entries',
    )) {
      final entries = priceRows
          .map(PriceEntryModel.fromMap)
          .where((item) => storeIds.contains(item.storeId))
          .toList();
      final store = storeMatches.isEmpty
          ? _fallbackLingayenMarket()
          : _displayStoreForEntries(storeMatches, entries);
      final storeId = store.id ?? 0;
      yield _buildDisplayData(
        store: store,
        storeId: storeId,
        commodities: commodities,
        categories: categories,
        entries: entries,
      );
    }
  }

  MarketDisplayData _buildDisplayData({
    required StoreModel store,
    required int storeId,
    required List<CommodityModel> commodities,
    required List<CategoryModel> categories,
    required List<PriceEntryModel> entries,
  }) {
    entries.sort((a, b) {
      final timeSort = b.recordedAt.compareTo(a.recordedAt);
      if (timeSort != 0) {
        return timeSort;
      }
      return (b.id ?? 0).compareTo(a.id ?? 0);
    });

    final latestByCommodity = <int, PriceEntryModel>{};
    final previousByCommodity = <int, PriceEntryModel>{};
    for (final entry in entries) {
      if (!latestByCommodity.containsKey(entry.commodityId)) {
        latestByCommodity[entry.commodityId] = entry;
      } else if (!previousByCommodity.containsKey(entry.commodityId)) {
        previousByCommodity[entry.commodityId] = entry;
      }
    }

    final commodityIds =
        commodities
            .where((commodity) {
              if (commodity.id == null) return false;
              final category = categories
                  .where((item) => item.id == commodity.categoryId)
                  .firstOrNull;
              return _isPublicBoardCategory(category?.name);
            })
            .map((commodity) => commodity.id!)
            .toList()
          ..sort((a, b) {
            final commodityA = commodities
                .where((item) => item.id == a)
                .firstOrNull;
            final commodityB = commodities
                .where((item) => item.id == b)
                .firstOrNull;
            final categoryA = categories
                .where((item) => item.id == commodityA?.categoryId)
                .firstOrNull;
            final categoryB = categories
                .where((item) => item.id == commodityB?.categoryId)
                .firstOrNull;
            final categorySort = (categoryA?.name ?? 'Uncategorized').compareTo(
              categoryB?.name ?? 'Uncategorized',
            );
            if (categorySort != 0) {
              return categorySort;
            }
            return (commodityA?.name ?? '').compareTo(commodityB?.name ?? '');
          });

    DateTime? lastUpdatedAt;
    final items = commodityIds
        .map((commodityId) {
          final latest = latestByCommodity[commodityId];
          final previous = previousByCommodity[commodityId];
          final commodity = commodities
              .where((item) => item.id == commodityId)
              .firstOrNull;
          if (commodity == null) {
            return null;
          }
          final category = categories
              .where((item) => item.id == commodity.categoryId)
              .firstOrNull;
          if (!_isPublicBoardCategory(category?.name)) {
            return null;
          }
          final recordedAt =
              latest?.recordedAt ?? DateTime.now().toUtc().toIso8601String();
          final recordedAtDate = DateTime.tryParse(recordedAt);
          if (recordedAtDate != null &&
              (lastUpdatedAt == null ||
                  recordedAtDate.isAfter(lastUpdatedAt!))) {
            lastUpdatedAt = recordedAtDate;
          }
          return MarketDisplayPriceItem(
            commodityId: commodityId,
            commodityName: commodity.name,
            categoryName: category?.name ?? 'Uncategorized',
            unit: commodity.unit,
            srp: commodity.srp,
            currentPrice: latest?.price ?? commodity.srp,
            previousPrice: previous?.price ?? latest?.price ?? commodity.srp,
            recordedAt: recordedAt,
          );
        })
        .nonNulls
        .toList();

    return MarketDisplayData(
      storeId: storeId,
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
