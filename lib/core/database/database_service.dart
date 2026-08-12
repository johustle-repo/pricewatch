import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../constants/app_constants.dart';
import '../utils/password_hasher.dart';

class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();

  factory DatabaseService() => instance;

  Database? _database;
  bool _factoryConfigured = false;

  Future<Database> get database async => initialize();

  Future<Database> initialize() async {
    if (_database != null) {
      return _database!;
    }

    await _configureDatabaseFactory();
    final databasePath = await _resolveDatabasePath();

    _database = await openDatabase(
      databasePath,
      version: AppConstants.databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _runMigrations(db, oldVersion, newVersion);
      },
    );

    await _seedIfNeeded(_database!);
    await _removeNonAgriculturalData(_database!);
    await _ensureDemoVendorAccount(_database!);
    await _ensureLingayenMarketDisplayData(_database!);
    return _database!;
  }

  Future<void> _configureDatabaseFactory() async {
    if (_factoryConfigured) {
      return;
    }

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _factoryConfigured = true;
  }

  Future<String> _resolveDatabasePath() async {
    if (kIsWeb) {
      return AppConstants.databaseName;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    return p.join(documentsDirectory.path, AppConstants.databaseName);
  }

  Future<void> _runMigrations(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    for (var version = oldVersion + 1; version <= newVersion; version++) {
      switch (version) {
        case 1:
          await _createSchema(db);
        case 2:
          await _migrateToV2(db);
        case 3:
          await _removeNonAgriculturalData(db);
      }
    }
  }

  Future<void> _migrateToV2(Database db) async {
    try {
      await db.execute(
        'ALTER TABLE users ADD COLUMN store_id INTEGER REFERENCES stores(id) ON DELETE SET NULL;',
      );
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE stores ADD COLUMN qr_code TEXT;');
    } catch (_) {}
  }

  Future<void> _removeNonAgriculturalData(Database db) async {
    const allowedCategories = ['rice', 'eggs', 'vegetables', 'fish', 'meat'];
    final placeholders = List.filled(allowedCategories.length, '?').join(', ');
    await db.transaction((txn) async {
      final categoryRows = await txn.rawQuery(
        'SELECT id FROM categories WHERE lower(name) NOT IN ($placeholders);',
        allowedCategories,
      );
      final categoryIds = categoryRows
          .map((row) => row['id'])
          .whereType<int>()
          .toList();
      if (categoryIds.isEmpty) {
        return;
      }

      final categoryPlaceholders = List.filled(
        categoryIds.length,
        '?',
      ).join(', ');
      final commodityRows = await txn.rawQuery(
        'SELECT id FROM commodities WHERE category_id IN ($categoryPlaceholders);',
        categoryIds,
      );
      final commodityIds = commodityRows
          .map((row) => row['id'])
          .whereType<int>()
          .toList();
      if (commodityIds.isNotEmpty) {
        final commodityPlaceholders = List.filled(
          commodityIds.length,
          '?',
        ).join(', ');
        await txn.rawDelete(
          'DELETE FROM price_entries WHERE commodity_id IN ($commodityPlaceholders);',
          commodityIds,
        );
        await txn.rawDelete(
          'DELETE FROM watchlists WHERE commodity_id IN ($commodityPlaceholders);',
          commodityIds,
        );
        await txn.rawDelete(
          'DELETE FROM reports WHERE commodity_id IN ($commodityPlaceholders);',
          commodityIds,
        );
        await txn.rawDelete(
          'DELETE FROM commodities WHERE id IN ($commodityPlaceholders);',
          commodityIds,
        );
      }
      await txn.rawDelete(
        'DELETE FROM categories WHERE id IN ($categoryPlaceholders);',
        categoryIds,
      );
    });
  }

  Future<void> _createSchema(Database db) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user',
        store_id INTEGER,
        created_at TEXT NOT NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        login_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      );
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT,
        created_at TEXT NOT NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS commodities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        unit TEXT NOT NULL,
        srp REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE RESTRICT
      );
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS stores(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        market_name TEXT,
        address TEXT NOT NULL,
        city TEXT,
        qr_code TEXT,
        created_at TEXT NOT NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS price_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        commodity_id INTEGER NOT NULL,
        store_id INTEGER NOT NULL,
        price REAL NOT NULL,
        recorded_at TEXT NOT NULL,
        source TEXT DEFAULT 'manual',
        FOREIGN KEY(commodity_id) REFERENCES commodities(id) ON DELETE CASCADE,
        FOREIGN KEY(store_id) REFERENCES stores(id) ON DELETE CASCADE
      );
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS watchlists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        commodity_id INTEGER NOT NULL,
        price_threshold REAL,
        created_at TEXT NOT NULL,
        UNIQUE(user_id, commodity_id),
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(commodity_id) REFERENCES commodities(id) ON DELETE CASCADE
      );
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS reports(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        commodity_id INTEGER NOT NULL,
        store_id INTEGER NOT NULL,
        observed_price REAL NOT NULL,
        srp_snapshot REAL NOT NULL,
        reason TEXT NOT NULL,
        photo_path TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(commodity_id) REFERENCES commodities(id) ON DELETE CASCADE,
        FOREIGN KEY(store_id) REFERENCES stores(id) ON DELETE CASCADE
      );
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        type TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      );
    ''');

    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_sessions_user_active ON sessions(user_id, is_active);',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_price_entries_commodity_store_time ON price_entries(commodity_id, store_id, recorded_at);',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_watchlists_user ON watchlists(user_id);',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);',
    );

    await batch.commit(noResult: true);
  }

  Future<void> _seedIfNeeded(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM users;'),
    );
    if ((count ?? 0) > 0) {
      return;
    }

    final now = DateTime.now().toUtc();
    final createdAt = now.toIso8601String();

    await db.transaction((txn) async {
      final batch = txn.batch();

      final users = [
        {
          'full_name': 'Maria Santos',
          'email': AppConstants.demoUserEmail,
          'password_hash': PasswordHasher.hashPassword(
            AppConstants.demoUserPassword,
            email: AppConstants.demoUserEmail,
          ),
          'role': 'user',
          'store_id': null,
          'created_at': createdAt,
        },
        {
          'full_name': 'Admin Reyes',
          'email': AppConstants.demoAdminEmail,
          'password_hash': PasswordHasher.hashPassword(
            AppConstants.demoAdminPassword,
            email: AppConstants.demoAdminEmail,
          ),
          'role': 'admin',
          'store_id': null,
          'created_at': createdAt,
        },
        {
          'full_name': 'Vendor Cruz',
          'email': AppConstants.demoVendorEmail,
          'password_hash': PasswordHasher.hashPassword(
            AppConstants.demoVendorPassword,
            email: AppConstants.demoVendorEmail,
          ),
          'role': 'vendor',
          'store_id': 1,
          'created_at': createdAt,
        },
      ];

      for (final user in users) {
        batch.insert('users', user);
      }

      final categories = [
        {'name': 'Rice', 'icon': 'rice'},
        {'name': 'Eggs', 'icon': 'eggs'},
        {'name': 'Vegetables', 'icon': 'vegetables'},
        {'name': 'Fish', 'icon': 'fish'},
        {'name': 'Meat', 'icon': 'meat'},
      ];

      for (final category in categories) {
        batch.insert('categories', {...category, 'created_at': createdAt});
      }

      final commodities = [
        _commodity(
          1,
          'Premium Rice',
          'Premium-grade well-milled rice.',
          'kg',
          52,
        ),
        _commodity(
          1,
          'Regular Milled Rice',
          'Reliable everyday rice.',
          'kg',
          45,
        ),
        _commodity(
          2,
          'Chicken Eggs Medium',
          'Fresh medium-sized eggs.',
          'dozen',
          96,
        ),
        _commodity(2, 'Chicken Eggs Large', 'Fresh large eggs.', 'dozen', 108),
        _commodity(
          2,
          'Duck Eggs',
          'Duck eggs commonly used for local dishes.',
          'dozen',
          120,
        ),
        _commodity(3, 'Tomato', 'Locally sourced ripe tomatoes.', 'kg', 82),
        _commodity(3, 'Onion', 'Red onions for daily cooking.', 'kg', 130),
        _commodity(3, 'Potato', 'Fresh potatoes for home kitchens.', 'kg', 95),
        _commodity(4, 'Tilapia', 'Freshwater tilapia.', 'kg', 180),
        _commodity(4, 'Galunggong', 'Round scad fish sold fresh.', 'kg', 210),
        _commodity(
          4,
          'Bangus',
          'Milkfish with daily market supply.',
          'kg',
          240,
        ),
        _commodity(5, 'Pork Liempo', 'Pork belly cuts.', 'kg', 380),
        _commodity(5, 'Beef Brisket', 'Lean beef brisket.', 'kg', 420),
        _commodity(5, 'Chicken Breast', 'Boneless chicken breast.', 'kg', 220),
      ];

      for (final commodity in commodities) {
        batch.insert('commodities', {
          'category_id': commodity['category_id'],
          'name': commodity['name'],
          'description': commodity['description'],
          'unit': commodity['unit'],
          'srp': commodity['srp'],
          'created_at': createdAt,
        });
      }

      final stores = [
        _store(
          'Central Public Market',
          'Central Market',
          'P. Burgos Street',
          'Quezon City',
        ),
        _store('Green Basket Mart', 'Green Basket', 'Mabini Avenue', 'Makati'),
        _store(
          'Riverside Wet Market',
          'Riverside Market',
          'Riverbank Road',
          'Pasig',
        ),
        _store('Sunrise Grocer', 'Sunrise', 'Boni Drive', 'Mandaluyong'),
        _store(
          'Bayanihan Coop Store',
          'Bayanihan Coop',
          'Aguinaldo Highway',
          'Bacoor',
        ),
        _store(
          'Fresh Catch Depot',
          'Fresh Catch',
          'Seaside Boulevard',
          'Paranaque',
        ),
        _store(
          'Metro Family Store',
          'Metro Family',
          'Commonwealth Avenue',
          'Quezon City',
        ),
        _store(
          'Neighborhood Essentials',
          'Essentials',
          'JP Rizal Street',
          'Taguig',
        ),
      ];

      for (final store in stores) {
        batch.insert('stores', {...store, 'created_at': createdAt});
      }

      const dayOffsets = [14, 7, 1];
      for (
        var commodityIndex = 0;
        commodityIndex < commodities.length;
        commodityIndex++
      ) {
        final srp = (commodities[commodityIndex]['srp'] as num).toDouble();
        final commodityId = commodityIndex + 1;
        for (var storeOffset = 0; storeOffset < 4; storeOffset++) {
          final storeId = ((commodityIndex + storeOffset) % stores.length) + 1;
          for (var dateIndex = 0; dateIndex < dayOffsets.length; dateIndex++) {
            final multiplier =
                0.9 + (((commodityIndex + storeOffset + dateIndex) % 9) * 0.04);
            batch.insert('price_entries', {
              'commodity_id': commodityId,
              'store_id': storeId,
              'price': _roundPrice(srp * multiplier),
              'recorded_at': now
                  .subtract(Duration(days: dayOffsets[dateIndex]))
                  .toIso8601String(),
              'source': dateIndex == 2 ? 'seed-latest' : 'seed-history',
            });
          }
        }
      }

      final watchlists = [
        {
          'user_id': 1,
          'commodity_id': 1,
          'price_threshold': 55.0,
          'created_at': createdAt,
        },
        {
          'user_id': 1,
          'commodity_id': 12,
          'price_threshold': 390.0,
          'created_at': createdAt,
        },
        {
          'user_id': 1,
          'commodity_id': 8,
          'price_threshold': 100.0,
          'created_at': createdAt,
        },
        {
          'user_id': 2,
          'commodity_id': 10,
          'price_threshold': 225.0,
          'created_at': createdAt,
        },
      ];

      for (final watch in watchlists) {
        batch.insert('watchlists', watch);
      }

      final reportDates = [
        now.subtract(const Duration(days: 4)),
        now.subtract(const Duration(days: 3)),
        now.subtract(const Duration(days: 2)),
        now.subtract(const Duration(days: 1)),
        now.subtract(const Duration(hours: 16)),
      ];

      final reports = [
        _report(
          userId: 1,
          commodityId: 1,
          storeId: 1,
          observedPrice: 67,
          srpSnapshot: 52,
          reason: 'Rice was being sold far above the posted SRP.',
          photoPath: 'reports/rice_counter_001.jpg',
          status: 'pending',
          createdAt: reportDates[0].toIso8601String(),
        ),
        _report(
          userId: 1,
          commodityId: 7,
          storeId: 3,
          observedPrice: 165,
          srpSnapshot: 130,
          reason: 'Onions were overpriced and no price board was visible.',
          photoPath: null,
          status: 'reviewed',
          createdAt: reportDates[1].toIso8601String(),
        ),
        _report(
          userId: 1,
          commodityId: 12,
          storeId: 5,
          observedPrice: 430,
          srpSnapshot: 380,
          reason:
              'Pork liempo price increased sharply against nearby stall prices.',
          photoPath: 'reports/pork_liempo_002.jpg',
          status: 'resolved',
          createdAt: reportDates[2].toIso8601String(),
        ),
        _report(
          userId: 1,
          commodityId: 8,
          storeId: 2,
          observedPrice: 118,
          srpSnapshot: 95,
          reason: 'Potato price seemed above the usual range in the area.',
          photoPath: null,
          status: 'pending',
          createdAt: reportDates[3].toIso8601String(),
        ),
        _report(
          userId: 2,
          commodityId: 10,
          storeId: 6,
          observedPrice: 260,
          srpSnapshot: 210,
          reason:
              'Fish price was significantly higher than other markets nearby.',
          photoPath: null,
          status: 'reviewed',
          createdAt: reportDates[4].toIso8601String(),
        ),
      ];

      for (final report in reports) {
        batch.insert('reports', report);
      }

      final notifications = [
        _notification(
          1,
          'Price threshold reached',
          'Premium Rice is now above your alert threshold.',
          'price_increase',
          now.subtract(const Duration(hours: 9)).toIso8601String(),
        ),
        _notification(
          1,
          'Report reviewed',
          'Your onion report is now under review by the admin.',
          'report_status_update',
          now.subtract(const Duration(hours: 7)).toIso8601String(),
        ),
        _notification(
          1,
          'Watched item updated',
          'Pork Liempo received a new market price update.',
          'watched_item_updated',
          now.subtract(const Duration(hours: 5)).toIso8601String(),
        ),
        _notification(
          1,
          'Report resolved',
          'Your Pork Liempo report has been marked as resolved.',
          'report_status_update',
          now.subtract(const Duration(hours: 3)).toIso8601String(),
        ),
        _notification(
          2,
          'Admin demo ready',
          'Use the admin dashboard to review seeded reports and analytics.',
          'system',
          now.subtract(const Duration(hours: 2)).toIso8601String(),
        ),
      ];

      for (final notification in notifications) {
        batch.insert('notifications', notification);
      }

      await batch.commit(noResult: true);
    });
  }

  Future<void> _ensureLingayenMarketDisplayData(Database db) async {
    final now = DateTime.now().toUtc();

    await db.transaction((txn) async {
      final existingStore = await txn.query(
        'stores',
        columns: ['id'],
        where: 'LOWER(name) = LOWER(?) OR LOWER(market_name) = LOWER(?)',
        whereArgs: ['Lingayen Public Market', 'Lingayen Market'],
        limit: 1,
      );

      final storeId = existingStore.isNotEmpty
          ? existingStore.first['id'] as int
          : await txn.insert('stores', {
              'name': 'Lingayen Public Market',
              'market_name': 'Lingayen Market',
              'address': 'Maramba Boulevard, Poblacion',
              'city': 'Lingayen, Pangasinan',
              'created_at': now.toIso8601String(),
            });

      final commodityRows = await txn.query(
        'commodities',
        columns: ['id', 'name', 'srp'],
        orderBy: 'category_id ASC, name ASC',
      );

      if (commodityRows.isEmpty) {
        return;
      }

      final existingPriceRows = await txn.query(
        'price_entries',
        columns: ['commodity_id'],
        where: 'store_id = ?',
        whereArgs: [storeId],
      );
      final existingCommodityIds = existingPriceRows
          .map((row) => row['commodity_id'] as int)
          .toSet();

      if (existingCommodityIds.length == commodityRows.length) {
        return;
      }

      final batch = txn.batch();
      const historyOffsets = [
        Duration(days: 2, hours: 5),
        Duration(days: 1, hours: 2),
        Duration(hours: 3, minutes: 30),
      ];

      for (final row in commodityRows) {
        final commodityId = row['id'] as int;
        if (existingCommodityIds.contains(commodityId)) {
          continue;
        }

        final commodityName = row['name'] as String;
        final srp = (row['srp'] as num).toDouble();
        final history = _lingayenDisplayHistoryPrices(
          commodityName: commodityName,
          srp: srp,
        );

        for (var index = 0; index < history.length; index++) {
          batch.insert('price_entries', {
            'commodity_id': commodityId,
            'store_id': storeId,
            'price': history[index],
            'recorded_at': now
                .subtract(historyOffsets[index])
                .toIso8601String(),
            'source': index == history.length - 1
                ? 'lingayen-display-latest'
                : 'lingayen-display-history',
          });
        }
      }

      await batch.commit(noResult: true);
    });
  }

  Future<void> _ensureDemoVendorAccount(Database db) async {
    final existing = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [AppConstants.demoVendorEmail],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return;
    }

    final store = await db.query(
      'stores',
      columns: ['id'],
      orderBy: 'id ASC',
      limit: 1,
    );
    final storeId = store.isNotEmpty ? store.first['id'] as int : null;

    await db.insert('users', {
      'full_name': 'Vendor Cruz',
      'email': AppConstants.demoVendorEmail,
      'password_hash': PasswordHasher.hashPassword(
        AppConstants.demoVendorPassword,
        email: AppConstants.demoVendorEmail,
      ),
      'role': 'vendor',
      'store_id': storeId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static List<double> _lingayenDisplayHistoryPrices({
    required String commodityName,
    required double srp,
  }) {
    final override = _lingayenPriceOverrides[commodityName];
    if (override != null) {
      return override;
    }

    final baseline = _roundPrice(srp * 1.01);
    return [
      _roundPrice(baseline * 0.97),
      _roundPrice(baseline * 0.99),
      baseline,
    ];
  }

  static const Map<String, List<double>> _lingayenPriceOverrides = {
    'Premium Rice': [53.5, 54.0, 55.0],
    'Regular Milled Rice': [45.0, 46.0, 46.5],
    'Chicken Eggs Medium': [97.0, 98.0, 99.0],
    'Chicken Eggs Large': [109.0, 110.0, 111.0],
    'Duck Eggs': [122.0, 123.0, 124.0],
    'Tomato': [79.5, 81.0, 83.0],
    'Onion': [128.0, 132.0, 134.0],
    'Potato': [92.0, 94.0, 95.5],
    'Tilapia': [176.0, 180.0, 184.0],
    'Galunggong': [214.0, 218.0, 220.0],
    'Bangus': [236.0, 241.0, 244.0],
    'Pork Liempo': [382.0, 388.0, 392.0],
    'Beef Brisket': [420.0, 424.0, 428.0],
    'Chicken Breast': [218.0, 222.0, 224.0],
  };

  static Map<String, Object?> _commodity(
    int categoryId,
    String name,
    String description,
    String unit,
    double srp,
  ) {
    return {
      'category_id': categoryId,
      'name': name,
      'description': description,
      'unit': unit,
      'srp': srp,
    };
  }

  static Map<String, Object?> _store(
    String name,
    String marketName,
    String address,
    String city,
  ) {
    return {
      'name': name,
      'market_name': marketName,
      'address': address,
      'city': city,
    };
  }

  static Map<String, Object?> _report({
    required int userId,
    required int commodityId,
    required int storeId,
    required double observedPrice,
    required double srpSnapshot,
    required String reason,
    required String? photoPath,
    required String status,
    required String createdAt,
  }) {
    return {
      'user_id': userId,
      'commodity_id': commodityId,
      'store_id': storeId,
      'observed_price': observedPrice,
      'srp_snapshot': srpSnapshot,
      'reason': reason,
      'photo_path': photoPath,
      'status': status,
      'created_at': createdAt,
      'updated_at': createdAt,
    };
  }

  static Map<String, Object?> _notification(
    int userId,
    String title,
    String body,
    String type,
    String createdAt,
  ) {
    return {
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': 0,
      'created_at': createdAt,
    };
  }

  static double _roundPrice(double value) {
    return (value * 100).round() / 100;
  }
}
