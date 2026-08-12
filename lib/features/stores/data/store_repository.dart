import '../../../core/database/cloud_data_service.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/models/commodity_model.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/price_entry_model.dart';
import '../../../shared/models/store_model.dart';
import '../../../shared/models/ui_models.dart';

class StoreRepository {
  StoreRepository({required CloudDataService cloudDataService})
    : _cloudDataService = cloudDataService;

  final CloudDataService _cloudDataService;

  Future<List<StoreModel>> getAllStores() async {
    final rows =
        (await _cloudDataService.getCollection(
            'stores',
          )).map(StoreModel.fromMap).where((item) => !item.isArchived).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return rows;
  }

  Future<List<StoreSummary>> getStores({String query = ''}) async {
    final stores = await getAllStores();
    final priceEntries = (await _cloudDataService.getCollection(
      'price_entries',
    )).map(PriceEntryModel.fromMap).toList();
    final normalized = query.trim().toLowerCase();
    final filtered = normalized.isEmpty
        ? stores
        : stores
              .where((item) => item.name.toLowerCase().contains(normalized))
              .toList();

    return filtered
        .map((store) {
          final storeId = store.id;
          if (storeId == null) {
            return null;
          }
          // Complaint records are private to the reporter, assigned vendor,
          // and administrators. Public store summaries do not enumerate them.
          const reportCount = 0;
          final latestPrices = priceEntries
              .where((item) => item.storeId == storeId)
              .map((item) => item.commodityId)
              .toSet()
              .length;
          return StoreSummary(
            id: storeId,
            name: store.name,
            marketName: store.marketName,
            address: store.address,
            city: store.city,
            reportCount: reportCount,
            rating: _ratingForReports(reportCount),
            latestPriceCount: latestPrices,
          );
        })
        .nonNulls
        .toList();
  }

  Future<StoreDetailData> getStoreDetail(int storeId) async {
    final stores = await getAllStores();
    final store = stores.where((item) => item.id == storeId).firstOrNull;
    if (store == null) {
      throw Exception('Store not found.');
    }

    final commodities = (await _cloudDataService.getCollection(
      'commodities',
    )).map(CommodityModel.fromMap).toList();
    final priceEntries =
        (await _cloudDataService.getCollection('price_entries'))
            .map(PriceEntryModel.fromMap)
            .where((item) => item.storeId == storeId)
            .toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    final latestByCommodity = <int, PriceEntryModel>{};
    for (final entry in priceEntries) {
      latestByCommodity.putIfAbsent(entry.commodityId, () => entry);
    }

    final prices =
        latestByCommodity.values
            .map((entry) {
              final commodity = commodities
                  .where((item) => item.id == entry.commodityId)
                  .firstOrNull;
              final commodityId = commodity?.id;
              if (commodity == null || commodityId == null) {
                return null;
              }
              return StoreCommodityPrice(
                commodityId: commodityId,
                commodityName: commodity.name,
                unit: commodity.unit,
                srp: commodity.srp,
                latestPrice: entry.price,
                recordedAt: entry.recordedAt,
              );
            })
            .nonNulls
            .toList()
          ..sort((a, b) => a.commodityName.compareTo(b.commodityName));

    const reportCount = 0;
    const pending = 0;
    const resolved = 0;

    return StoreDetailData(
      store: store,
      prices: prices,
      rating: _ratingForReports(reportCount),
      reportCount: reportCount,
      pendingReports: pending,
      resolvedReports: resolved,
    );
  }

  Future<List<CommodityModel>> getProductCatalog() async {
    final commodities =
        (await _cloudDataService.getCollection('commodities'))
            .map(CommodityModel.fromMap)
            .where((item) => item.id != null)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return commodities;
  }

  Future<List<CategoryModel>> getProductCategories() async {
    final categories =
        (await _cloudDataService.getCollection(
            'categories',
          )).map(CategoryModel.fromMap).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return categories;
  }

  Future<Map<int, List<PriceEntryModel>>> getStorePriceHistory(
    int storeId,
  ) async {
    final entries =
        (await _cloudDataService.getCollectionWhere(
            'price_entries',
            field: 'store_id',
            value: storeId,
          )).map(PriceEntryModel.fromMap).toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final history = <int, List<PriceEntryModel>>{};
    for (final entry in entries) {
      history.putIfAbsent(entry.commodityId, () => []).add(entry);
    }
    return history;
  }

  Future<void> addVendorProductPrice({
    required int storeId,
    required int commodityId,
    required double price,
  }) async {
    final id = _cloudDataService.generateId();
    await _cloudDataService.setDocument('price_entries', id, {
      'id': id,
      'commodity_id': commodityId,
      'store_id': storeId,
      'price': price,
      'recorded_at': DateTimeUtils.nowIso(),
      'source': 'vendor',
    });
  }

  Future<void> removeVendorProduct({
    required int storeId,
    required int commodityId,
  }) async {
    final entries =
        (await _cloudDataService.getCollectionWhere(
              'price_entries',
              field: 'store_id',
              value: storeId,
            ))
            .map(PriceEntryModel.fromMap)
            .where((entry) => entry.commodityId == commodityId);
    for (final entry in entries) {
      final id = entry.id;
      if (id != null) {
        await _cloudDataService.deleteOwnedDocument('price_entries', id);
      }
    }
  }

  double _ratingForReports(int reportCount) {
    final rating = 5 - (reportCount * 0.35);
    return rating.clamp(1.0, 5.0);
  }
}
