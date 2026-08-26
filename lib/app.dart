import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/app_dependencies.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/presentation/controllers/admin_controller.dart';
import 'features/admin/data/admin_repository.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/commodities/presentation/controllers/commodity_controller.dart';
import 'features/commodities/data/commodity_repository.dart';
import 'features/display/data/market_display_repository.dart';
import 'features/home/data/home_repository.dart';
import 'features/home/presentation/controllers/home_controller.dart';
import 'features/notifications/data/notification_repository.dart';
import 'features/notifications/presentation/controllers/notification_controller.dart';
import 'features/profile/data/profile_repository.dart';
import 'features/profile/presentation/controllers/profile_controller.dart';
import 'features/reports/data/report_repository.dart';
import 'features/reports/presentation/controllers/report_controller.dart';
import 'features/reports/data/vendor_incident_repository.dart';
import 'features/reports/presentation/controllers/vendor_incident_controller.dart';
import 'features/stores/data/store_repository.dart';
import 'features/stores/presentation/controllers/store_controller.dart';
import 'features/watchlist/data/watchlist_repository.dart';
import 'features/watchlist/presentation/controllers/watchlist_controller.dart';

class PriceWatchApp extends StatelessWidget {
  const PriceWatchApp({
    super.key,
    required this.dependencies,
    required this.authController,
  });

  final AppDependencies dependencies;
  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    final router = AppRouter(authController: authController).router;

    return MultiProvider(
      providers: [
        Provider<AppDependencies>.value(value: dependencies),
        Provider<AuthRepository>.value(value: dependencies.authRepository),
        Provider<HomeRepository>.value(value: dependencies.homeRepository),
        Provider<CommodityRepository>.value(
          value: dependencies.commodityRepository,
        ),
        Provider<StoreRepository>.value(value: dependencies.storeRepository),
        Provider<MarketDisplayRepository>.value(
          value: dependencies.marketDisplayRepository,
        ),
        Provider<WatchlistRepository>.value(
          value: dependencies.watchlistRepository,
        ),
        Provider<ReportRepository>.value(value: dependencies.reportRepository),
        Provider<VendorIncidentRepository>.value(
          value: dependencies.vendorIncidentRepository,
        ),
        Provider<NotificationRepository>.value(
          value: dependencies.notificationRepository,
        ),
        Provider<ProfileRepository>.value(
          value: dependencies.profileRepository,
        ),
        Provider<AdminRepository>.value(value: dependencies.adminRepository),
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider(
          create: (_) =>
              HomeController(homeRepository: dependencies.homeRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CommodityController(
            commodityRepository: dependencies.commodityRepository,
            watchlistRepository: dependencies.watchlistRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              StoreController(storeRepository: dependencies.storeRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => WatchlistController(
            watchlistRepository: dependencies.watchlistRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ReportController(reportRepository: dependencies.reportRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => VendorIncidentController(
            repository: dependencies.vendorIncidentRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationController(
            notificationRepository: dependencies.notificationRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileController(
            profileRepository: dependencies.profileRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              AdminController(adminRepository: dependencies.adminRepository),
        ),
      ],
      child: MaterialApp.router(
        title: 'PriceWatch',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        scrollBehavior: const AppScrollBehavior(),
        routerConfig: router,
      ),
    );
  }
}
