import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../admin/presentation/widgets/admin_page_frame.dart';
import '../../../shared/widgets/app_shell_menu_button.dart';
import '../../../shared/widgets/app_seal_badge.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final isVendor = user?.isVendor ?? false;
    final useDark = AppColors.isDark(context);
    final navSurface = AppColors.surfaceFor(
      context,
    ).withValues(alpha: useDark ? 0.94 : 0.92);
    final navBorder = AppColors.borderFor(context);
    final navShadow = AppColors.shadowFor(context).withValues(alpha: 0.22);
    final currentLocation = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri.path;
    final items = isVendor
        ? [
            const _ShellNavItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              branchIndex: 0,
              route: '/modules',
            ),
            const _ShellNavItem(
              icon: Icons.inventory_2_rounded,
              label: 'Products & Prices',
              route: '/vendor/products',
            ),
            const _ShellNavItem(
              icon: Icons.assignment_rounded,
              label: 'Reports',
              route: '/reports',
              matchPrefixes: ['/report/'],
            ),
            const _ShellNavItem(
              icon: Icons.qr_code_2_rounded,
              label: 'Store QR',
              route: '/vendor/qr',
            ),
            const _ShellNavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              branchIndex: 4,
              route: '/profile',
              matchPrefixes: ['/profile/'],
            ),
          ]
        : [
            const _ShellNavItem(
              icon: Icons.apps_rounded,
              label: 'Modules',
              branchIndex: 0,
              route: '/modules',
            ),
            const _ShellNavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              branchIndex: 1,
              route: '/home',
            ),
            const _ShellNavItem(
              icon: Icons.inventory_2_rounded,
              label: 'Products',
              route: '/commodities',
              matchPrefixes: ['/commodity/', '/categories'],
            ),
            const _ShellNavItem(
              icon: Icons.storefront_rounded,
              label: 'Stores',
              route: '/stores',
              matchPrefixes: ['/store/'],
            ),
            const _ShellNavItem(
              icon: Icons.gpp_bad_rounded,
              label: 'Vendor Incidents',
              route: '/incidents',
              matchPrefixes: ['/incident/'],
            ),
            const _ShellNavItem(
              icon: Icons.bookmark_rounded,
              label: 'Watchlist',
              branchIndex: 2,
              route: '/watchlist',
            ),
            const _ShellNavItem(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan QR',
              branchIndex: 3,
              route: '/scan-qr',
            ),
            const _ShellNavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              branchIndex: 4,
              route: '/profile',
              matchPrefixes: ['/profile/'],
            ),
          ];
    final size = MediaQuery.sizeOf(context);
    final useRailLayout = size.width >= 1180 && size.height >= 720;
    final useVendorWebShell =
        isVendor && size.width >= adminWebLayoutBreakpoint;
    final useCommunityWebShell =
        !isVendor && size.width >= adminWebLayoutBreakpoint;
    // StatefulNavigationShell owns nested Navigators with global keys. Keeping
    // an outgoing copy alive in AnimatedSwitcher duplicates that navigator
    // render tree during route changes. On web this races MouseTracker and can
    // leave the destination blank with `_debugDuringDeviceUpdate` assertions.
    // Render the shell directly; individual pages may animate their own local
    // content without duplicating the navigation hierarchy.
    final Widget shellContent = navigationShell;

    if (useVendorWebShell) {
      return _VendorWebShell(
        items: items,
        currentIndex: navigationShell.currentIndex,
        currentLocation: currentLocation,
        userName: user?.fullName ?? 'PriceWatch vendor',
        roleLabel: _roleLabel(user?.role),
        onNotifications: () => context.go('/notifications'),
        onLogout: () => _logout(context),
        onTap: (item) => _goToItem(context, navigationShell, item),
        child: shellContent,
      );
    }

    if (useCommunityWebShell) {
      return _VendorWebShell(
        communityMode: true,
        items: items,
        currentIndex: navigationShell.currentIndex,
        currentLocation: currentLocation,
        userName: user?.fullName ?? 'PriceWatch user',
        roleLabel: _roleLabel(user?.role),
        onNotifications: () => context.go('/notifications'),
        onPublicView: () => context.go('/'),
        onLogout: () => _logout(context),
        onTap: (item) => _goToItem(context, navigationShell, item),
        child: shellContent,
      );
    }

    if (useRailLayout) {
      return Scaffold(
        body: SafeArea(
          minimum: const EdgeInsets.only(right: 18),
          child: Row(
            children: [
              _WideNavigationRail(
                items: items,
                userName: user?.fullName ?? 'PriceWatch user',
                roleLabel: _roleLabel(user?.role),
                isVendor: isVendor,
                currentIndex: navigationShell.currentIndex,
                currentLocation: currentLocation,
                onLogout: () => _logout(context),
                onTap: (item) => _goToItem(context, navigationShell, item),
              ),
              const SizedBox(width: 18),
              Expanded(child: shellContent),
            ],
          ),
        ),
      );
    }

    final scaffoldKey = GlobalKey<ScaffoldState>();
    final showMobileBar = size.width < 720;

    final mobileScaffold = Scaffold(
      key: scaffoldKey,
      drawer: _MobileNavigationDrawer(
        items: items,
        userName: user?.fullName ?? 'PriceWatch user',
        roleLabel: _roleLabel(user?.role),
        isVendor: isVendor,
        currentIndex: navigationShell.currentIndex,
        currentLocation: currentLocation,
        navSurface: navSurface,
        navBorder: navBorder,
        navShadow: navShadow,
        onLogout: () => _logout(context),
        onTap: (item) {
          Navigator.of(context).pop();
          _goToItem(context, navigationShell, item);
        },
      ),
      body: AppShellScope(
        openDrawer: () => scaffoldKey.currentState?.openDrawer(),
        child: shellContent,
      ),
    );

    if (!showMobileBar) {
      return mobileScaffold;
    }

    return ColoredBox(
      color: AppColors.backgroundFor(context),
      child: SafeArea(child: mobileScaffold),
    );
  }

  static String _roleLabel(String? role) {
    return switch (role) {
      'vendor' => 'Vendor workspace',
      'admin' => 'Admin workspace',
      _ => 'Community workspace',
    };
  }

  static Future<void> _logout(BuildContext context) async {
    await context.read<AuthController>().logout();
    if (context.mounted) {
      context.go('/login');
    }
  }

  static void _goToItem(
    BuildContext context,
    StatefulNavigationShell navigationShell,
    _ShellNavItem item,
  ) {
    // Post-frame callbacks may run alongside MouseTracker's own annotation
    // refresh. Move the route mutation to the next event-loop turn instead,
    // after the complete pointer-device update has returned.
    Future<void>.delayed(Duration.zero, () {
      if (!context.mounted) return;
      final branchIndex = item.branchIndex;
      if (branchIndex != null && item.route == null) {
        navigationShell.goBranch(
          branchIndex,
          initialLocation: branchIndex == navigationShell.currentIndex,
        );
        return;
      }

      context.go(item.route ?? '/modules');
    });
  }
}

