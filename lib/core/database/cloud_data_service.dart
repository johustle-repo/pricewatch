import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database_service.dart';

class CloudDataService {
  CloudDataService({
    required FirebaseFirestore firestore,
    required SharedPreferences preferences,
  }) : _firestore = firestore,
       _preferences = preferences;

  final FirebaseFirestore _firestore;
  final SharedPreferences _preferences;

  static const String _sessionUserIdKey = 'active_user_id';
  static const String _seedMetaCollection = 'meta';
  static const String _seedMetaDocument = 'app';
  static const String _deletionsCollection = 'deletions';
  static const int _migrationVersion = 5;
  static const String _localMigrationVersionKey = 'cloud_migration_version';
  static const String _lingayenStoreName = 'Lingayen Public Market';
  static const String _lingayenMarketName = 'Lingayen Market';
  static const Set<String> _agriculturalCategoryNames = {
    'rice',
    'eggs',
    'vegetables',
    'fish',
    'meat',
  };

  Future<void> migrateLocalToCloudIfNeeded(
    DatabaseService databaseService,
  ) async {
    final migratedVersion = _preferences.getInt(_localMigrationVersionKey) ?? 0;
    if (migratedVersion >= _migrationVersion) {
      await removeNonAgriculturalCloudData();
      await ensureFreshLingayenMarketDisplayData();
      return;
    }

    final metaRef = _firestore
        .collection(_seedMetaCollection)
        .doc(_seedMetaDocument);
    final cloudMeta = await metaRef.get();
    final cloudSeedVersion = cloudMeta.data()?['seed_version'];
    if (cloudSeedVersion is int && cloudSeedVersion >= _migrationVersion) {
      await _preferences.setInt(_localMigrationVersionKey, _migrationVersion);
      await removeNonAgriculturalCloudData();
      await ensureFreshLingayenMarketDisplayData();
      return;
    }

    final db = await databaseService.database;
    final users = await db.query('users');
    final sessions = await db.query('sessions');
    final categories = await db.query('categories');
    final commodities = await db.query('commodities');
    final stores = await db.query('stores');
    final priceEntries = await db.query('price_entries');
    final watchlists = await db.query('watchlists');
    final reports = await db.query('reports');
    final notifications = await db.query('notifications');

    final batch = _firestore.batch();
    await _seedMissingDocuments(batch, 'users', users);
    await _seedMissingDocuments(batch, 'sessions', sessions);
    await _seedMissingDocuments(batch, 'categories', categories);
    await _seedMissingDocuments(batch, 'commodities', commodities);
    await _seedMissingDocuments(batch, 'stores', stores);
    await _seedMissingDocuments(batch, 'price_entries', priceEntries);
    await _seedMissingDocuments(batch, 'watchlists', watchlists);
    await _seedMissingDocuments(batch, 'reports', reports);
    await _seedMissingDocuments(batch, 'notifications', notifications);
    batch.set(metaRef, {
      'seeded_at': FieldValue.serverTimestamp(),
      'seed_version': _migrationVersion,
      'last_sync_at': FieldValue.serverTimestamp(),
      'collections': [
        'users',
        'sessions',
        'categories',
        'commodities',
        'stores',
        'price_entries',
        'watchlists',
        'reports',
        'notifications',
      ],
    }, SetOptions(merge: true));
    await batch.commit();
    await removeNonAgriculturalCloudData();
    await ensureFreshLingayenMarketDisplayData();
    await _preferences.setInt(_localMigrationVersionKey, _migrationVersion);
  }

