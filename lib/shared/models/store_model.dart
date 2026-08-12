class StoreModel {
  const StoreModel({
    this.id,
    required this.name,
    this.ownerName,
    this.ownerUserId,
    this.isArchived = false,
    this.archivedAt,
    required this.marketName,
    required this.address,
    required this.city,
    this.qrCode,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String? ownerName;
  final int? ownerUserId;
  final bool isArchived;
  final String? archivedAt;
  final String? marketName;
  final String address;
  final String? city;
  final String? qrCode;
  final String createdAt;

  factory StoreModel.fromMap(Map<String, Object?> map) {
    return StoreModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      ownerName: map['owner_name'] as String?,
      ownerUserId: map['owner_user_id'] as int?,
      isArchived: map['is_archived'] == true || map['is_archived'] == 1,
      archivedAt: map['archived_at'] as String?,
      marketName: map['market_name'] as String?,
      address: map['address'] as String,
      city: map['city'] as String?,
      qrCode: map['qr_code'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'owner_name': ownerName,
      'owner_user_id': ownerUserId,
      'is_archived': isArchived,
      'archived_at': archivedAt,
      'market_name': marketName,
      'address': address,
      'city': city,
      'qr_code': qrCode,
      'created_at': createdAt,
    };
  }
}
