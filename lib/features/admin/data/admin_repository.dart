import 'package:dio/dio.dart';

import '../../../core/database/cloud_data_service.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/store_qr_codec.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/commodity_model.dart';
import '../../../shared/models/price_entry_model.dart';
import '../../../shared/models/report_model.dart';
import '../../../shared/models/store_model.dart';
import '../../../shared/models/ui_models.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/watchlist_model.dart';

class AdminRepository {
  AdminRepository({
    required CloudDataService cloudDataService,
    required String firebaseApiKey,
  }) : _cloudDataService = cloudDataService,
       _firebaseApiKey = firebaseApiKey;

  final CloudDataService _cloudDataService;
  final String _firebaseApiKey;

  Future<List<CategoryModel>> getCategories() async {
    final rows =
        (await _cloudDataService.getCollection(
            'categories',
          )).map(CategoryModel.fromMap).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return rows;
  }

  Future<void> saveCategory({
    int? id,
    required String name,
    required String icon,
  }) async {
    await _requireAdmin();
    final targetId = id ?? _cloudDataService.generateId();
    final existing = id == null
        ? null
        : await _cloudDataService.getDocument('categories', targetId);
    await _cloudDataService.setDocument('categories', targetId, {
      'id': targetId,
      'name': name.trim(),
      'icon': icon.trim(),
      'created_at': existing?['created_at'] ?? DateTimeUtils.nowIso(),
    });
    await _audit(
      id == null ? 'create' : 'update',
      'category',
      targetId,
      'Saved category ${name.trim()}.',
    );
  }

  Future<void> deleteCategory(int categoryId) async {
    await _requireAdmin();
    final category = await _cloudDataService.getDocument(
      'categories',
      categoryId,
    );
    if (category == null) throw Exception('Category not found.');
    final commodities = await _cloudDataService.getCollection('commodities');
    if (commodities.any((item) => item['category_id'] == categoryId)) {
      throw Exception('Move or delete this category’s commodities first.');
    }
    await _cloudDataService.deleteDocument('categories', categoryId);
    await _audit(
      'delete',
      'category',
      categoryId,
      'Deleted category ${category['name']}.',
    );
  }

  Future<List<CommodityModel>> getCommodities() async {
    final rows =
        (await _cloudDataService.getCollection(
            'commodities',
          )).map(CommodityModel.fromMap).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return rows;
  }

  Future<void> saveCommodity({
    int? id,
    required int categoryId,
    required String name,
    required String description,
    required String unit,
    required double srp,
  }) async {
    await _requireAdmin();
    final targetId = id ?? _cloudDataService.generateId();
    final existing = id == null
        ? null
        : await _cloudDataService.getDocument('commodities', targetId);
    await _cloudDataService.setDocument('commodities', targetId, {
      'id': targetId,
      'category_id': categoryId,
      'name': name.trim(),
      'description': description.trim(),
      'unit': unit.trim(),
      'srp': srp,
      'created_at': existing?['created_at'] ?? DateTimeUtils.nowIso(),
    });
    await _audit(
      id == null ? 'create' : 'update',
      'commodity',
      targetId,
      'Saved commodity ${name.trim()}.',
    );
  }

  Future<void> deleteCommodity(int commodityId) async {
    await _requireAdmin();
    final commodity = await _cloudDataService.getDocument(
      'commodities',
      commodityId,
    );
    if (commodity == null) throw Exception('Commodity not found.');
    for (final collection in const ['price_entries', 'watchlists', 'reports']) {
      final linked = await _cloudDataService.getCollection(collection);
      if (linked.any((item) => item['commodity_id'] == commodityId)) {
        throw Exception(
          'This commodity has linked prices, watchlists, or reports and cannot be deleted.',
        );
      }
    }
    await _cloudDataService.deleteDocument('commodities', commodityId);
    await _audit(
      'delete',
      'commodity',
      commodityId,
      'Deleted commodity ${commodity['name']}.',
    );
  }

  Future<List<StoreModel>> getStores({bool archived = false}) async {
    final rows =
        (await _cloudDataService.getCollection('stores'))
            .map(StoreModel.fromMap)
            .where((item) => item.isArchived == archived)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return rows;
  }

  Future<List<UserModel>> getUsers() async {
    final rows =
        (await _cloudDataService.getCollection(
            'users',
          )).map(UserModel.fromMap).toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
    return rows;
  }

