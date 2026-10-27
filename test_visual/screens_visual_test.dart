// Visual audit: renders the real app against an in-memory Firestore and
// captures every main screen at phone, tablet and desktop widths in light and
// dark mode, logging any layout overflow.
//
// Run:
//   PW_FIXTURE=<fixture.json> PW_FONTS=<dir with Poppins-*.ttf> \
//   flutter test test_visual/screens_visual_test.dart --update-goldens
import 'dart:convert';
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pricewatch_apk/app.dart';
import 'package:pricewatch_apk/core/database/cloud_data_service.dart';
import 'package:pricewatch_apk/core/database/database_service.dart';
import 'package:pricewatch_apk/core/di/app_dependencies.dart';
import 'package:pricewatch_apk/core/theme/theme_controller.dart';
import 'package:pricewatch_apk/features/admin/data/admin_repository.dart';
import 'package:pricewatch_apk/features/auth/data/auth_repository.dart';
import 'package:pricewatch_apk/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pricewatch_apk/features/commodities/data/commodity_repository.dart';
import 'package:pricewatch_apk/features/display/data/market_display_repository.dart';
import 'package:pricewatch_apk/features/home/data/home_repository.dart';
import 'package:pricewatch_apk/features/notifications/data/notification_repository.dart';
import 'package:pricewatch_apk/features/profile/data/profile_repository.dart';
import 'package:pricewatch_apk/features/reports/data/report_repository.dart';
import 'package:pricewatch_apk/features/reports/data/vendor_incident_repository.dart';
import 'package:pricewatch_apk/features/stores/data/store_repository.dart';
import 'package:pricewatch_apk/features/watchlist/data/watchlist_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sizes = {
  'phone': Size(390, 844),
  'tablet': Size(820, 1180),
  'desktop': Size(1440, 900),
};

final _issues = <String>[];

Future<void> _loadFonts() async {
  final fontDir = Platform.environment['PW_FONTS'];
  if (fontDir == null) return;
  Future<ByteData> read(String path) async =>
      ByteData.sublistView(await File(path).readAsBytes());
  const weights = {
    'Poppins_300': 'Light',
    'Poppins_regular': 'Regular',
    'Poppins': 'Regular',
    'Poppins_500': 'Medium',
    'Poppins_600': 'SemiBold',
    'Poppins_700': 'Bold',
    'Poppins_800': 'ExtraBold',
    'Poppins_900': 'Black',
  };
  for (final entry in weights.entries) {
    await (FontLoader(
      entry.key,
    )..addFont(read('$fontDir/Poppins-${entry.value}.ttf'))).load();
  }
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final material = '$flutterRoot/bin/cache/artifacts/material_fonts';
    await (FontLoader(
      'MaterialIcons',
    )..addFont(read('$material/materialicons-regular.otf'))).load();
    await (FontLoader('Roboto')
          ..addFont(read('$material/roboto-regular.ttf'))
          ..addFont(read('$material/roboto-bold.ttf')))
        .load();
  }
}

