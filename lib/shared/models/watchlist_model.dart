class WatchlistModel {
  const WatchlistModel({
    this.id,
    required this.userId,
    required this.commodityId,
    required this.priceThreshold,
    required this.createdAt,
  });

  final int? id;
  final int userId;
  final int commodityId;
  final double? priceThreshold;
  final String createdAt;

  factory WatchlistModel.fromMap(Map<String, Object?> map) {
    return WatchlistModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      commodityId: map['commodity_id'] as int,
      priceThreshold: (map['price_threshold'] as num?)?.toDouble(),
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'commodity_id': commodityId,
      'price_threshold': priceThreshold,
      'created_at': createdAt,
    };
  }
}
