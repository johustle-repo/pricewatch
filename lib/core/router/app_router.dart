import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_web_shell_screen.dart';
import '../../features/admin/presentation/screens/analytics_screen.dart';
import '../../features/admin/presentation/screens/manage_categories_screen.dart';
import '../../features/admin/presentation/screens/manage_commodities_screen.dart';
import '../../features/admin/presentation/screens/manage_prices_screen.dart';
import '../../features/admin/presentation/screens/manage_reports_screen.dart';
import '../../features/admin/presentation/screens/manage_stores_screen.dart';
import '../../features/admin/presentation/screens/manage_users_screen.dart';
import '../../features/admin/presentation/widgets/admin_page_frame.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/commodities/presentation/screens/category_list_screen.dart';
import '../../features/commodities/presentation/screens/commodity_detail_screen.dart';
import '../../features/commodities/presentation/screens/commodity_list_screen.dart';
import '../../features/display/presentation/screens/lingayen_market_display_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/navigation/presentation/main_navigation_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/change_password_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/reports/presentation/screens/add_report_screen.dart';
import '../../features/reports/presentation/screens/report_detail_screen.dart';
import '../../features/reports/presentation/screens/report_list_screen.dart';
import '../../features/reports/presentation/screens/store_qr_scanner_screen.dart';
import '../../features/stores/presentation/screens/store_detail_screen.dart';
import '../../features/stores/presentation/screens/store_list_screen.dart';
import '../../features/user/presentation/screens/user_module_screen.dart';
import '../../features/watchlist/presentation/screens/watchlist_screen.dart';