class _ShellNavItem {
  const _ShellNavItem({
    required this.icon,
    required this.label,
    this.branchIndex,
    this.route,
    this.matchPrefixes = const [],
  });

  final IconData icon;
  final String label;
  final int? branchIndex;
  final String? route;
  final List<String> matchPrefixes;

  bool isSelected(String currentLocation, int currentIndex) {
    final route = this.route;
    if (route != null && currentLocation == route) {
      return true;
    }
    if (matchPrefixes.any(currentLocation.startsWith)) {
      return true;
    }
    return route == null && branchIndex == currentIndex;
  }
}

class _MobileNavigationDrawer extends StatelessWidget {
  const _MobileNavigationDrawer({
    required this.items,
    required this.userName,
    required this.roleLabel,
    required this.isVendor,
    required this.currentIndex,
    required this.currentLocation,
    required this.navSurface,
    required this.navBorder,
    required this.navShadow,
    required this.onLogout,
    required this.onTap,
  });

  final List<_ShellNavItem> items;
  final String userName;
  final String roleLabel;
  final bool isVendor;
  final int currentIndex;
  final String currentLocation;
  final Color navSurface;
  final Color navBorder;
  final Color navShadow;
  final Future<void> Function() onLogout;
  final ValueChanged<_ShellNavItem> onTap;