  Future<void> removeNonAgriculturalCloudData() async {
    final categories = await getCollection('categories');
    final nonAgriculturalCategoryIds = categories
        .where(
          (row) => !_agriculturalCategoryNames.contains(
            ((row['name'] as String?) ?? '').trim().toLowerCase(),
          ),
        )
        .map((row) => row['id'])
        .whereType<int>()
        .toSet();
    if (nonAgriculturalCategoryIds.isEmpty) {
      return;
    }

    final commodities = await getCollection('commodities');
    final nonAgriculturalCommodityIds = commodities
        .where((row) => nonAgriculturalCategoryIds.contains(row['category_id']))
        .map((row) => row['id'])
        .whereType<int>()
        .toSet();

    final batch = _firestore.batch();
    for (final id in nonAgriculturalCategoryIds) {
      batch.delete(_firestore.collection('categories').doc('$id'));
    }
    for (final id in nonAgriculturalCommodityIds) {
      batch.delete(_firestore.collection('commodities').doc('$id'));
    }

    if (nonAgriculturalCommodityIds.isNotEmpty) {
      await _deleteRowsWhereCommodityId(
        batch,
        collection: 'price_entries',
        commodityIds: nonAgriculturalCommodityIds,
      );
      await _deleteRowsWhereCommodityId(
        batch,
        collection: 'watchlists',
        commodityIds: nonAgriculturalCommodityIds,
      );
      await _deleteRowsWhereCommodityId(
        batch,
        collection: 'reports',
        commodityIds: nonAgriculturalCommodityIds,
      );
    }

    batch.set(
      _firestore.collection(_seedMetaCollection).doc(_seedMetaDocument),
      {
        'seed_version': _migrationVersion,
        'agricultural_cleanup_at': FieldValue.serverTimestamp(),
        'last_sync_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<List<Map<String, Object?>>> getCollection(String name) async {
    final snapshot = await _firestore.collection(name).get();
    return snapshot.docs
        .map((doc) => _normalizeWithDocumentId(doc.data(), doc.id))
        .toList();
  }

  Stream<List<Map<String, Object?>>> watchCollection(String name) {
    return _firestore
        .collection(name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _normalizeWithDocumentId(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<Map<String, Object?>?> getDocument(String collection, int id) async {
    final snapshot = await _firestore.collection(collection).doc('$id').get();
    if (!snapshot.exists) {
      return null;
    }
    return _normalizeWithDocumentId(snapshot.data()!, snapshot.id);
  }

  Future<Map<String, Object?>?> getDocumentByKey(
    String collection,
    String documentId,
  ) async {
    final snapshot = await _firestore
        .collection(collection)
        .doc(documentId)
        .get();
    if (!snapshot.exists) return null;
    return _normalize(snapshot.data()!);
  }

  Future<List<Map<String, Object?>>> getCollectionWhere(
    String collection, {
    required String field,
    required Object value,
  }) async {
    final snapshot = await _firestore
        .collection(collection)
        .where(field, isEqualTo: value)
        .get();
    return snapshot.docs
        .map((doc) => _normalizeWithDocumentId(doc.data(), doc.id))
        .toList();
  }

  Future<void> createAuthenticatedUserProfile({
    required String authUid,
    required int userId,
    required Map<String, Object?> userData,
  }) async {
    final batch = _firestore.batch();
    batch.set(_firestore.collection('users').doc('$userId'), userData);
    batch.set(_firestore.collection('access_control').doc(authUid), {
      'uid': authUid,
      'user_id': userId,
      'role': 'user',
      'store_id': null,
      'active': true,
      'created_at': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> saveManagedUserProfile({
    required int userId,
    required String authUid,
    required Map<String, Object?> userData,
  }) async {
    await requireActiveUser(roles: const {'admin'});
    final batch = _firestore.batch();
    batch.set(_firestore.collection('users').doc('$userId'), userData);
    batch.set(
      _firestore.collection('access_control').doc(authUid),
      {
        'uid': authUid,
        'user_id': userId,
        'role': userData['role'],
        'store_id': userData['store_id'],
        'active': true,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> deactivateManagedUser({
    required int userId,
    String? authUid,
  }) async {
    await requireActiveUser(roles: const {'admin'});
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('users').doc('$userId'));
    if (authUid != null && authUid.isNotEmpty) {
      batch.set(
        _firestore.collection('access_control').doc(authUid),
        {'active': false, 'disabled_at': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> deactivateOwnAccount({
    required int userId,
    required String authUid,
    required Map<String, Object?> userData,
  }) async {
    final batch = _firestore.batch();
    batch.set(_firestore.collection('users').doc('$userId'), userData);
    batch.set(
      _firestore.collection('access_control').doc(authUid),
      {'active': false, 'disabled_at': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<int?> claimLegacyProfile({
    required String authUid,
    required String email,
  }) async {
    final matches = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (matches.docs.isEmpty) return null;
    final profile = matches.docs.first;
    final data = profile.data();
    final userId = data['id'];
    if (userId is! int) return null;
    final batch = _firestore.batch();
    batch.update(profile.reference, {
      'auth_uid': authUid,
      'password_hash': FieldValue.delete(),
    });
    batch.set(_firestore.collection('access_control').doc(authUid), {
      'uid': authUid,
      'user_id': userId,
      'role': data['role'],
      'store_id': data['store_id'],
      'active': true,
      'claimed_at': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return userId;
  }

  Future<void> setDocument(
    String collection,
    int id,
    Map<String, Object?> data,
  ) async {
    await _firestore.collection(collection).doc('$id').set(data);
  }

  Future<void> deleteDocument(String collection, int id) async {
    final batch = _firestore.batch();
    _addDeletionToBatch(batch, collection, '$id');
    batch.delete(_firestore.collection(collection).doc('$id'));
    await batch.commit();
  }

  Future<void> deleteOwnedDocument(String collection, int id) async {
    await _firestore.collection(collection).doc('$id').delete();
  }

  int generateId() => DateTime.now().microsecondsSinceEpoch;

  Future<void> ensureFreshLingayenMarketDisplayData() async {
    final stores = await getCollection('stores');
    final lingayenStores = stores.where(_isLingayenStore).toList();
    if (lingayenStores.isEmpty) {
      return;
    }

    final storeIds = lingayenStores
        .map((row) => row['id'])
        .whereType<int>()
        .toSet();
    if (storeIds.isEmpty) {
      return;
    }

    final commodities = await getCollection('commodities');
    final priceEntries = await getCollection('price_entries');
    final lingayenEntries = priceEntries
        .where((row) => storeIds.contains(row['store_id']))
        .toList();
    if (lingayenEntries.isEmpty) {
      return;
    }

    final latestByCommodity = <int, Map<String, Object?>>{};
    DateTime? latestRecordedAt;
    for (final row in lingayenEntries) {
      final commodityId = row['commodity_id'];
      final recordedAt = row['recorded_at'];
      if (commodityId is! int || recordedAt is! String) {
        continue;
      }

      final recordedDate = DateTime.tryParse(recordedAt);
      if (recordedDate != null &&
          (latestRecordedAt == null ||
              recordedDate.isAfter(latestRecordedAt))) {
        latestRecordedAt = recordedDate;
      }

      final current = latestByCommodity[commodityId];
      final currentRecordedAt = current?['recorded_at'];
      if (current == null ||
          (currentRecordedAt is String &&
              recordedAt.compareTo(currentRecordedAt) > 0)) {
        latestByCommodity[commodityId] = row;
      }
    }

    final now = DateTime.now().toUtc();
    if (latestRecordedAt == null ||
        now.difference(latestRecordedAt.toUtc()) < const Duration(days: 1)) {
      return;
    }

    final preferredStoreId = _preferredLingayenStoreId(lingayenStores);
    if (preferredStoreId == null) {
      return;
    }

    final batch = _firestore.batch();
    var wroteAny = false;
    for (final commodity in commodities) {
      final commodityId = commodity['id'];
      if (commodityId is! int) {
        continue;
      }

      final latest = latestByCommodity[commodityId];
      final latestPrice = latest?['price'];
      final fallbackSrp = commodity['srp'];
      final price = latestPrice is num
          ? latestPrice.toDouble()
          : fallbackSrp is num
          ? fallbackSrp.toDouble()
          : null;
      if (price == null) {
        continue;
      }

      final id = generateId() + commodityId;
      batch.set(_firestore.collection('price_entries').doc('$id'), {
        'id': id,
        'commodity_id': commodityId,
        'store_id': preferredStoreId,
        'price': price,
        'recorded_at': now.toIso8601String(),
        'source': 'lingayen-display-refresh',
      });
      wroteAny = true;
    }

    if (!wroteAny) {
      return;
    }

    batch.set(
      _firestore.collection(_seedMetaCollection).doc(_seedMetaDocument),
      {
        'lingayen_refreshed_at': FieldValue.serverTimestamp(),
        'last_sync_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<int?> getActiveUserId() async {
    return _preferences.getInt(_sessionUserIdKey);
  }

  Future<void> setActiveUserId(int userId) async {
    await _preferences.setInt(_sessionUserIdKey, userId);
  }

  Future<void> clearActiveUserId() async {
    await _preferences.remove(_sessionUserIdKey);
  }

  Future<Map<String, Object?>> requireActiveUser({Set<String>? roles}) async {
    final userId = await getActiveUserId();
    if (userId == null) {
      throw Exception('Your session has expired. Please sign in again.');
    }
    final user = await getDocument('users', userId);
    if (user == null) {
      await clearActiveUserId();
      throw Exception('Your account is no longer available.');
    }
    final role = (user['role'] as String? ?? '').trim().toLowerCase();
    if (roles != null && !roles.contains(role)) {
      throw Exception('You are not authorized to perform this action.');
    }
    return user;
  }

  Future<void> writeAuditLog({
    required String action,
    required String entityType,
    required int entityId,
    required String description,
    Map<String, Object?> details = const {},
  }) async {
    final actor = await requireActiveUser(roles: const {'admin'});
    final id = generateId();
    await setDocument('audit_logs', id, {
      'id': id,
      'actor_user_id': actor['id'],
      'actor_name': actor['full_name'],
      'actor_email': actor['email'],
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'description': description,
      'details': details,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> saveStoreWithOwner({
    required int storeId,
    required Map<String, Object?> storeData,
    int? previousOwnerUserId,
    int? ownerUserId,
  }) async {
    final actor = await requireActiveUser(roles: const {'admin'});
    Map<String, Object?>? owner;
    if (ownerUserId != null) {
      owner = await getDocument('users', ownerUserId);
      if (owner == null || owner['role'] != 'vendor') {
        throw Exception('The selected owner must be an active vendor account.');
      }
    }
    final assignedUsers = await _firestore
        .collection('users')
        .where('store_id', isEqualTo: storeId)
        .get();
    final batch = _firestore.batch();
    batch.set(_firestore.collection('stores').doc('$storeId'), storeData);
    for (final assigned in assignedUsers.docs) {
      if (assigned.id != '$ownerUserId') {
        batch.update(assigned.reference, {'store_id': null});
      }
    }
    if (previousOwnerUserId != null && previousOwnerUserId != ownerUserId) {
      batch.update(_firestore.collection('users').doc('$previousOwnerUserId'), {
        'store_id': null,
      });
    }
    if (ownerUserId != null) {
      final previousStoreId = owner?['store_id'];
      if (previousStoreId is int && previousStoreId != storeId) {
        final oldStore = await getDocument('stores', previousStoreId);
        if (oldStore != null) {
          batch.update(
            _firestore.collection('stores').doc('$previousStoreId'),
            {'owner_user_id': null, 'owner_name': ''},
          );
        }
      }
      batch.update(_firestore.collection('users').doc('$ownerUserId'), {
        'store_id': storeId,
      });
    }
    _addAuditToBatch(
      batch,
      actor: actor,
      action: 'save',
      entityType: 'store',
      entityId: storeId,
      description: 'Saved store ${storeData['name']}.',
    );
    await batch.commit();
  }

  Future<void> synchronizeVendorStore({
    required int vendorUserId,
    required String vendorName,
    int? previousStoreId,
    int? storeId,
  }) async {
    await requireActiveUser(roles: const {'admin'});
    final batch = _firestore.batch();
    if (previousStoreId != null && previousStoreId != storeId) {
      final previous = await getDocument('stores', previousStoreId);
      if (previous?['owner_user_id'] == vendorUserId) {
        batch.update(_firestore.collection('stores').doc('$previousStoreId'), {
          'owner_user_id': null,
          'owner_name': '',
        });
      }
    }
    if (storeId != null) {
      final store = await getDocument('stores', storeId);
      if (store == null) throw Exception('Assigned store not found.');
      final assignedUsers = await _firestore
          .collection('users')
          .where('store_id', isEqualTo: storeId)
          .get();
      for (final assigned in assignedUsers.docs) {
        if (assigned.id != '$vendorUserId') {
          batch.update(assigned.reference, {'store_id': null});
        }
      }
      batch.update(_firestore.collection('stores').doc('$storeId'), {
        'owner_user_id': vendorUserId,
        'owner_name': vendorName,
      });
    }
    await batch.commit();
  }

  Future<void> deleteStoreCascade(int storeId) async {
    final actor = await requireActiveUser(roles: const {'admin'});
    final store = await getDocument('stores', storeId);
    if (store == null) throw Exception('Store not found.');
    final users = await _firestore
        .collection('users')
        .where('store_id', isEqualTo: storeId)
        .get();
    final prices = await _firestore
        .collection('price_entries')
        .where('store_id', isEqualTo: storeId)
        .get();
    final reports = await _firestore
        .collection('reports')
        .where('store_id', isEqualTo: storeId)
        .get();
    if (users.size + prices.size * 2 + reports.size * 2 + 3 > 490) {
      throw Exception(
        'This store has too many linked records for one safe deletion. Archive it instead.',
      );
    }
    final batch = _firestore.batch();
    for (final user in users.docs) {
      batch.update(user.reference, {'store_id': null});
    }
    for (final snapshot in [prices, reports]) {
      for (final doc in snapshot.docs) {
        _addDeletionToBatch(batch, doc.reference.parent.id, doc.id);
        batch.delete(doc.reference);
      }
    }
    _addDeletionToBatch(batch, 'stores', '$storeId');
    batch.delete(_firestore.collection('stores').doc('$storeId'));
    _addAuditToBatch(
      batch,
      actor: actor,
      action: 'delete',
      entityType: 'store',
      entityId: storeId,
      description: 'Deleted store ${store['name']} and its linked records.',
    );
    await batch.commit();
  }

  void _addDeletionToBatch(WriteBatch batch, String collection, String id) {
    batch.set(
      _firestore.collection(_deletionsCollection).doc('${collection}_$id'),
      {
        'collection': collection,
        'record_id': int.tryParse(id) ?? id,
        'deleted_at': FieldValue.serverTimestamp(),
      },
    );
  }

  void _addAuditToBatch(
    WriteBatch batch, {
    required Map<String, Object?> actor,
    required String action,
    required String entityType,
    required int entityId,
    required String description,
  }) {
    final id = generateId();
    batch.set(_firestore.collection('audit_logs').doc('$id'), {
      'id': id,
      'actor_user_id': actor['id'],
      'actor_name': actor['full_name'],
      'actor_email': actor['email'],
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'description': description,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> _seedMissingDocuments(
    WriteBatch batch,
    String collection,
    List<Map<String, Object?>> rows,
  ) async {
    final existingSnapshot = await _firestore.collection(collection).get();
    final existingIds = existingSnapshot.docs.map((doc) => doc.id).toSet();
    final deletionSnapshot = await _firestore
        .collection(_deletionsCollection)
        .where('collection', isEqualTo: collection)
        .get();
    final deletedIds = deletionSnapshot.docs
        .map((doc) => doc.data()['record_id'])
        .whereType<int>()
        .toSet();
    for (final row in rows) {
      final id = row['id'];
      if (id is! int) {
        continue;
      }
      if (deletedIds.contains(id)) continue;
      final documentId = '$id';
      if (existingIds.contains(documentId)) {
        continue;
      }
      batch.set(_firestore.collection(collection).doc(documentId), row);
    }
  }

  Future<void> _deleteRowsWhereCommodityId(
    WriteBatch batch, {
    required String collection,
    required Set<int> commodityIds,
  }) async {
    final snapshot = await _firestore.collection(collection).get();
    for (final doc in snapshot.docs) {
      final commodityId = doc.data()['commodity_id'];
      if (commodityId is int && commodityIds.contains(commodityId)) {
        batch.delete(doc.reference);
      }
    }
  }

  bool _isLingayenStore(Map<String, Object?> row) {
    return (row['name'] as String?)?.toLowerCase() ==
            _lingayenStoreName.toLowerCase() ||
        (row['market_name'] as String?)?.toLowerCase() ==
            _lingayenMarketName.toLowerCase();
  }

  int? _preferredLingayenStoreId(List<Map<String, Object?>> stores) {
    for (final store in stores) {
      if ((store['name'] as String?)?.toLowerCase() ==
          _lingayenStoreName.toLowerCase()) {
        return store['id'] as int?;
      }
    }
    return stores.first['id'] as int?;
  }

  Map<String, Object?> _normalize(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _normalizeValue(value)));
  }

  Map<String, Object?> _normalizeWithDocumentId(
    Map<String, dynamic> data,
    String documentId,
  ) {
    final normalized = _normalize(data);
    normalized['id'] ??= int.tryParse(documentId);
    return normalized;
  }

  Object? _normalizeValue(Object? value) {
    if (value is Timestamp) {
      return value.toDate().toUtc().toIso8601String();
    }
    if (value is num) {
      return value;
    }
    if (value is bool || value is String || value == null) {
      return value;
    }
    if (value is Map<String, dynamic>) {
      return _normalize(value);
    }
    if (value is Iterable) {
      return value.map(_normalizeValue).toList();
    }
    return value.toString();
  }
}
