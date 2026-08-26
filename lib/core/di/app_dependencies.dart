import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/admin/data/admin_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/commodities/data/commodity_repository.dart';
import '../../features/display/data/market_display_repository.dart';
import '../../features/home/data/home_repository.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/reports/data/report_repository.dart';
import '../../features/reports/data/vendor_incident_repository.dart';
import '../../features/stores/data/store_repository.dart';
import '../../features/watchlist/data/watchlist_repository.dart';
import '../database/cloud_data_service.dart';
import '../database/database_service.dart';
import '../../firebase_options.dart';

class AppDependencies {
  const AppDependencies({
    required this.cloudDataService,
    required this.databaseService,
    required this.authRepository,
    required this.homeRepository,
    required this.commodityRepository,
    required this.storeRepository,
    required this.marketDisplayRepository,
    required this.watchlistRepository,
    required this.reportRepository,
    required this.vendorIncidentRepository,
    required this.notificationRepository,
    required this.profileRepository,
    required this.adminRepository,
  });

  final CloudDataService cloudDataService;
  final DatabaseService databaseService;
  final AuthRepository authRepository;
  final HomeRepository homeRepository;
  final CommodityRepository commodityRepository;
  final StoreRepository storeRepository;
  final MarketDisplayRepository marketDisplayRepository;
  final WatchlistRepository watchlistRepository;
  final ReportRepository reportRepository;
  final VendorIncidentRepository vendorIncidentRepository;
  final NotificationRepository notificationRepository;
  final ProfileRepository profileRepository;
  final AdminRepository adminRepository;

  static Future<AppDependencies> bootstrap() async {
    final databaseService = DatabaseService.instance;
    await databaseService.initialize();
    final preferences = await SharedPreferences.getInstance();
    final cloudDataService = CloudDataService(
      firestore: FirebaseFirestore.instance,
      preferences: preferences,
    );
    // Legacy seeding is intentionally not performed by the client. Firestore
    // writes are now authorized by Firebase Authentication and security rules.

    return AppDependencies(
      cloudDataService: cloudDataService,
      databaseService: databaseService,
      authRepository: AuthRepository(
        cloudDataService: cloudDataService,
        firebaseAuth: FirebaseAuth.instance,
      ),
      homeRepository: HomeRepository(cloudDataService: cloudDataService),
      commodityRepository: CommodityRepository(
        cloudDataService: cloudDataService,
      ),
      storeRepository: StoreRepository(cloudDataService: cloudDataService),
      marketDisplayRepository: MarketDisplayRepository(
        cloudDataService: cloudDataService,
      ),
      watchlistRepository: WatchlistRepository(
        cloudDataService: cloudDataService,
      ),
      reportRepository: ReportRepository(cloudDataService: cloudDataService),
      vendorIncidentRepository: VendorIncidentRepository(
        cloudDataService: cloudDataService,
      ),
      notificationRepository: NotificationRepository(
        cloudDataService: cloudDataService,
      ),
      profileRepository: ProfileRepository(
        cloudDataService: cloudDataService,
        firebaseAuth: FirebaseAuth.instance,
      ),
      adminRepository: AdminRepository(
        cloudDataService: cloudDataService,
        firebaseApiKey: DefaultFirebaseOptions.currentPlatform.apiKey,
      ),
    );
  }
}