  @override
  Widget build(BuildContext context) {
    final drawerItems = items.where((item) => item.label != 'Modules').toList();
    return Drawer(
      backgroundColor: AppColors.backgroundFor(context),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: navSurface,
            border: Border(right: BorderSide(color: navBorder)),
            boxShadow: [
              BoxShadow(
                color: navShadow,
                blurRadius: 24,
                offset: const Offset(8, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradientFor(context),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.glowStrong,
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const AppSealBadge(size: 42, padding: 3, showFrame: false),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PriceWatch',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  itemCount: drawerItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = drawerItems[index];
                    final selected = item.isSelected(
                      currentLocation,
                      currentIndex,
                    );
                    return _RailDestinationTile(
                      icon: item.icon,
                      label: item.label,
                      selected: selected,
                      onTap: () => onTap(item),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: _WorkspaceIdentityCard(
                  isVendor: isVendor,
                  onLogout: onLogout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VendorWebShell extends StatelessWidget {
  const _VendorWebShell({
    this.communityMode = false,
    required this.items,
    required this.currentIndex,
    required this.currentLocation,
    required this.userName,
    required this.roleLabel,
    required this.onNotifications,
    this.onPublicView,
    required this.onLogout,
    required this.onTap,
    required this.child,
  });

  final bool communityMode;
  final List<_ShellNavItem> items;
  final int currentIndex;
  final String currentLocation;
  final String userName;
  final String roleLabel;
  final VoidCallback onNotifications;
  final VoidCallback? onPublicView;
  final Future<void> Function() onLogout;
  final ValueChanged<_ShellNavItem> onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final compactSidebar = width < 1200;
        final compactHeight = height < 760;
        final sidebarWidth = compactSidebar
            ? (compactHeight ? 80.0 : 92.0)
            : (compactHeight ? 232.0 : 256.0);

        return Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.backgroundAltFor(context),
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: sidebarWidth,
                    padding: EdgeInsets.fromLTRB(
                      compactSidebar ? 10 : 14,
                      compactHeight ? 14 : 18,
                      compactSidebar ? 10 : 14,
                      compactHeight ? 14 : 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradientFor(context),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowFor(
                            context,
                          ).withValues(alpha: 0.28),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _VendorWebBrand(
                          compact: compactSidebar,
                          userName: userName,
                        ),
                        if (communityMode && !compactSidebar) ...[
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'COMMUNITY MENU',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: .54),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                  ),
                            ),
                          ),
                        ],
                        SizedBox(
                          height: communityMode && !compactSidebar
                              ? AppSpacing.md
                              : compactHeight
                              ? AppSpacing.lg
                              : AppSpacing.xl,
                        ),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              for (final item in items)
                                _VendorShellItem(
                                  icon: item.icon,
                                  label: item.label,
                                  compact: compactSidebar,
                                  selected: item.isSelected(
                                    currentLocation,
                                    currentIndex,
                                  ),
                                  onTap: () => onTap(item),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: compactHeight ? AppSpacing.sm : AppSpacing.md,
                        ),
                        if (communityMode && onPublicView != null) ...[
                          _CommunityPublicViewAction(
                            compact: compactSidebar,
                            onPressed: onPublicView!,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        _VendorShellLogout(
                          compact: compactSidebar,
                          onPressed: onLogout,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: communityMode
                            ? AppColors.backgroundAltFor(context)
                            : AppColors.surfaceFor(context),
                        border: Border.all(
                          color: AppColors.borderFor(
                            context,
                          ).withValues(alpha: 0.8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowFor(
                              context,
                            ).withValues(alpha: 0.16),
                            blurRadius: 32,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (communityMode)
                            _CommunityTopBar(
                              title: _titleForLocation(
                                currentLocation,
                                currentIndex,
                              ),
                              userName: userName,
                              compact: width < 1160,
                              onNotifications: onNotifications,
                              onPublicView: onPublicView,
                            )
                          else
                            _VendorTopBar(
                              title: _titleForLocation(
                                currentLocation,
                                currentIndex,
                              ),
                              userName: userName,
                              roleLabel: roleLabel,
                              compact: width < 1100,
                              onNotifications: onNotifications,
                            ),
                          Expanded(child: child),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _titleForLocation(String location, int index) {
    if (location == '/modules') return 'Community Dashboard';
    if (location == '/home') return 'Market Overview';
    if (location == '/commodities' || location.startsWith('/commodity/')) {
      return 'Products & Prices';
    }
    if (location == '/categories') return 'Product Categories';
    if (location == '/stores' || location.startsWith('/store/')) {
      return 'Markets & Stores';
    }
    if (location == '/watchlist') return 'My Watchlist';
    if (location == '/scan-qr') return 'Scan Store QR';
    if (location == '/vendor/products') return 'Products & Prices';
    if (location == '/vendor/qr') return 'Store QR';
    if (location == '/notifications') return 'Notifications';
    if (location == '/reports' || location.startsWith('/report/')) {
      return 'Reports';
    }
    if (location == '/incidents' || location.startsWith('/incident/')) {
      return 'Vendor Incidents';
    }
    if (location == '/profile' || location.startsWith('/profile/')) {
      return 'Profile';
    }
    return switch (index) {
      0 => 'Dashboard',
      _ => 'Vendor Workspace',
    };
  }
}

class _VendorWebBrand extends StatelessWidget {
  const _VendorWebBrand({required this.compact, required this.userName});

  final bool compact;
  final String userName;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Center(
        child: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const AppSealBadge(size: 28, padding: 2, showFrame: false),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const AppSealBadge(size: 24, padding: 2, showFrame: false),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PriceWatch',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityPublicViewAction extends StatelessWidget {
  const _CommunityPublicViewAction({
    required this.compact,
    required this.onPressed,
  });

  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.monitor_rounded, color: Colors.white, size: 19),
            if (!compact) ...[
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Public price board',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_outward_rounded,
                color: Colors.white70,
                size: 17,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _CommunityTopBar extends StatelessWidget {
  const _CommunityTopBar({
    required this.title,
    required this.userName,
    required this.compact,
    required this.onNotifications,
    required this.onPublicView,
  });

  final String title;
  final String userName;
  final bool compact;
  final VoidCallback onNotifications;
  final VoidCallback? onPublicView;

  @override
  Widget build(BuildContext context) {
    final cleanName = userName.trim();
    final initial = cleanName.isEmpty ? 'U' : cleanName[0].toUpperCase();
    return Container(
      height: 84,
      padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderFor(context).withValues(alpha: .8),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'PRICEWATCH',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 15,
                      color: AppColors.textSecondaryFor(context),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Community workspace',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondaryFor(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimaryFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (!compact && onPublicView != null) ...[
            _TopBarAction(
              icon: Icons.monitor_rounded,
              label: 'Public prices',
              onTap: onPublicView!,
            ),
            const SizedBox(width: 10),
          ],
          IconButton(
            tooltip: 'Notifications',
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 10),
          Container(
            height: 44,
            padding: const EdgeInsets.fromLTRB(5, 4, 14, 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMutedFor(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderFor(context)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 9),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarAction extends StatelessWidget {
  const _TopBarAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMutedFor(context),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.borderFor(context)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    ),
  );
}

class _VendorTopBar extends StatelessWidget {
  const _VendorTopBar({
    required this.title,
    required this.userName,
    required this.roleLabel,
    required this.compact,
    required this.onNotifications,
  });

  final String title;
  final String userName;
  final String roleLabel;
  final bool compact;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 72 : 80,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.lg : AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderFor(context).withValues(alpha: 0.75),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimaryFor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (!compact) ...[
            _VendorTopBarChip(
              icon: Icons.storefront_outlined,
              label: userName,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: AppSpacing.sm),
            const _VendorTopBarChip(
              icon: Icons.desktop_windows_outlined,
              label: 'Web workspace',
              color: AppColors.sky,
            ),
          ],
        ],
      ),
    );
  }
}

class _VendorTopBarChip extends StatelessWidget {
  const _VendorTopBarChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark(context) ? 0.22 : 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textPrimaryFor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorShellItem extends StatelessWidget {
  const _VendorShellItem({
    required this.icon,
    required this.label,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final verticalPadding = compact ? 10.0 : 12.0;
    final horizontalPadding = compact ? 8.0 : 12.0;
    final iconBoxSize = compact ? 42.0 : 40.0;
    final borderRadius = compact ? 16.0 : 14.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(borderRadius),
              border: selected
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      width: 1.2,
                    )
                  : null,
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: compact
                ? Center(
                    child: Tooltip(
                      message: label,
                      child: _VendorShellIcon(
                        icon: icon,
                        selected: selected,
                        size: iconBoxSize,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      _VendorShellIcon(
                        icon: icon,
                        selected: selected,
                        size: iconBoxSize,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: selected
                                    ? AppColors.textPrimary
                                    : Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _VendorShellIcon extends StatelessWidget {
  const _VendorShellIcon({
    required this.icon,
    required this.selected,
    required this.size,
  });

  final IconData icon;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 20,
        color: selected ? AppColors.primaryDark : Colors.white,
      ),
    );
  }
}

class _VendorShellLogout extends StatelessWidget {
  const _VendorShellLogout({required this.compact, required this.onPressed});

  final bool compact;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return compact
        ? Center(
            child: IconButton(
              tooltip: 'Log out',
              onPressed: () async => onPressed(),
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                padding: const EdgeInsets.all(14),
              ),
            ),
          )
        : OutlinedButton.icon(
            onPressed: () async => onPressed(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
          );
  }
}

class _WideNavigationRail extends StatelessWidget {
  const _WideNavigationRail({
    required this.items,
    required this.userName,
    required this.roleLabel,
    required this.isVendor,
    required this.currentIndex,
    required this.currentLocation,
    required this.onLogout,
    required this.onTap,
  });

  final List<_ShellNavItem> items;
  final String userName;
  final String roleLabel;
  final bool isVendor;
  final int currentIndex;
  final String currentLocation;
  final Future<void> Function() onLogout;
  final ValueChanged<_ShellNavItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 224,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(
          context,
        ).withValues(alpha: AppColors.isDark(context) ? 0.94 : 0.92),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.borderFor(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowFor(context).withValues(alpha: 0.2),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradientFor(context),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.glowStrong,
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppSealBadge(size: 42, padding: 3, showFrame: false),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'PriceWatch',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  userName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (var i = 0; i < items.length; i++) ...[
            _RailDestinationTile(
              icon: items[i].icon,
              label: items[i].label,
              selected: items[i].isSelected(currentLocation, currentIndex),
              onTap: () => onTap(items[i]),
            ),
            if (i != items.length - 1) const SizedBox(height: 10),
          ],
          const Spacer(),
          _WorkspaceIdentityCard(isVendor: isVendor, onLogout: onLogout),
        ],
      ),
    );
  }
}

class _WorkspaceIdentityCard extends StatelessWidget {
  const _WorkspaceIdentityCard({
    required this.isVendor,
    required this.onLogout,
  });

  final bool isVendor;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final useDark = AppColors.isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMutedFor(
          context,
        ).withValues(alpha: useDark ? 0.76 : 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isVendor) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.go('/modules?addProduct=1'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Product'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.isDark(context)
                      ? AppColors.darkPrimary
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: useDark
                    ? AppColors.darkPrimarySoft
                    : AppColors.primaryDark,
                side: BorderSide(
                  color: AppColors.borderFor(
                    context,
                  ).withValues(alpha: useDark ? 0.74 : 1),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailDestinationTile extends StatelessWidget {
  const _RailDestinationTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.primaryGradientFor(context) : null,
            color: selected ? null : AppColors.surfaceMutedFor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppColors.borderFor(context),
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppColors.glowSoft,
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.16)
                      : AppColors.surfaceFor(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? Colors.white
                      : (AppColors.isDark(context)
                            ? AppColors.darkPrimarySoft
                            : AppColors.primaryDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: selected
                        ? Colors.white
                        : AppColors.textPrimaryFor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
