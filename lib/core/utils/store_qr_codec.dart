import 'dart:convert';

import '../../shared/models/store_model.dart';

class StoreQrPayload {
  const StoreQrPayload({
    required this.storeId,
    required this.storeName,
    this.ownerName,
    required this.marketName,
    required this.address,
    required this.city,
  });

  final int storeId;
  final String storeName;
  final String? ownerName;
  final String? marketName;
  final String address;
  final String? city;

  factory StoreQrPayload.fromMap(Map<String, Object?> map) {
    return StoreQrPayload(
      storeId: map['store_id'] as int,
      storeName: map['store_name'] as String,
      ownerName: map['owner_name'] as String?,
      marketName: map['market_name'] as String?,
      address: map['address'] as String,
      city: map['city'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'type': 'pricewatch_store',
      'version': 1,
      'store_id': storeId,
      'store_name': storeName,
      'owner_name': ownerName,
      'market_name': marketName,
      'address': address,
      'city': city,
    };
  }

  Map<String, Object?> toCompactMap() {
    return {
      't': 'pw_store',
      'v': 2,
      'id': storeId,
      'n': storeName,
      'o': ownerName,
      'm': marketName,
      'a': address,
      'c': city,
    };
  }
}

class StoreQrCodec {
  const StoreQrCodec._();

  static String encode(StoreModel store) {
    final storeId = store.id;
    if (storeId == null) {
      throw ArgumentError.value(store, 'store', 'Store id is required.');
    }
    return jsonEncode(
      StoreQrPayload(
        storeId: storeId,
        storeName: store.name,
        ownerName: store.ownerName,
        marketName: store.marketName,
        address: store.address,
        city: store.city,
      ).toCompactMap(),
    );
  }

  static StoreQrPayload decode(String value) {
    final dynamic decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('QR code does not contain store data.');
    }
    final normalized = decoded.map(
      (key, entry) => MapEntry(key, entry is num ? entry.toInt() : entry),
    );
    if (normalized['t'] == 'pw_store') {
      return StoreQrPayload(
        storeId: normalized['id'] as int,
        storeName: normalized['n'] as String,
        ownerName: normalized['o'] as String?,
        marketName: normalized['m'] as String?,
        address: normalized['a'] as String,
        city: normalized['c'] as String?,
      );
    }
    if (normalized['type'] != 'pricewatch_store') {
      throw const FormatException('Unsupported QR payload.');
    }
    return StoreQrPayload.fromMap(normalized);
  }
}