Future<FakeFirebaseFirestore> _seed() async {
  final firestore = FakeFirebaseFirestore();
  final fixture =
      jsonDecode(File(Platform.environment['PW_FIXTURE']!).readAsStringSync())
          as Map<String, dynamic>;
  for (final collection in fixture.entries) {
    for (final row in (collection.value as List).cast<Map<String, dynamic>>()) {
      final data = Map<String, dynamic>.from(row)..remove('documentId');
      await firestore
          .collection(collection.key)
          .doc(row['documentId'] as String)
          .set(data);
    }
  }
  final stores = (fixture['stores'] as List).cast<Map<String, dynamic>>();
  final stallId = stores.firstWhere(
    (store) => store['name'] == 'Sample Stall 01',
  )['id'];
  final commodities = (fixture['commodities'] as List)
      .cast<Map<String, dynamic>>();
  int commodityId(String name) =>
      commodities.firstWhere((item) => item['name'] == name)['id'] as int;

  const createdAt = '2026-09-01T00:00:00.000Z';
  final accounts = [
    (1, 'uid-admin', 'Admin Reyes', 'admin@example.com', 'admin', null),
    (2, 'uid-user', 'Maria Santos', 'user@example.com', 'user', null),
    (3, 'uid-vendor', 'Vendor Cruz', 'vendor@example.com', 'vendor', stallId),
  ];
  for (final (id, uid, name, email, role, storeId) in accounts) {
    await firestore.collection('users').doc('$id').set({
      'id': id,
      'full_name': name,
      'email': email,
      'auth_uid': uid,
      'role': role,
      'store_id': storeId,
      'created_at': createdAt,
    });
    await firestore.collection('access_control').doc(uid).set({
      'uid': uid,
      'user_id': id,
      'role': role,
      'store_id': storeId,
      'active': true,
    });
  }
  await firestore.collection('stores').doc('$stallId').update({
    'owner_user_id': 3,
    'owner_name': 'Vendor Cruz',
  });
  var watchId = 9000;
  for (final (name, threshold) in [
    ('Bangus (Large)', 225.0),
    ('Tilapia', null),
    ('Chicken Eggs Medium', null),
  ]) {
    watchId++;
    await firestore.collection('watchlists').doc('$watchId').set({
      'id': watchId,
      'user_id': 2,
      'commodity_id': commodityId(name),
      'price_threshold': threshold,
      'created_at': createdAt,
    });
  }
  return firestore;
}

