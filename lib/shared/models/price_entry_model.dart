class PriceEntryModel {
  const PriceEntryModel({
    this.id,
    required this.commodityId,
    required this.storeId,
    required this.price,
    required this.recordedAt,
    required this.source,
  });

  final int? id;
  final int commodityId;
  final int storeId;
  final double price;
  final String recordedAt;
  final String source;

  factory PriceEntryModel.fromMap(Map<String, Object?> map) {
    return PriceEntryModel(
      id: map['id'] as int?,
      commodityId: map['commodity_id'] as int,
      storeId: map['store_id'] as int,
      price: (map['price'] as num).toDouble(),
      recordedAt: map['recorded_at'] as String,
      source: map['source'] as String? ?? 'manual',
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'commodity_id': commodityId,
      'store_id': storeId,
      'price': price,
      'recorded_at': recordedAt,
      'source': source,
    };
  }
}
