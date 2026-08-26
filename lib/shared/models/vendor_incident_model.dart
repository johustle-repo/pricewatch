class VendorIncidentModel {
  const VendorIncidentModel({
    this.id,
    required this.userId,
    this.legacyStoreId,
    required this.reportedVendorName,
    required this.marketLocation,
    required this.reasonCode,
    required this.details,
    required this.evidencePhotos,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int userId;
  final int? legacyStoreId;
  final String reportedVendorName;
  final String marketLocation;
  final String reasonCode;
  final String details;
  final List<String> evidencePhotos;
  final String status;
  final String createdAt;
  final String updatedAt;

  factory VendorIncidentModel.fromMap(Map<String, Object?> map) {
    return VendorIncidentModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      legacyStoreId: map['store_id'] as int?,
      reportedVendorName:
          map['reported_vendor_name'] as String? ?? 'Unidentified vendor',
      marketLocation:
          map['market_location'] as String? ?? 'Location not supplied',
      reasonCode: map['reason_code'] as String? ?? 'other',
      details: map['details'] as String? ?? '',
      evidencePhotos: (map['evidence_photos'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      status: map['status'] as String? ?? 'pending',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'user_id': userId,
    if (legacyStoreId != null) 'store_id': legacyStoreId,
    'reported_vendor_name': reportedVendorName,
    'market_location': marketLocation,
    'reason_code': reasonCode,
    'details': details,
    'evidence_photos': evidencePhotos,
    'status': status,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class VendorIncidentViewData {
  const VendorIncidentViewData({
    required this.incident,
    required this.reporterName,
  });

  final VendorIncidentModel incident;
  final String reporterName;
}