AppDependencies _dependencies(
  FakeFirebaseFirestore firestore,
  MockFirebaseAuth auth,
  SharedPreferences preferences,
) {
  final cloud = CloudDataService(
    firestore: firestore,
    preferences: preferences,
  );
  return AppDependencies(
    cloudDataService: cloud,
    databaseService: DatabaseService.instance,
    authRepository: AuthRepository(cloudDataService: cloud, firebaseAuth: auth),
    homeRepository: HomeRepository(cloudDataService: cloud),
    commodityRepository: CommodityRepository(cloudDataService: cloud),
    storeRepository: StoreRepository(cloudDataService: cloud),
    marketDisplayRepository: MarketDisplayRepository(cloudDataService: cloud),
    watchlistRepository: WatchlistRepository(cloudDataService: cloud),
    reportRepository: ReportRepository(cloudDataService: cloud),
    vendorIncidentRepository: VendorIncidentRepository(cloudDataService: cloud),
    notificationRepository: NotificationRepository(cloudDataService: cloud),
    profileRepository: ProfileRepository(
      cloudDataService: cloud,
      firebaseAuth: auth,
    ),
    adminRepository: AdminRepository(
      cloudDataService: cloud,
      firebaseApiKey: 'test',
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _capture(
  WidgetTester tester, {
  required String role,
  required List<String> routes,
  String? uid,
  String? email,
  Set<String> sizes = const {'phone', 'tablet', 'desktop'},
}) async {
  for (final sizeName in sizes) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      tester.view.physicalSize = _sizes[sizeName]!;
      tester.view.devicePixelRatio = 1;
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final firestore = await tester.runAsync(_seed);
      final auth = MockFirebaseAuth(
        signedIn: uid != null,
        mockUser: uid == null ? null : MockUser(uid: uid, email: email),
      );
      final dependencies = _dependencies(firestore!, auth, preferences);
      final authController = AuthController(
        authRepository: dependencies.authRepository,
      );
      await tester.runAsync(authController.initialize);

      await tester.pumpWidget(
        PriceWatchApp(
          dependencies: dependencies,
          authController: authController,
          themeController: ThemeController(initialMode: mode),
        ),
      );
      await _settle(tester);

      for (final route in routes) {
        final context = tester.element(find.byType(Scaffold).first);
        GoRouter.of(context).go(route);
        await _settle(tester);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await _settle(tester);

        final label =
            '${role}_${route.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '')}'
            '_${sizeName}_${mode.name}';
        final name = label.replaceAll('__', '_root_');
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          final message = details.exceptionAsString().split('\n').first;
          final source = details.informationCollector == null
              ? ''
              : details.informationCollector!()
                    .map((node) => node.toString())
                    .firstWhere(
                      (text) => text.contains('lib/'),
                      orElse: () => '',
                    )
                    .replaceAll(RegExp(r'file:///.*?pricewatch_apk/'), '')
                    .split('\n')
                    .firstWhere(
                      (line) => line.contains('lib/'),
                      orElse: () => '',
                    )
                    .trim();
          _issues.add('$name: $message $source');
        };
        try {
          await expectLater(
            find.byType(PriceWatchApp),
            matchesGoldenFile('goldens/$name.png'),
          );
        } finally {
          FlutterError.onError = previous;
        }
        final exception = tester.takeException();
        if (exception != null) {
          _issues.add('$name: ${exception.toString().split('\n').first}');
        }
      }

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }
  }
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadFonts();
  });

  tearDownAll(() {
    final report = _issues.toSet().toList()..sort();
    File('test_visual/issues.txt').writeAsStringSync(report.join('\n'));
    // ignore: avoid_print
    print('VISUAL ISSUES (${report.length}):\n${report.join('\n')}');
  });

  // Overflow errors are collected in issues.txt instead of failing the run.
  final originalOnError = FlutterError.onError;
  setUp(() {
    FlutterError.onError = (details) {
      final message = details.exceptionAsString().split('\n').first;
      _issues.add('${details.library}: $message');
    };
  });
  tearDown(() => FlutterError.onError = originalOnError);

  testWidgets('public screens', (tester) async {
    await _capture(
      tester,
      role: 'public',
      routes: ['/', '/login', '/register'],
    );
  });

  testWidgets('community user screens', (tester) async {
    await _capture(
      tester,
      role: 'user',
      uid: 'uid-user',
      email: 'user@example.com',
      routes: [
        '/home',
        '/commodities',
        '/commodities?categoryId=4',
        '/commodities?categoryId=1',
        '/watchlist',
        '/stores',
        '/profile',
        '/notifications',
        '/reports',
      ],
    );
  });

  testWidgets('admin screens', (tester) async {
    await _capture(
      tester,
      role: 'admin',
      uid: 'uid-admin',
      email: 'admin@example.com',
      sizes: const {'tablet', 'desktop'},
      routes: [
        '/admin',
        '/admin/categories',
        '/admin/commodities',
        '/admin/prices',
        '/admin/analytics',
      ],
    );
  });

  testWidgets('guide', (tester) async {
    for (final sizeName in ['phone', 'desktop']) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        tester.view.physicalSize = _sizes[sizeName]!;
        tester.view.devicePixelRatio = 1;
        // ignore: invalid_use_of_visible_for_testing_member
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final firestore = await tester.runAsync(_seed);
        final dependencies = _dependencies(
          firestore!,
          MockFirebaseAuth(),
          preferences,
        );
        final authController = AuthController(
          authRepository: dependencies.authRepository,
        );
        await tester.runAsync(authController.initialize);
        await tester.pumpWidget(
          PriceWatchApp(
            dependencies: dependencies,
            authController: authController,
            themeController: ThemeController(initialMode: mode),
          ),
        );
        await _settle(tester);
        GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/login');
        await _settle(tester);
        await tester.tap(find.byTooltip('PriceWatch guide').first);
        await _settle(tester);
        await expectLater(
          find.byType(PriceWatchApp),
          matchesGoldenFile('goldens/guide_start_${sizeName}_${mode.name}.png'),
        );
        await tester.tap(find.text('Prices'));
        await _settle(tester);
        await expectLater(
          find.byType(PriceWatchApp),
          matchesGoldenFile(
            'goldens/guide_prices_${sizeName}_${mode.name}.png',
          ),
        );
        final exception = tester.takeException();
        if (exception != null) {
          _issues.add(
            'guide_$sizeName: ${exception.toString().split('\n').first}',
          );
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('vendor screens', (tester) async {
    await _capture(
      tester,
      role: 'vendor',
      uid: 'uid-vendor',
      email: 'vendor@example.com',
      routes: ['/modules'],
    );
  });
}
