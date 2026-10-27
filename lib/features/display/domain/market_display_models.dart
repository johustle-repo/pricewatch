import '../../../core/utils/market_prices.dart';

class MarketDisplayData {
  const MarketDisplayData({
    required this.storeId,
    required this.storeName,
    required this.marketName,
    required this.address,
    required this.city,
    required this.lastUpdatedAt,
    required this.items,
  });

  final int storeId;
  final String storeName;
  final String? marketName;
  final String address;
  final String? city;
  final String lastUpdatedAt;
  final List<MarketDisplayPriceItem> items;

  int get itemCount => items.length;

  /// Items with at least one recorded market price.
  List<MarketDisplayPriceItem> get pricedItems =>
      items.where((item) => item.hasRecordedPrice).toList();

  int get aboveSrpCount => pricedItems.where((item) => item.isAboveSrp).length;

  int get belowSrpCount => pricedItems.where((item) => item.isBelowSrp).length;

  int get updatedTodayCount {
    final now = DateTime.now();
    return pricedItems.where((item) {
      final updated = DateTime.parse(item.recordedAt).toLocal();
      return updated.year == now.year &&
          updated.month == now.month &&
          updated.day == now.day;
    }).length;
  }

  double get averagePrice {
    final priced = pricedItems;
    if (priced.isEmpty) {
      return 0;
    }

    final total = priced.fold<double>(
      0,
      (sum, item) => sum + item.currentPrice,
    );
    return total / priced.length;
  }

  List<MarketDisplayPriceItem> get spotlightItems {
    final sorted = [...pricedItems]
      ..sort(
        (left, right) => right.absoluteVarianceFromSrp.compareTo(
          left.absoluteVarianceFromSrp,
        ),
      );
    return sorted.take(4).toList(growable: false);
  }
}

class MarketDisplayPriceItem {
  const MarketDisplayPriceItem({
    required this.commodityId,
    required this.commodityName,
    required this.categoryName,
    required this.unit,
    required this.srp,
    required this.currentPrice,
    required this.previousPrice,
    required this.recordedAt,
    this.hasRecordedPrice = true,
    this.storeCount = 1,
    double? lowestPrice,
    double? highestPrice,
  }) : lowestPrice = lowestPrice ?? currentPrice,
       highestPrice = highestPrice ?? currentPrice;

  final int commodityId;
  final String commodityName;
  final String categoryName;
  final String unit;
  final double srp;
  final double currentPrice;
  final double previousPrice;
  final String recordedAt;

  /// False when no stall has recorded a price; the SRP is shown for reference.
  final bool hasRecordedPrice;

  /// Number of stalls whose latest price is in [currentPrice].
  final int storeCount;
  final double lowestPrice;
  final double highestPrice;

  bool get hasPriceRange => highestPrice - lowestPrice > 0.009;

  /// Newest price is older than [stalePriceAge].
  bool get isStale => hasRecordedPrice && isStalePrice(recordedAt);

  String get statusLabel => !hasRecordedPrice
      ? 'No price yet'
      : isAboveSrp
      ? 'Above SRP'
      : isBelowSrp
      ? 'Below SRP'
      : 'At SRP';

  String get storeCountLabel =>
      storeCount == 1 ? '1 stall' : '$storeCount stalls';

  double get deltaFromPrevious => currentPrice - previousPrice;

  double get deltaFromSrp => currentPrice - srp;

  double get absoluteVarianceFromSrp => deltaFromSrp.abs();

  double get percentageFromSrp {
    if (srp == 0) {
      return 0;
    }

    return (deltaFromSrp / srp) * 100;
  }

  bool get isRising => deltaFromPrevious > 0.009;

  bool get isFalling => deltaFromPrevious < -0.009;

  bool get isAboveSrp => deltaFromSrp > 0.009;

  bool get isBelowSrp => deltaFromSrp < -0.009;
}
