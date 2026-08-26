import 'category_model.dart';
import 'commodity_model.dart';
import 'store_model.dart';

class DashboardData {
  const DashboardData({
    required this.categories,
    required this.featuredProducts,
    required this.latestUpdates,
    required this.unreadNotifications,
    required this.watchlistCount,
    required this.reportsCount,
    required this.storeCount,
  });

  final List<CategoryModel> categories;
  final List<CommodityOverview> featuredProducts;
  final List<PriceUpdateItem> latestUpdates;
  final int unreadNotifications;
  final int watchlistCount;
  final int reportsCount;
  final int storeCount;
}

class CommodityOverview {
  const CommodityOverview({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.unit,
    required this.srp,
    required this.latestAveragePrice,
    required this.latestUpdatedAt,
    required this.isWatched,
  });

  final int id;
  final int categoryId;
  final String categoryName;
  final String name;
  final String unit;
  final double srp;
  final double latestAveragePrice;
  final String latestUpdatedAt;
  final bool isWatched;

  double get varianceFromSrp => latestAveragePrice - srp;
}

class PriceUpdateItem {
  const PriceUpdateItem({
    required this.commodityName,
    required this.storeName,
    required this.price,
    required this.recordedAt,
  });

  final String commodityName;
  final String storeName;
  final double price;
  final String recordedAt;
}

class AdminPriceEntryView {
  const AdminPriceEntryView({
    required this.id,
    required this.commodityName,
    required this.storeName,
    required this.price,
    required this.srp,
    required this.unit,
    required this.recordedAt,
    required this.source,
  });

  final int id;
  final String commodityName;
  final String storeName;
  final double price;
  final double srp;
  final String unit;
  final String recordedAt;
  final String source;

  double get variance => price - srp;
}

class StorePriceSnapshot {
  const StorePriceSnapshot({
    required this.storeId,
    required this.storeName,
    required this.marketName,
    required this.address,
    required this.city,
    required this.price,
    required this.recordedAt,
    required this.differenceFromSrp,
  });

  final int storeId;
  final String storeName;
  final String? marketName;
  final String address;
  final String? city;
  final double price;
  final String recordedAt;
  final double differenceFromSrp;
}

class PriceHistoryPoint {
  const PriceHistoryPoint({required this.date, required this.value});

  final DateTime date;
  final double value;
}

class CommodityDetailData {
  const CommodityDetailData({
    required this.commodity,
    required this.category,
    required this.latestStorePrices,
    required this.history,
    required this.averagePrice,
    required this.lowestPrice,
    required this.highestPrice,
    required this.isWatched,
    required this.watchThreshold,
  });

  final CommodityModel commodity;
  final CategoryModel category;
  final List<StorePriceSnapshot> latestStorePrices;
  final List<PriceHistoryPoint> history;
  final double averagePrice;
  final double lowestPrice;
  final double highestPrice;
  final bool isWatched;
  final double? watchThreshold;
}

class StoreSummary {
  const StoreSummary({
    required this.id,
    required this.name,
    required this.marketName,
    required this.address,
    required this.city,
    required this.reportCount,
    required this.rating,
    required this.latestPriceCount,
  });

  final int id;
  final String name;
  final String? marketName;
  final String address;
  final String? city;
  final int reportCount;
  final double rating;
  final int latestPriceCount;
}

class StoreCommodityPrice {
  const StoreCommodityPrice({
    required this.commodityId,
    required this.commodityName,
    required this.unit,
    required this.srp,
    required this.latestPrice,
    required this.recordedAt,
  });

  final int commodityId;
  final String commodityName;
  final String unit;
  final double srp;
  final double latestPrice;
  final String recordedAt;
}

class StoreDetailData {
  const StoreDetailData({
    required this.store,
    required this.prices,
    required this.rating,
    required this.reportCount,
    required this.pendingReports,
    required this.resolvedReports,
  });

  final StoreModel store;
  final List<StoreCommodityPrice> prices;
  final double rating;
  final int reportCount;
  final int pendingReports;
  final int resolvedReports;
}

class WatchlistViewData {
  const WatchlistViewData({
    required this.watchlistId,
    required this.commodityId,
    required this.commodityName,
    required this.unit,
    required this.srp,
    required this.threshold,
    required this.currentPrice,
    required this.previousPrice,
    required this.updatedAt,
    required this.history,
  });

  final int watchlistId;
  final int commodityId;
  final String commodityName;
  final String unit;
  final double srp;
  final double? threshold;
  final double currentPrice;
  final double previousPrice;
  final String updatedAt;
  final List<PriceHistoryPoint> history;

