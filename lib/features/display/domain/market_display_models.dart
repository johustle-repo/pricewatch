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

  int get aboveSrpCount =>
      items.where((item) => item.currentPrice > item.srp).length;

  int get belowSrpCount =>
      items.where((item) => item.currentPrice < item.srp).length;

  int get updatedTodayCount {
    final now = DateTime.now();
    return items.where((item) {
      final updated = DateTime.parse(item.recordedAt).toLocal();
      return updated.year == now.year &&
          updated.month == now.month &&
          updated.day == now.day;
    }).length;
  }

  double get averagePrice {
    if (items.isEmpty) {
      return 0;
    }

    final total = items.fold<double>(0, (sum, item) => sum + item.currentPrice);
    return total / items.length;
  }

  List<MarketDisplayPriceItem> get spotlightItems {
    final sorted = [...items]
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
  });

  final int commodityId;
  final String commodityName;
  final String categoryName;
  final String unit;
  final double srp;
  final double currentPrice;
  final double previousPrice;
  final String recordedAt;

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