  Future<List<Map<String, Object?>>> getAuditLogs({int limit = 20}) async {
    await _requireAdmin();
    final rows = await _cloudDataService.getCollection('audit_logs');
    rows.sort(
      (a, b) => (b['created_at'] as String? ?? '').compareTo(
        a['created_at'] as String? ?? '',
      ),
    );
    return rows.take(limit).toList();
  }

  Future<void> saveStore({
    int? id,
    required String name,
    required String ownerName,
    int? ownerUserId,
    required String marketName,
    required String address,
    required String city,
  }) async {
    await _requireAdmin();
    final targetId = id ?? _cloudDataService.generateId();
    final existing = id == null
        ? null
        : await _cloudDataService.getDocument('stores', targetId);
    final store = StoreModel(
      id: targetId,
      name: name.trim(),
      ownerName: ownerName.trim(),
      ownerUserId: ownerUserId,
      marketName: marketName.trim(),
      address: address.trim(),
      city: city.trim(),
      qrCode: (existing?['qr_code'] as String?)?.trim(),
      createdAt: (existing?['created_at'] as String?) ?? DateTimeUtils.nowIso(),
    );
    final now = DateTimeUtils.nowIso();
    await _cloudDataService.saveStoreWithOwner(
      storeId: targetId,
      previousOwnerUserId: existing?['owner_user_id'] as int?,
      ownerUserId: ownerUserId,
      storeData: {
        ...store.toMap(),
        'qr_code': StoreQrCodec.encode(store),
        'updated_at': now,
      },
    );
  }

  Future<void> deleteStore(int storeId) async {
    await _cloudDataService.deleteStoreCascade(storeId);
  }

  Future<void> archiveStore(int storeId) async {
    await _requireAdmin();
    final row = await _cloudDataService.getDocument('stores', storeId);
    if (row == null) throw Exception('Store not found.');
    await _cloudDataService.setDocument('stores', storeId, {
      ...row,
      'is_archived': true,
      'archived_at': DateTimeUtils.nowIso(),
    });
    await _audit('archive', 'store', storeId, 'Archived store ${row['name']}.');
  }

  Future<void> restoreStore(int storeId) async {
    await _requireAdmin();
    final row = await _cloudDataService.getDocument('stores', storeId);
    if (row == null) throw Exception('Archived store not found.');
    await _cloudDataService.setDocument('stores', storeId, {
      ...row,
      'is_archived': false,
      'archived_at': null,
    });
    await _audit('restore', 'store', storeId, 'Restored store ${row['name']}.');
  }

  Future<void> saveUser({
    int? id,
    required String fullName,
    required String email,
    required String role,
    int? storeId,
    String? password,
  }) async {
    await _requireAdmin();
    final normalizedEmail = email.trim().toLowerCase();
    final users = await getUsers();
    final duplicate = users.any(
      (item) => item.email == normalizedEmail && item.id != id,
    );
    if (duplicate) {
      throw Exception('An account with that email already exists.');
    }

    final targetId = id ?? _cloudDataService.generateId();
    final existing = id == null
        ? null
        : await _cloudDataService.getDocument('users', targetId);
    var authUid = existing?['auth_uid'] as String?;
    if (id == null) {
      final newPassword = password?.trim() ?? '';
      if (newPassword.length < 6) {
        throw Exception('Enter a password with at least six characters.');
      }
      authUid = await _createFirebaseAuthAccount(
        email: normalizedEmail,
        password: newPassword,
      );
    } else if ((existing?['email'] as String?) != normalizedEmail) {
      throw Exception(
        'Email changes must be completed in Firebase Authentication first.',
      );
    }
    if (authUid == null || authUid.isEmpty) {
      throw Exception('This account is not linked to Firebase Authentication.');
    }
    await _cloudDataService.saveManagedUserProfile(
      userId: targetId,
      authUid: authUid,
      userData: {
        'id': targetId,
        'auth_uid': authUid,
        'full_name': fullName.trim(),
        'email': normalizedEmail,
        'role': role,
        'store_id': role == 'vendor' ? storeId : null,
        'created_at': existing?['created_at'] ?? DateTimeUtils.nowIso(),
      },
    );
    await _cloudDataService.synchronizeVendorStore(
      vendorUserId: targetId,
      vendorName: fullName.trim(),
      previousStoreId: existing?['store_id'] as int?,
      storeId: role == 'vendor' ? storeId : null,
    );
    await _audit(
      id == null ? 'create' : 'update',
      'user',
      targetId,
      'Saved $role account for ${fullName.trim()}.',
    );

    if (id == null) {
      final notificationId = _cloudDataService.generateId();
      await _cloudDataService.setDocument('notifications', notificationId, {
        'id': notificationId,
        'user_id': targetId,
        'title': 'Welcome to PriceWatch',
        'body': role == 'vendor'
            ? 'Your vendor account is ready. You can now access your assigned store data.'
            : 'Your account is ready. Start tracking prices and community reports.',
        'type': 'system',
        'is_read': 0,
        'created_at': DateTimeUtils.nowIso(),
      });
    }
  }

