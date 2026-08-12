class ReportModel {
  const ReportModel({
    this.id,
    required this.userId,
    required this.commodityId,
    required this.storeId,
    required this.observedPrice,
    required this.srpSnapshot,
    required this.reason,
    required this.photoPath,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int userId;
  final int commodityId;
  final int storeId;
  final double observedPrice;
  final double srpSnapshot;
  final String reason;
  final String? photoPath;
  final String status;
  final String createdAt;
  final String updatedAt;

  factory ReportModel.fromMap(Map<String, Object?> map) {
    return ReportModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      commodityId: map['commodity_id'] as int,
      storeId: map['store_id'] as int,
      observedPrice: (map['observed_price'] as num).toDouble(),
      srpSnapshot: (map['srp_snapshot'] as num).toDouble(),
      reason: map['reason'] as String,
      photoPath: map['photo_path'] as String?,
      status: map['status'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'commodity_id': commodityId,
      'store_id': storeId,
      'observed_price': observedPrice,
      'srp_snapshot': srpSnapshot,
      'reason': reason,
      'photo_path': photoPath,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
