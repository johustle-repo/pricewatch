import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_seal_badge.dart';
import '../widgets/admin_page_frame.dart';

class AdminWebShellScreen extends StatelessWidget {
  const AdminWebShellScreen({
    super.key,
    required this.child,
    required this.onLogout,
  });

  final Widget child;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final useWebShell = width >= adminWebLayoutBreakpoint;

        if (!useWebShell) {
          return child;
        }

        final bool compactSidebar = width < 1200;
        final bool compactHeight = height < 760;
        final double sidebarWidth = compactSidebar
            ? (compactHeight ? 76 : 84)
            : (compactHeight ? 232 : 252);
        final router = GoRouter.of(context);

        return AnimatedBuilder(
          animation: router.routerDelegate,
          builder: (context, _) {
            final currentLocation =
                router.routerDelegate.currentConfiguration.uri.path;
            final currentTitle = _titleForRoute(currentLocation);
            final currentSection = _sectionForRoute(currentLocation);

            return DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.isDark(context)
                    ? const Color(0xFF0B1120)
                    : const Color(0xFFF2F5F9),
              ),
              child: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: sidebarWidth,
                      padding: EdgeInsets.fromLTRB(
                        compactSidebar ? 8 : 12,
                        compactHeight ? 10 : 14,
                        compactSidebar ? 8 : 12,
                        compactHeight ? 10 : 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF0D172B),
                            Color(0xFF111E35),
                            Color(0xFF172641),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x4D020617),
                            blurRadius: 32,
                            offset: const Offset(8, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: compactSidebar ? 0 : 6,
                            ),
                            child: compactSidebar
                                ? Center(
                                    child: Container(
                                      width: compactHeight ? 40 : 44,
                                      height: compactHeight ? 40 : 44,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const AppSealBadge(
                                        size: 28,
                                        padding: 2,
                                        showFrame: false,
                                      ),
                                    ),
                                  )
                                : Row(
                                    children: [
                                      Container(
                                        width: compactHeight ? 36 : 40,
                                        height: compactHeight ? 36 : 40,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const AppSealBadge(
                                          size: 24,
                                          padding: 2,
                                          showFrame: false,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'PriceWatch',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Admin console',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.72,
                                                        ),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          SizedBox(
                            height: compactHeight
                                ? AppSpacing.md
                                : AppSpacing.lg,
                          ),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                _AdminShellItem(
                                  label: 'Overview',
                                  route: '/admin',
                                  icon: Icons.dashboard_rounded,
                                  compact: compactSidebar,
                                  currentLocation: currentLocation,
                                ),
                                _AdminShellItem(
                                  label: 'Categories',
                                  route: '/admin/categories',
                                  icon: Icons.category_rounded,
                                  compact: compactSidebar,
                                  currentLocation: currentLocation,
                                ),
                                _AdminShellItem(
                                  label: 'Commodities',
                                  route: '/admin/commodities',
                                  icon: Icons.inventory_2_rounded,
                                  compact: compactSidebar,
                                  currentLocation: currentLocation,
                                ),
                                _AdminShellItem(
                                  label: 'Users',
                                  route: '/admin/users',
                                  icon: Icons.people_alt_rounded,
                                  compact: compactSidebar,
                                  currentLocation: currentLocation,
                                ),
                                _AdminShellItem(
                                  label: 'Stores',
                                  route: '/admin/stores',
                                  icon: Icons.storefront_rounded,
                                  compact: compactSidebar,
                                  currentLocation: currentLocation,
                                ),
                                _AdminShellItem(
                                  label: 'Prices',
                                  route: '/admin/prices',
                                  icon: Icons.price_change_rounded,
                                  compact: compactSidebar,
                                  currentLocation: currentLocation,
                                ),
                                _AdminShellItem(
                                  label: 'Reports',
                                  route: '/admin/reports',
                                  icon: Icons.flag_rounded,
                                  compact: compactSidebar,
                                  currentLocation: currentLocation,
                                ),
                                _AdminShellItem(
                                  label: 'Analytics',
                                  route: '/admin/analytics',
                                  icon: Icons.query_stats_rounded,
                                  compact: compactSidebar,
                                  currentLocation: currentLocation,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: compactHeight
                                ? AppSpacing.sm
                                : AppSpacing.md,
                          ),
                          _PublicViewButton(compact: compactSidebar),
                          SizedBox(
                            height: compactHeight
                                ? AppSpacing.sm
                                : AppSpacing.md,
                          ),
                          _LogoutButton(
                            compact: compactSidebar,
                            onPressed: () async {
                              await onLogout();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.isDark(context)
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF5F7FA),
                            border: Border.all(
                              color: AppColors.borderFor(
                                context,
                              ).withValues(alpha: 0.8),
                            ),
                            boxShadow: [
                              const BoxShadow(
                                color: Color(0x120F172A),
                                blurRadius: 30,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _AdminTopBar(
                                title: currentTitle,
                                section: currentSection,
                                compact: width < 1100,
                              ),
                              Expanded(child: child),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _titleForRoute(String route) {
    if (route.startsWith('/admin/categories')) {
      return 'Categories';
    }
    if (route.startsWith('/admin/commodities')) {
      return 'Commodities';
    }
    if (route.startsWith('/admin/users')) {
      return 'Users';
    }
    if (route.startsWith('/admin/stores')) {
      return 'Stores';
    }
    if (route.startsWith('/admin/prices')) {
      return 'Prices';
    }
    if (route.startsWith('/admin/reports')) {
      return 'Reports';
    }
    if (route.startsWith('/admin/analytics')) {
      return 'Analytics';
    }
    return 'Dashboard';
  }

  String _sectionForRoute(String route) {
    if (route == '/admin') {
      return 'Overview';
    }
    if (route.startsWith('/admin/reports')) {
      return 'Moderation';
    }
    if (route.startsWith('/admin/analytics')) {
      return 'Insights';
    }
    return 'Management';
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.title,
    required this.section,
    required this.compact,
  });

  final String title;
  final String section;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 68 : 78,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.md : AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? const Color(0xFF101827)
            : Colors.white,
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
                  section,
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
          if (!compact) ...[
            _TopBarChip(
              icon: Icons.cloud_done_outlined,
              label: 'Firebase live',
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: AppSpacing.sm),
            _TopBarChip(
              icon: Icons.calendar_today_outlined,
              label: DateFormat('MMM d, y').format(DateTime.now()),
              color: const Color(0xFF475569),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          IconButton(
            tooltip: 'Public view',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.monitor_rounded),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.isDark(context)
                  ? AppColors.darkPrimarySoft
                  : AppColors.primaryDark,
              backgroundColor: AppColors.isDark(context)
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9),
              side: BorderSide(color: AppColors.borderFor(context)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE11D67), Color(0xFFFB7185)],
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24E11D67),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarChip extends StatelessWidget {
  const _TopBarChip({
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

class _AdminShellItem extends StatelessWidget {
  const _AdminShellItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.compact,
    required this.currentLocation,
  });

  final String label;
  final String route;
  final IconData icon;
  final bool compact;
  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    final selected = route == '/admin'
        ? currentLocation == route
        : currentLocation == route || currentLocation.startsWith('$route/');

    final double verticalPadding = compact ? 8 : 10;
    final double horizontalPadding = compact ? 6 : 10;
    final double iconBoxSize = compact ? 38 : 36;
    final double borderRadius = compact ? 14 : 12;

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: () => context.go(route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFE11D67).withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadius),
              border: selected
                  ? Border.all(
                      color: const Color(0xFFFF6B9A).withValues(alpha: 0.28),
                    )
                  : Border.all(color: Colors.transparent),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: compact
                ? Center(
                    child: Tooltip(
                      message: label,
                      child: Container(
                        width: iconBoxSize,
                        height: iconBoxSize,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFE11D67)
                              : Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, size: 20, color: Colors.white),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        width: iconBoxSize,
                        height: iconBoxSize,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFE11D67)
                              : Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 20, color: Colors.white),
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
                                    ? Colors.white
                                    : const Color(0xFFD5DEEC),
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

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.compact, required this.onPressed});

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

class _PublicViewButton extends StatelessWidget {
  const _PublicViewButton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return compact
        ? Center(
            child: IconButton(
              tooltip: 'Public view',
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.monitor_rounded, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                padding: const EdgeInsets.all(14),
              ),
            ),
          )
        : OutlinedButton.icon(
            onPressed: () => context.go('/'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.monitor_rounded),
            label: const Text('Public view'),
          );
  }
}