  Future<void> deleteUser(int userId) async {
    await _requireAdmin();
    final row = await _cloudDataService.getDocument('users', userId);
    if (row == null) {
      throw Exception('User not found.');
    }
    final user = UserModel.fromMap(row);
    if (user.isAdmin) {
      throw Exception('Admin accounts cannot be deleted from this screen.');
    }
    await _cloudDataService.deactivateManagedUser(
      userId: userId,
      authUid: user.authUid,
    );
    await _audit('delete', 'user', userId, 'Deleted user ${user.fullName}.');
  }

  Future<String> _createFirebaseAuthAccount({
    required String email,
    required String password,
  }) async {
    try {
      final response = await Dio().post<Map<String, dynamic>>(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp',
        queryParameters: {'key': _firebaseApiKey},
        data: {
          'email': email,
          'password': password,
          'returnSecureToken': false,
        },
      );
      final uid = response.data?['localId'] as String?;
      if (uid == null || uid.isEmpty) {
        throw Exception('Firebase did not return an account identifier.');
      }
      return uid;
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map
          ? ((data['error'] as Map?)?['message'] as String?)
          : null;
      if (message == 'EMAIL_EXISTS') {
        throw Exception(
          'That email already exists in Firebase Authentication.',
        );
      }
      throw Exception(
        message ?? 'Firebase Authentication account creation failed.',
      );
    }
  }

  Future<void> addPriceEntry({
    required int commodityId,
    required int storeId,
    required double price,
  }) async {
    await _requireAdmin();
    final timestamp = DateTimeUtils.nowIso();
    final id = _cloudDataService.generateId();
    await _cloudDataService.setDocument('price_entries', id, {
      'id': id,
      'commodity_id': commodityId,
      'store_id': storeId,
      'price': price,
      'recorded_at': timestamp,
      'source': 'admin',
    });

    final commodityRow = await _cloudDataService.getDocument(
      'commodities',
      commodityId,
    );
    if (commodityRow == null) {
      return;
    }
    final commodity = CommodityModel.fromMap(commodityRow);
    final watchlists = (await _cloudDataService.getCollection('watchlists'))
        .map(WatchlistModel.fromMap)
        .where((item) => item.commodityId == commodityId)
        .toList();

    for (final watch in watchlists) {
      final updatedId = _cloudDataService.generateId();
      await _cloudDataService.setDocument('notifications', updatedId, {
        'id': updatedId,
        'user_id': watch.userId,
        'title': 'Watched item updated',
        'body':
            '${commodity.name} has a new price update: ${AppFormatters.currency(price)}.',
        'type': 'watched_item_updated',
        'is_read': 0,
        'created_at': timestamp,
      });

      if (watch.priceThreshold != null && price > watch.priceThreshold!) {
        final thresholdId = _cloudDataService.generateId();
        await _cloudDataService.setDocument('notifications', thresholdId, {
          'id': thresholdId,
          'user_id': watch.userId,
          'title': 'Price threshold reached',
          'body':
              '${commodity.name} is at ${AppFormatters.currency(price)}, above your alert threshold of ${AppFormatters.currency(watch.priceThreshold!)}.',
          'type': 'price_increase',
          'is_read': 0,
          'created_at': timestamp,
        });
      }
    }
    await _audit(
      'create',
      'price_entry',
      id,
      'Recorded a market price of $price.',
    );
  }

  Future<void> updateLatestPriceEntry({
    required int commodityId,
    required int storeId,
    required double price,
  }) async {
    await _requireAdmin();
    final matches =
        (await _cloudDataService.getCollection('price_entries'))
            .map(PriceEntryModel.fromMap)
            .where(
              (entry) =>
                  entry.commodityId == commodityId && entry.storeId == storeId,
            )
            .toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    if (matches.isEmpty || matches.first.id == null) {
      await addPriceEntry(
        commodityId: commodityId,
        storeId: storeId,
        price: price,
      );
      return;
    }
    await _cloudDataService.setDocument('price_entries', matches.first.id!, {
      'id': matches.first.id,
      'commodity_id': commodityId,
      'store_id': storeId,
      'price': price,
      'recorded_at': DateTimeUtils.nowIso(),
      'source': 'csv',
    });
    await _audit(
      'update',
      'price_entry',
      matches.first.id!,
      'Updated a market price to $price.',
    );
  }

