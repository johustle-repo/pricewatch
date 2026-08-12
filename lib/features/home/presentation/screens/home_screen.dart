import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/app_icon_mapper.dart';
import '../../../../shared/models/category_model.dart';
import '../../../../shared/models/ui_models.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_seal_badge.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/adaptive_stat_grid.dart';
import '../../../../shared/widgets/app_shell_menu_button.dart';
import '../../../../shared/widgets/commodity_visual.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/price_trend_badge.dart';
import '../../../../shared/widgets/responsive_page.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthController>().currentUser?.id;
      if (userId != null) {
        context.read<HomeController>().load(userId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final controller = context.watch<HomeController>();
    final dashboard = controller.dashboard;
    final user = auth.currentUser;
    final isVendor = user?.isVendor ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: const AppShellMenuButton(showMobileBrand: false),
        title: Row(
          children: [
            const AppSealBadge(size: 32, padding: 2.5, showFrame: false),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isVendor ? 'Vendor Workspace' : 'PriceWatch',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/stores'),
            icon: const Icon(Icons.storefront_outlined),
          ),
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            final userId = auth.currentUser?.id;
            if (userId != null) {
              await context.read<HomeController>().load(userId);
            }
          },
          child: controller.isLoading && dashboard == null
              ? const ListLoadingView(cardCount: 6)
              : dashboard == null
              ? const EmptyStateView(
                  title: 'Dashboard unavailable',
                  message: 'We could not load your local dashboard right now.',
                )
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: ResponsivePage(
                        maxWidth: 1220,
                        horizontalPadding: 0,
                        topPadding: 0,
                        bottomPadding: 0,
                        edgeToEdgeDesktopOnly: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HeroCard(
                              userName:
                                  user?.fullName.split(' ').first ?? 'Friend',
                              isVendor: isVendor,
                              watchlistCount: dashboard.watchlistCount,
                              alertCount: dashboard.unreadNotifications,
                              savingsInsight: _buildSavingsInsight(dashboard),
                              searchController: _searchController,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _ShortcutRow(
                              isVendor: isVendor,
                              onReport: () => context.push('/report/new'),
                              onWatchlist: () => context.go('/watchlist'),
                              onStores: () => context.push('/stores'),
                            ),
                            if (!isVendor) ...[
                              const SizedBox(height: AppSpacing.lg),
                              const _CommunityGuideCard(),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                            SectionHeader(
                              title: isVendor
                                  ? 'Product Categories'
                                  : 'Categories',
                              subtitle: isVendor
                                  ? 'Review commodity groups your customers track'
                                  : 'Browse essentials faster',
                              actionLabel: 'See all',
                              onTap: () => context.push('/categories'),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _ResponsiveCategorySection(
                              categories: dashboard.categories,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SectionHeader(
                              title: isVendor
                                  ? 'Market Price Signals'
                                  : 'Trending Prices',
                              subtitle: isVendor
                                  ? 'Watch SRP variance before customers report issues'
                                  : 'Items people are actively checking this week',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _ResponsiveTrendingSection(
                              items: dashboard.featuredProducts,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SectionHeader(
                              title: isVendor
                                  ? 'Store Activity'
                                  : 'Nearby Markets',
                              subtitle: isVendor
                                  ? 'Recent public updates from local market stalls'
                                  : 'Recent updates captured from local stores',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _ResponsiveNearbyMarketSection(
                              items: dashboard.latestUpdates,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SectionHeader(
                              title: isVendor
                                  ? 'Customer Alert Signals'
                                  : 'Watchlist Alerts',
                              subtitle: isVendor
                                  ? 'Items shoppers are watching closely'
                                  : 'Quick view of tracked essentials',
                              actionLabel: 'Open watchlist',
                              onTap: () => context.go('/watchlist'),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _WatchlistAlertStrip(dashboard: dashboard),
                            const SizedBox(height: AppSpacing.xl),
                            AdaptiveStatGrid(
                              minTileWidth: 220,
                              maxColumns: ResponsivePage.isWide(context)
                                  ? 3
                                  : 2,
                              children: [
                                StatCard(
                                  title: isVendor
                                      ? 'Pending signals'
                                      : 'Unread alerts',
                                  value: '${dashboard.unreadNotifications}',
                                  icon: Icons.notifications_active_rounded,
                                  caption: isVendor
                                      ? 'Customer-facing updates to review'
                                      : 'Notifications waiting for review',
                                  highlight: true,
                                ),
                                StatCard(
                                  title: isVendor
                                      ? 'Stores visible'
                                      : 'Markets tracked',
                                  value: '${dashboard.storeCount}',
                                  icon: Icons.storefront_rounded,
                                  caption: isVendor
                                      ? 'Local stores in the shared price board'
                                      : 'Active local stores in shared data',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _buildSavingsInsight(DashboardData dashboard) {
    final savings = dashboard.featuredProducts
        .map((item) => item.srp - item.latestAveragePrice)
        .where((value) => value > 0)
        .fold<double>(0, (sum, item) => sum + item);

    if (savings <= 0) {
      return 'Market prices are holding close to SRP today.';
    }
    return 'Potential tracked savings: ${AppFormatters.currency(savings)} across featured essentials.';
  }
}

class _CommunityGuideCard extends StatelessWidget {
  const _CommunityGuideCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final steps = [
            const _GuideStep(
              icon: Icons.search_rounded,
              title: 'Check prices',
              caption: 'Compare nearby shops with the published SRP.',
            ),
            const _GuideStep(
              icon: Icons.bookmark_add_outlined,
              title: 'Track essentials',
              caption: 'Save items and receive threshold alerts.',
            ),
            _GuideStep(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Report fairly',
              caption: 'Scan the shop QR and attach accurate details.',
              onTap: () => context.push('/scan-qr'),
            ),
          ];
          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your quick guide',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                ...steps.expand((item) => [item, const SizedBox(height: 10)]),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shop smarter in three steps',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Row(
                children: steps
                    .map(
                      (item) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: item,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.icon,
    required this.title,
    required this.caption,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surfaceMutedFor(context),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(caption, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.userName,
    required this.isVendor,
    required this.watchlistCount,
    required this.alertCount,
    required this.savingsInsight,
    required this.searchController,
  });

  final String userName;
  final bool isVendor;
  final int watchlistCount;
  final int alertCount;
  final String savingsInsight;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final useDark = AppColors.isDark(context);
    final compact = MediaQuery.sizeOf(context).width < 400;
    final veryCompact = MediaQuery.sizeOf(context).width < 340;
    final radius = BorderRadius.circular(compact ? 26 : 30);
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradientFor(context),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: useDark ? 0.28 : 0.16),
            blurRadius: compact ? 18 : 24,
            offset: Offset(0, compact ? 10 : 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _HeroBackdropPainter()),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!compact) ...[
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AppSealBadge(
                          size: veryCompact ? 42 : 54,
                          padding: veryCompact ? 2.6 : 3.5,
                          showFrame: false,
                        ),
                        _RolePill(
                          label: isVendor
                              ? 'Vendor workspace'
                              : 'Community workspace',
                          icon: isVendor
                              ? Icons.storefront_rounded
                              : Icons.people_alt_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Text(
                    '${_greeting()}, $userName',
                    style:
                        (veryCompact
                                ? Theme.of(context).textTheme.titleLarge
                                : Theme.of(context).textTheme.headlineSmall)
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isVendor
                        ? 'Manage store visibility, price signals, and customer trust.'
                        : 'Your local price intelligence snapshot',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
                  ),
                  SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final metricWidth = constraints.maxWidth < 340
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: metricWidth,
                            child: _HeroMetric(
                              value: '$watchlistCount',
                              label: isVendor
                                  ? 'Watched products'
                                  : 'Tracked items',
                            ),
                          ),
                          SizedBox(
                            width: metricWidth,
                            child: _HeroMetric(
                              value: '$alertCount',
                              label: isVendor
                                  ? 'Customer signals'
                                  : 'New alerts',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (!compact) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: EdgeInsets.all(veryCompact ? 14 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: AppColors.isDark(context) ? 0.1 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(compact ? 18 : 22),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: AppColors.isDark(context) ? 0.14 : 0.12,
                          ),
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final stackInfo = constraints.maxWidth < 310;
                          final iconCard = Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isVendor
                                  ? Icons.store_mall_directory_rounded
                                  : Icons.wallet_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          );
                          final copy = Text(
                            isVendor
                                ? 'Keep your listed prices aligned with SRP and recent shopper activity.'
                                : savingsInsight,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  height: 1.4,
                                ),
                          );

                          if (stackInfo) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                iconCard,
                                const SizedBox(height: 10),
                                copy,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              iconCard,
                              const SizedBox(width: 12),
                              Expanded(child: copy),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                  SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                  AppSearchField(
                    controller: searchController,
                    hintText: isVendor
                        ? 'Search commodities, stores, or price movement'
                        : 'Search rice, eggs, fish, or nearby prices',
                    onSubmitted: (value) {
                      context.push(
                        '/commodities?q=${Uri.encodeQueryComponent(value)}',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 18) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bandPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.58, 0, size.width * 0.12, size.height),
      bandPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.78, 0, size.width * 0.18, size.height),
      bandPaint..color = Colors.black.withValues(alpha: 0.05),
    );

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.3 + i * 0.17);
      final path = Path()
        ..moveTo(-size.width * 0.08, y)
        ..quadraticBezierTo(
          size.width * 0.48,
          y - size.height * 0.08,
          size.width * 1.08,
          y + size.height * 0.05,
        );
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 400;
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: AppColors.isDark(context) ? 0.1 : 0.12,
        ),
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style:
                (compact
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.headlineSmall)
                    ?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.isVendor,
    required this.onReport,
    required this.onWatchlist,
    required this.onStores,
  });

  final bool isVendor;
  final VoidCallback onReport;
  final VoidCallback onWatchlist;
  final VoidCallback onStores;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final cards = isVendor
            ? [
                _ShortcutCard(
                  title: 'Review Stores',
                  subtitle: 'Open public store details',
                  icon: Icons.storefront_rounded,
                  onTap: onStores,
                  accent: AppColors.primary,
                ),
                _ShortcutCard(
                  title: 'Report Queue',
                  subtitle: 'Check community reports',
                  icon: Icons.assignment_rounded,
                  onTap: onReport,
                  accent: AppColors.warning,
                ),
                _ShortcutCard(
                  title: 'Watch Products',
                  subtitle: 'Review tracked essentials',
                  icon: Icons.inventory_2_rounded,
                  onTap: onWatchlist,
                  accent: AppColors.primarySoft,
                ),
              ]
            : [
                _ShortcutCard(
                  title: 'Report Overpricing',
                  subtitle: 'Send a community report',
                  icon: Icons.flag_rounded,
                  onTap: onReport,
                  accent: AppColors.warning,
                ),
                _ShortcutCard(
                  title: 'Watchlist',
                  subtitle: 'Track essentials and alerts',
                  icon: Icons.bookmark_rounded,
                  onTap: onWatchlist,
                  accent: AppColors.primarySoft,
                ),
                _ShortcutCard(
                  title: 'Browse Stores',
                  subtitle: 'Review local market listings',
                  icon: Icons.storefront_rounded,
                  onTap: onStores,
                  accent: AppColors.primary,
                ),
              ];

        if (compact) {
          final mobileActions = isVendor
              ? [
                  _MobileShortcut(
                    title: 'Stores',
                    icon: Icons.storefront_rounded,
                    accent: AppColors.primary,
                    onTap: onStores,
                  ),
                  _MobileShortcut(
                    title: 'Reports',
                    icon: Icons.assignment_rounded,
                    accent: AppColors.warning,
                    onTap: onReport,
                  ),
                  _MobileShortcut(
                    title: 'Products',
                    icon: Icons.inventory_2_rounded,
                    accent: AppColors.primarySoft,
                    onTap: onWatchlist,
                  ),
                ]
              : [
                  _MobileShortcut(
                    title: 'Report',
                    icon: Icons.flag_rounded,
                    accent: AppColors.warningText,
                    onTap: onReport,
                  ),
                  _MobileShortcut(
                    title: 'Watchlist',
                    icon: Icons.bookmark_rounded,
                    accent: AppColors.primary,
                    onTap: onWatchlist,
                  ),
                  _MobileShortcut(
                    title: 'Stores',
                    icon: Icons.storefront_rounded,
                    accent: AppColors.info,
                    onTap: onStores,
                  ),
                ];
          return Row(
            children: [
              for (var i = 0; i < mobileActions.length; i++) ...[
                Expanded(child: mobileActions[i]),
                if (i != mobileActions.length - 1) const SizedBox(width: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }
}

class _MobileShortcut extends StatelessWidget {
  const _MobileShortcut({
    required this.title,
    required this.icon,
    required this.accent,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surfaceFor(context),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 94),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderFor(context)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textPrimaryFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(
              context,
            ).withValues(alpha: AppColors.isDark(context) ? 0.96 : 0.86),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderFor(context)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowFor(context).withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 116),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                    height: 1.3,
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

class _ResponsiveCategorySection extends StatelessWidget {
  const _ResponsiveCategorySection({required this.categories});

  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final maxColumns = constraints.maxWidth >= 1180
            ? 6
            : constraints.maxWidth >= 900
            ? 4
            : 3;

        final cards = categories
            .map(
              (category) => SizedBox(
                height: 128,
                child: _CategoryChipCard(
                  title: category.name,
                  icon: AppIconMapper.fromKey(category.icon),
                  width: wide ? null : (constraints.maxWidth < 380 ? 156 : 172),
                  onTap: () => context.push(
                    category.id == null
                        ? '/commodities'
                        : '/commodities?categoryId=${category.id}',
                  ),
                ),
              ),
            )
            .toList();

        if (wide) {
          return AdaptiveStatGrid(
            minTileWidth: 140,
            maxColumns: maxColumns,
            children: cards,
          );
        }

        return SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => cards[index],
          ),
        );
      },
    );
  }
}

class _CategoryChipCard extends StatelessWidget {
  const _CategoryChipCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.width,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(
              context,
            ).withValues(alpha: AppColors.isDark(context) ? 0.96 : 0.84),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderFor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.backgroundAltFor(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primaryDark, size: 20),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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

class _ResponsiveTrendingSection extends StatelessWidget {
  const _ResponsiveTrendingSection({required this.items});

  final List<CommodityOverview> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        final maxColumns = constraints.maxWidth >= 1180
            ? 4
            : constraints.maxWidth >= 900
            ? 3
            : 2;
        final cardWidth = constraints.maxWidth < 380 ? 206.0 : 224.0;
        final cardHeight = wide ? 256.0 : 218.0;
        final cards = items
            .map(
              (item) => SizedBox(
                height: cardHeight,
                child: _TrendingPriceCard(
                  item: item,
                  width: wide ? null : cardWidth,
                ),
              ),
            )
            .toList();

        if (wide) {
          return AdaptiveStatGrid(
            minTileWidth: 220,
            maxColumns: maxColumns,
            children: cards,
          );
        }

        return SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) => cards[index],
          ),
        );
      },
    );
  }
}

class _TrendingPriceCard extends StatelessWidget {
  const _TrendingPriceCard({required this.item, this.width});

  final CommodityOverview item;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final compact = width != null;
    return InkWell(
      onTap: () => context.push('/commodity/${item.id}'),
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        width: width,
        padding: EdgeInsets.all(compact ? 14 : 18),
        decoration: BoxDecoration(
          gradient: AppColors.surfaceGradientFor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderFor(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowFor(context).withValues(alpha: 0.15),
              blurRadius: 14,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommodityVisual(
                  label: item.name,
                  category: item.categoryName,
                  size: compact ? 52 : 62,
                  heroTag: 'commodity-visual-${item.id}',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: PriceTrendBadge(delta: item.varianceFromSrp),
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 12 : 18),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: compact ? 3 : 6),
            Text(
              '${item.categoryName} | ${item.unit}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              AppFormatters.currency(item.latestAveragePrice),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'SRP ${AppFormatters.currency(item.srp)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchlistAlertStrip extends StatelessWidget {
  const _WatchlistAlertStrip({required this.dashboard});

  final DashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    final watchedItems = dashboard.featuredProducts
        .where((item) => item.isWatched)
        .take(3)
        .toList();

    if (watchedItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(
            context,
          ).withValues(alpha: AppColors.isDark(context) ? 0.96 : 0.86),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderFor(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.backgroundAltFor(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                dashboard.unreadNotifications > 0
                    ? '${dashboard.unreadNotifications} unread alerts are ready for review.'
                    : 'No active watchlist alerts yet. Start tracking a commodity to see price movement here.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final children = watchedItems
            .map((item) => _WatchlistAlertCard(item: item))
            .toList();

        if (constraints.maxWidth >= 900) {
          return AdaptiveStatGrid(
            minTileWidth: 260,
            maxColumns: 3,
            children: children,
          );
        }

        return Column(
          children: children
              .map(
                (child) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ResponsiveNearbyMarketSection extends StatelessWidget {
  const _ResponsiveNearbyMarketSection({required this.items});

  final List<PriceUpdateItem> items;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final unique = <PriceUpdateItem>[];
    for (final update in items) {
      if (seen.add(update.storeName)) {
        unique.add(update);
      }
      if (unique.length == 3) {
        break;
      }
    }

    final cards = unique.map((item) => _NearbyMarketCard(item: item)).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return AdaptiveStatGrid(
            minTileWidth: 280,
            maxColumns: 3,
            children: cards,
          );
        }

        return Column(
          children: cards
              .map(
                (card) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _NearbyMarketCard extends StatelessWidget {
  const _NearbyMarketCard({required this.item});

  final PriceUpdateItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(
          context,
        ).withValues(alpha: AppColors.isDark(context) ? 0.96 : 0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.backgroundAltFor(context),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.store_mall_directory_rounded,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.storeName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Latest update for ${item.commodityName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Text(
                      AppFormatters.currency(item.price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      AppFormatters.date(item.recordedAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchlistAlertCard extends StatelessWidget {
  const _WatchlistAlertCard({required this.item});

  final CommodityOverview item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(
          context,
        ).withValues(alpha: AppColors.isDark(context) ? 0.96 : 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final visual = CommodityVisual(
            label: item.name,
            category: item.categoryName,
            size: 56,
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Latest average ${AppFormatters.currency(item.latestAveragePrice)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
          final badge = PriceTrendBadge(delta: item.varianceFromSrp);

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                visual,
                const SizedBox(height: 14),
                details,
                const SizedBox(height: 12),
                badge,
              ],
            );
          }

          return Row(
            children: [
              visual,
              const SizedBox(width: 14),
              Expanded(child: details),
              const SizedBox(width: 12),
              Flexible(child: badge),
            ],
          );
        },
      ),
    );
  }
}