class AppRouter {
  AppRouter({required AuthController authController})
    : router = GoRouter(
        initialLocation: '/',
        refreshListenable: authController,
        redirect: (context, state) {
          final currentUser = authController.currentUser;
          final isLanding = state.matchedLocation == '/';
          final isSplash = state.matchedLocation == '/splash';
          final isAuthRoute =
              state.matchedLocation == '/login' ||
              state.matchedLocation == '/register' ||
              state.matchedLocation == '/register/vendor';
          final isAdminRoute = state.matchedLocation.startsWith('/admin');
          final isPublicDisplayRoute =
              isLanding || state.matchedLocation.startsWith('/display');
          final isMainAppShellRoute = _mainAppShellRoutes.contains(
            state.matchedLocation,
          );
          final intendedRoute = state.uri.queryParameters['from'];
          final viewportWidth = MediaQuery.maybeSizeOf(context)?.width ?? 0;
          final useAdminWebWorkspace =
              (currentUser?.isAdmin ?? false) &&
              (kIsWeb || viewportWidth >= adminWebLayoutBreakpoint);

          if (authController.status == AuthStatus.initializing) {
            return (isSplash || isPublicDisplayRoute) ? null : '/splash';
          }

          if (!authController.isAuthenticated) {
            if (isAuthRoute || isPublicDisplayRoute) {
              return null;
            }

            return Uri(
              path: '/login',
              queryParameters: {'from': state.uri.toString()},
            ).toString();
          }

          if (isAuthRoute || isSplash) {
            if (_isSafePostAuthRoute(intendedRoute)) {
              return _resolvePostAuthRoute(
                intendedRoute!,
                useAdminWebWorkspace: useAdminWebWorkspace,
              );
            }
            return useAdminWebWorkspace ? '/admin' : '/modules';
          }

          if (useAdminWebWorkspace && isMainAppShellRoute) {
            return '/admin';
          }

          if (isAdminRoute && !(currentUser?.isAdmin ?? false)) {
            return '/profile';
          }

          return null;
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const LingayenMarketDisplayScreen(),
          ),
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: '/register/vendor',
            redirect: (context, state) => '/register',
          ),
          GoRoute(
            path: '/display/lingayen-market',
            builder: (context, state) => const LingayenMarketDisplayScreen(),
          ),
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return MainNavigationScreen(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/modules',
                    builder: (context, state) => UserModuleScreen(
                      autoOpenAddProduct:
                          state.uri.queryParameters['addProduct'] == '1',
                    ),
                  ),
                  GoRoute(
                    path: '/vendor/products',
                    builder: (context, state) =>
                        const UserModuleScreen(vendorSection: 'products'),
                  ),
                  GoRoute(
                    path: '/vendor/qr',
                    builder: (context, state) =>
                        const UserModuleScreen(vendorSection: 'qr'),
                  ),
                  GoRoute(
                    path: '/categories',
                    builder: (context, state) => const CategoryListScreen(),
                  ),
                  GoRoute(
                    path: '/commodities',
                    builder: (context, state) => CommodityListScreen(
                      initialCategoryId: int.tryParse(
                        state.uri.queryParameters['categoryId'] ?? '',
                      ),
                      initialSearch: state.uri.queryParameters['q'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: '/commodity/:id',
                    builder: (context, state) {
                      final commodityId = int.tryParse(
                        state.pathParameters['id'] ?? '',
                      );
                      if (commodityId == null) {
                        return const _InvalidRouteScreen(label: 'commodity');
                      }
                      return CommodityDetailScreen(commodityId: commodityId);
                    },
                  ),
                  GoRoute(
                    path: '/stores',
                    builder: (context, state) => const StoreListScreen(),
                  ),
                  GoRoute(
                    path: '/store/:id',
                    builder: (context, state) {
                      final storeId = int.tryParse(
                        state.pathParameters['id'] ?? '',
                      );
                      if (storeId == null) {
                        return const _InvalidRouteScreen(label: 'store');
                      }
                      return StoreDetailScreen(storeId: storeId);
                    },
                  ),
                  GoRoute(
                    path: '/notifications',
                    builder: (context, state) => const NotificationsScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (context, state) => const HomeScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/watchlist',
                    builder: (context, state) => const WatchlistScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/reports',
                    builder: (context, state) => const ReportListScreen(),
                  ),
                  GoRoute(
                    path: '/report/new',
                    builder: (context, state) => AddReportScreen(
                      preselectedCommodityId: int.tryParse(
                        state.uri.queryParameters['commodityId'] ?? '',
                      ),
                      preselectedStoreId: int.tryParse(
                        state.uri.queryParameters['storeId'] ?? '',
                      ),
                    ),
                  ),
                  GoRoute(
                    path: '/scan-qr',
                    builder: (context, state) =>
                        const StoreQrScannerScreen(openReportOnScan: true),
                  ),
                  GoRoute(
                    path: '/report/:id',
                    builder: (context, state) {
                      final reportId = int.tryParse(
                        state.pathParameters['id'] ?? '',
                      );
                      if (reportId == null) {
                        return const _InvalidRouteScreen(label: 'report');
                      }
                      return ReportDetailScreen(reportId: reportId);
                    },
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/profile',
                    builder: (context, state) => const ProfileScreen(),
                  ),
                  GoRoute(
                    path: '/profile/edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: '/profile/password',
                    builder: (context, state) => const ChangePasswordScreen(),
                  ),
                ],
              ),
            ],
          ),
          ShellRoute(
            builder: (context, state, child) {
              return AdminWebShellScreen(
                onLogout: authController.logout,
                child: child,
              );
            },
            routes: [
              GoRoute(
                path: '/admin',
                builder: (context, state) => const AdminDashboardScreen(),
              ),
              GoRoute(
                path: '/admin/categories',
                builder: (context, state) => const ManageCategoriesScreen(),
              ),
              GoRoute(
                path: '/admin/commodities',
                builder: (context, state) => const ManageCommoditiesScreen(),
              ),
              GoRoute(
                path: '/admin/users',
                builder: (context, state) => const ManageUsersScreen(),
              ),
              GoRoute(
                path: '/admin/stores',
                builder: (context, state) => const ManageStoresScreen(),
              ),
              GoRoute(
                path: '/admin/prices',
                builder: (context, state) => const ManagePricesScreen(),
              ),
              GoRoute(
                path: '/admin/reports',
                builder: (context, state) => const ManageReportsScreen(),
              ),
              GoRoute(
                path: '/admin/analytics',
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
        ],
      );

  final GoRouter router;

  static const Set<String> _mainAppShellRoutes = {
    '/modules',
    '/home',
    '/categories',
    '/commodities',
    '/stores',
    '/watchlist',
    '/reports',
    '/report/new',
    '/scan-qr',
    '/notifications',
    '/profile',
    '/profile/edit',
    '/profile/password',
  };

  static String _resolvePostAuthRoute(
    String location, {
    required bool useAdminWebWorkspace,
  }) {
    if (!useAdminWebWorkspace) {
      return location;
    }

    return _mainAppShellRoutes.contains(location) ? '/admin' : location;
  }

  static bool _isSafePostAuthRoute(String? location) {
    if (location == null || location.isEmpty) {
      return false;
    }

    return location != '/login' &&
        location != '/register' &&
        location != '/splash' &&
        !location.startsWith('/login?') &&
        !location.startsWith('/register?');
  }
}

class _InvalidRouteScreen extends StatelessWidget {
  const _InvalidRouteScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unavailable')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'This $label link is invalid or no longer available.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