  Future<void> replacePriceEntries({
    required int commodityId,
    required int storeId,
    required double price,
  }) async {
    await _requireAdmin();
    final matches = (await _cloudDataService.getCollection('price_entries'))
        .map(PriceEntryModel.fromMap)
        .where(
          (entry) =>
              entry.commodityId == commodityId && entry.storeId == storeId,
        );
    for (final entry in matches) {
      if (entry.id != null) {
        await _cloudDataService.deleteDocument('price_entries', entry.id!);
      }
    }
    await addPriceEntry(
      commodityId: commodityId,
      storeId: storeId,
      price: price,
    );
  }

  Future<void> deletePriceEntry(int priceEntryId) async {
    await _requireAdmin();
    final row = await _cloudDataService.getDocument(
      'price_entries',
      priceEntryId,
    );
    if (row == null) throw Exception('Price entry not found.');
    await _cloudDataService.deleteDocument('price_entries', priceEntryId);
    await _audit(
      'delete',
      'price_entry',
      priceEntryId,
      'Deleted a price record.',
    );
  }

  Future<List<AdminPriceEntryView>> getPriceEntries() async {
    final entries =
        (await _cloudDataService.getCollection(
            'price_entries',
          )).map(PriceEntryModel.fromMap).toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final commodities = await getCommodities();
    final stores = await getStores();
    return entries.map((entry) {
      final commodity = commodities
          .where((item) => item.id == entry.commodityId)
          .firstOrNull;
      final store = stores
          .where((item) => item.id == entry.storeId)
          .firstOrNull;
      return AdminPriceEntryView(
        id: entry.id ?? 0,
        commodityName: commodity?.name ?? 'Unknown commodity',
        storeName: store?.name ?? 'Unknown store',
        price: entry.price,
        srp: commodity?.srp ?? 0,
        unit: commodity?.unit ?? '',
        recordedAt: entry.recordedAt,
        source: entry.source,
      );
    }).toList();
  }

  Future<List<ReportViewData>> getReports() async {
    final reports =
        (await _cloudDataService.getCollection(
            'reports',
          )).map(ReportModel.fromMap).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final commodities = (await _cloudDataService.getCollection(
      'commodities',
    )).map(CommodityModel.fromMap).toList();
    final stores = (await _cloudDataService.getCollection(
      'stores',
    )).map(StoreModel.fromMap).toList();
    final users = (await _cloudDataService.getCollection(
      'users',
    )).map(UserModel.fromMap).toList();

    return reports
        .map((report) {
          final reportId = report.id;
          if (reportId == null) {
            return null;
          }
          final commodity = commodities
              .where((item) => item.id == report.commodityId)
              .firstOrNull;
          final store = stores
              .where((item) => item.id == report.storeId)
              .firstOrNull;
          final user = users
              .where((item) => item.id == report.userId)
              .firstOrNull;
          return ReportViewData(
            reportId: reportId,
            commodityName: commodity?.name ?? 'Unknown commodity',
            storeName: store?.name ?? 'Unknown store',
            userName: user?.fullName ?? 'Unknown user',
            observedPrice: report.observedPrice,
            srpSnapshot: report.srpSnapshot,
            reason: report.reason,
            photoPath: report.photoPath,
            status: report.status,
            createdAt: report.createdAt,
            updatedAt: report.updatedAt,
          );
        })
        .nonNulls
        .toList();
  }

  Future<void> updateReportStatus({
    required int reportId,
    required String status,
  }) async {
    await _requireAdmin();
    final row = await _cloudDataService.getDocument('reports', reportId);
    if (row == null) {
      throw Exception('Report not found.');
    }
    final report = ReportModel.fromMap(row);
    final now = DateTimeUtils.nowIso();
    await _cloudDataService.setDocument('reports', reportId, {
      ...report.toMap(),
      'status': status,
      'updated_at': now,
    });

    final notificationId = _cloudDataService.generateId();
    await _cloudDataService.setDocument('notifications', notificationId, {
      'id': notificationId,
      'user_id': report.userId,
      'title': 'Report status updated',
      'body': 'Your report is now marked as $status.',
      'type': 'report_status_update',
      'is_read': 0,
      'created_at': now,
    });
    await _audit(
      'status_change',
      'report',
      reportId,
      'Changed report status to $status.',
    );
  }