  double get variance => currentPrice - previousPrice;
}

class MarketPriceTrendPoint {
  const MarketPriceTrendPoint({
    required this.date,
    required this.averagePrice,
    required this.averageSrp,
  });

  final DateTime date;
  final double averagePrice;
  final double averageSrp;
}

class CommodityPriceHistoryPoint {
  const CommodityPriceHistoryPoint({
    required this.date,
    required this.price,
    required this.storeId,
    required this.storeName,
  });

  final DateTime date;
  final double price;
  final int storeId;
  final String storeName;
}

class CommodityPriceTrend {
  const CommodityPriceTrend({
    required this.commodityId,
    required this.commodityName,
    required this.unit,
    required this.srp,
    required this.history,
  });

  final int commodityId;
  final String commodityName;
  final String unit;
  final double srp;
  final List<CommodityPriceHistoryPoint> history;
}

class ReportViewData {
  const ReportViewData({
    required this.reportId,
    required this.commodityName,
    required this.storeName,
    required this.userName,
    required this.observedPrice,
    required this.srpSnapshot,
    required this.reason,
    required this.photoPath,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int reportId;
  final String commodityName;
  final String storeName;
  final String userName;
  final double observedPrice;
  final double srpSnapshot;
  final String reason;
  final String? photoPath;
  final String status;
  final String createdAt;
  final String updatedAt;
}

class TopReportedStore {
  const TopReportedStore({required this.storeName, required this.count});

  final String storeName;
  final int count;
}

class CategoryPriceAverage {
  const CategoryPriceAverage({
    required this.categoryName,
    required this.averagePrice,
    required this.averageSrp,
    required this.priceRecordCount,
    required this.commodityCount,
  });

  final String categoryName;
  final double averagePrice;
  final double averageSrp;
  final int priceRecordCount;
  final int commodityCount;

  double get variance => averagePrice - averageSrp;

  double get variancePercent =>
      averageSrp == 0 ? 0 : (variance / averageSrp) * 100;
}

class StatusBreakdown {
  const StatusBreakdown({required this.status, required this.count});

  final String status;
  final int count;
}

class MarketLocationInsight {
  const MarketLocationInsight({
    required this.location,
    required this.storeCount,
    required this.reportCount,
    required this.priceUpdateCount,
  });

  final String location;
  final int storeCount;
  final int reportCount;
  final int priceUpdateCount;
}

class CommodityMonitoringInsight {
  const CommodityMonitoringInsight({
    required this.commodityName,
    required this.categoryName,
    required this.unit,
    required this.averagePrice,
    required this.srp,
    required this.storeCount,
    required this.lastUpdated,
    required this.isStale,
  });

  final String commodityName;
  final String categoryName;
  final String unit;
  final double averagePrice;
  final double srp;
  final int storeCount;
  final String lastUpdated;
  final bool isStale;

  double get variance => averagePrice - srp;
  double get variancePercent => srp == 0 ? 0 : variance / srp * 100;
  bool get isAboveSrp => averagePrice > srp;
}

class AdminAnalyticsData {
  const AdminAnalyticsData({
    required this.totalReports,
    required this.pendingReports,
    required this.reviewedReports,
    required this.resolvedReports,
    required this.watchedItemsCount,
    required this.latestUpdatesCount,
    required this.topReportedStores,
    required this.categoryAverages,
    required this.statusBreakdown,
    required this.locationInsights,
    required this.marketTrend,
    required this.commodityPriceTrends,
    required this.aboveSrpCount,
    required this.highestPrice,
    required this.lowestPrice,
    required this.compliantCount,
    required this.staleCount,
    required this.monitoredPriceCount,
    required this.commodityMonitoring,
  });

  final int totalReports;
  final int pendingReports;
  final int reviewedReports;
  final int resolvedReports;
  final int watchedItemsCount;
  final int latestUpdatesCount;
  final List<TopReportedStore> topReportedStores;
  final List<CategoryPriceAverage> categoryAverages;
  final List<StatusBreakdown> statusBreakdown;
  final List<MarketLocationInsight> locationInsights;
  final List<MarketPriceTrendPoint> marketTrend;
  final List<CommodityPriceTrend> commodityPriceTrends;
  final int aboveSrpCount;
  final double highestPrice;
  final double lowestPrice;
  final int compliantCount;
  final int staleCount;
  final int monitoredPriceCount;
  final List<CommodityMonitoringInsight> commodityMonitoring;

  double get complianceRate =>
      monitoredPriceCount == 0 ? 0 : compliantCount / monitoredPriceCount * 100;
}