  Future<void> _requireAdmin() async {
    await _cloudDataService.requireActiveUser(roles: const {'admin'});
  }

  Future<void> _audit(
    String action,
    String entityType,
    int entityId,
    String description,
  ) {
    return _cloudDataService.writeAuditLog(
      action: action,
      entityType: entityType,
      entityId: entityId,
      description: description,
    );
  }

  Future<AdminAnalyticsData> getAnalytics() async {
    final allReports = (await _cloudDataService.getCollection(
      'reports',
    )).map(ReportModel.fromMap).toList();
    final watchlists = (await _cloudDataService.getCollection(
      'watchlists',
    )).map(WatchlistModel.fromMap).toList();
    final stores = (await _cloudDataService.getCollection(
      'stores',
    )).map(StoreModel.fromMap).where((item) => !item.isArchived).toList();
    final activeStoreIds = stores.map((item) => item.id).nonNulls.toSet();
    final reports = allReports
        .where((item) => activeStoreIds.contains(item.storeId))
        .toList();
    final commodities = (await _cloudDataService.getCollection(
      'commodities',
    )).map(CommodityModel.fromMap).toList();
    final categories = (await _cloudDataService.getCollection(
      'categories',
    )).map(CategoryModel.fromMap).toList();
    final priceEntries =
        (await _cloudDataService.getCollection('price_entries'))
            .map(PriceEntryModel.fromMap)
            .where((item) => activeStoreIds.contains(item.storeId))
            .toList();

    final weekAgo = DateTime.now().toUtc().subtract(const Duration(days: 7));
    final latestUpdatesCount = priceEntries
        .where((item) => DateTime.parse(item.recordedAt).isAfter(weekAgo))
        .length;

    final topStoreCounts = <int, int>{};
    for (final report in reports) {
      topStoreCounts.update(
        report.storeId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final topReportedStores =
        topStoreCounts.entries
            .map((entry) {
              final store = stores
                  .where((item) => item.id == entry.key)
                  .firstOrNull;
              if (store == null) {
                return null;
              }
              return TopReportedStore(
                storeName: store.name,
                count: entry.value,
              );
            })
            .nonNulls
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    final latestByStoreCommodity = <String, PriceEntryModel>{};
    final sortedEntries = [...priceEntries]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    for (final entry in sortedEntries) {
      latestByStoreCommodity.putIfAbsent(
        '${entry.storeId}:${entry.commodityId}',
        () => entry,
      );
    }
    final categoryBuckets = <int, List<double>>{};
    for (final entry in latestByStoreCommodity.values) {
      final commodity = commodities
          .where((item) => item.id == entry.commodityId)
          .firstOrNull;
      if (commodity == null) {
        continue;
      }
      categoryBuckets
          .putIfAbsent(commodity.categoryId, () => [])
          .add(entry.price);
    }
    final categoryAverages =
        categoryBuckets.entries
            .map((entry) {
              final category = categories
                  .where((item) => item.id == entry.key)
                  .firstOrNull;
              if (category == null) {
                return null;
              }
              final avg =
                  entry.value.reduce((a, b) => a + b) / entry.value.length;
              return CategoryPriceAverage(
                categoryName: category.name,
                averagePrice: avg,
              );
            })
            .nonNulls
            .toList()
          ..sort((a, b) => a.categoryName.compareTo(b.categoryName));

    final statusCounts = <String, int>{};
    for (final report in reports) {
      statusCounts.update(
        report.status,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final reportsByStore = <int, int>{};
    for (final report in reports) {
      reportsByStore.update(
        report.storeId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final updatesByStore = <int, int>{};
    for (final entry in priceEntries) {
      updatesByStore.update(
        entry.storeId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final locationBuckets = <String, List<StoreModel>>{};
    for (final store in stores) {
      final city = (store.city ?? '').trim();
      final location = city.isEmpty ? 'Unspecified location' : city;
      locationBuckets.putIfAbsent(location, () => []).add(store);
    }
    final locationInsights =
        locationBuckets.entries.map((entry) {
            return MarketLocationInsight(
              location: entry.key,
              storeCount: entry.value.length,
              reportCount: entry.value.fold(
                0,
                (total, store) => total + (reportsByStore[store.id] ?? 0),
              ),
              priceUpdateCount: entry.value.fold(
                0,
                (total, store) => total + (updatesByStore[store.id] ?? 0),
              ),
            );
          }).toList()
          ..sort((a, b) => b.priceUpdateCount.compareTo(a.priceUpdateCount));

    final commodityById = {
      for (final commodity in commodities) commodity.id: commodity,
    };
    final dailyPrices = <DateTime, List<double>>{};
    final dailySrps = <DateTime, List<double>>{};
    var aboveSrpCount = 0;
    for (final entry in priceEntries) {
      final parsed = DateTime.tryParse(entry.recordedAt)?.toLocal();
      final commodity = commodityById[entry.commodityId];
      if (parsed == null || commodity == null) continue;
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      dailyPrices.putIfAbsent(day, () => []).add(entry.price);
      dailySrps.putIfAbsent(day, () => []).add(commodity.srp);
    }
    final trend = dailyPrices.entries.map((entry) {
      final srps = dailySrps[entry.key]!;
      return MarketPriceTrendPoint(
        date: entry.key,
        averagePrice: entry.value.reduce((a, b) => a + b) / entry.value.length,
        averageSrp: srps.reduce((a, b) => a + b) / srps.length,
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
    final recentTrend = trend.length <= 30
        ? trend
        : trend.sublist(trend.length - 30);
    final currentEntries = latestByStoreCommodity.values.toList();
    aboveSrpCount = currentEntries.where((entry) {
      final commodity = commodityById[entry.commodityId];
      return commodity != null && entry.price > commodity.srp;
    }).length;
    final compliantCount = currentEntries.length - aboveSrpCount;
    final staleBoundary = DateTime.now().toUtc().subtract(
      const Duration(days: 7),
    );
    final staleCount = currentEntries.where((entry) {
      final recorded = DateTime.tryParse(entry.recordedAt)?.toUtc();
      return recorded == null || recorded.isBefore(staleBoundary);
    }).length;

    final categoryById = {for (final item in categories) item.id: item};
    final entriesByCommodity = <int, List<PriceEntryModel>>{};
    for (final entry in currentEntries) {
      entriesByCommodity.putIfAbsent(entry.commodityId, () => []).add(entry);
    }
    final commodityMonitoring = entriesByCommodity.entries.map((bucket) {
      final commodity = commodityById[bucket.key]!;
      final values = bucket.value;
      final latest = [...values]
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      final average =
          values.fold<double>(0, (sum, item) => sum + item.price) /
          values.length;
      final latestDate = DateTime.tryParse(latest.first.recordedAt)?.toUtc();
      return CommodityMonitoringInsight(
        commodityName: commodity.name,
        categoryName:
            categoryById[commodity.categoryId]?.name ?? 'Uncategorized',
        unit: commodity.unit,
        averagePrice: average,
        srp: commodity.srp,
        storeCount: values.length,
        lastUpdated: latest.first.recordedAt,
        isStale: latestDate == null || latestDate.isBefore(staleBoundary),
      );
    }).toList()..sort((a, b) => b.variancePercent.compareTo(a.variancePercent));
    final allPrices = currentEntries.map((entry) => entry.price).toList();

    return AdminAnalyticsData(
      totalReports: reports.length,
      pendingReports: reports.where((item) => item.status == 'pending').length,
      reviewedReports: reports
          .where((item) => item.status == 'reviewed')
          .length,
      resolvedReports: reports
          .where((item) => item.status == 'resolved')
          .length,
      watchedItemsCount: watchlists.length,
      latestUpdatesCount: latestUpdatesCount,
      topReportedStores: topReportedStores.take(5).toList(),
      categoryAverages: categoryAverages,
      statusBreakdown:
          statusCounts.entries
              .map(
                (entry) =>
                    StatusBreakdown(status: entry.key, count: entry.value),
              )
              .toList()
            ..sort((a, b) => a.status.compareTo(b.status)),
      locationInsights: locationInsights,
      marketTrend: recentTrend,
      aboveSrpCount: aboveSrpCount,
      highestPrice: allPrices.isEmpty
          ? 0
          : allPrices.reduce((a, b) => a > b ? a : b),
      lowestPrice: allPrices.isEmpty
          ? 0
          : allPrices.reduce((a, b) => a < b ? a : b),
      compliantCount: compliantCount,
      staleCount: staleCount,
      monitoredPriceCount: currentEntries.length,
      commodityMonitoring: commodityMonitoring,
    );
  }
}
