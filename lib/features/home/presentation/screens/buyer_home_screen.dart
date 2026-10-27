import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/models/category_model.dart';
import '../../../../shared/models/ui_models.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_seal_badge.dart';
import '../../../../shared/widgets/category_style.dart';
import '../../../../shared/widgets/commodity_visual.dart';
import '../../../../shared/widgets/price_freshness_chip.dart';
import '../../../../shared/widgets/pricewatch_help.dart';
import '../../../../shared/widgets/responsive_page.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../../../../shared/widgets/theme_mode_button.dart';
import '../../../admin/presentation/widgets/admin_page_frame.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../watchlist/presentation/controllers/watchlist_controller.dart';
import '../controllers/home_controller.dart';

/// Buyer home: search, quick actions, categories, watchlist and the latest
/// market prices, in that order of everyday use.
class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = context.read<AuthController>().currentUser?.id;
    if (userId == null) return;
    await Future.wait([
      context.read<HomeController>().load(userId),
      context.read<WatchlistController>().load(userId),
    ]);
  }

  void _search(String query) {
    final trimmed = query.trim();
    context.go(
      trimmed.isEmpty
          ? '/commodities'
          : '/commodities?q=${Uri.encodeQueryComponent(trimmed)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final home = context.watch<HomeController>();
    final watchlist = context.watch<WatchlistController>();
    final dashboard = home.dashboard;
    final useWebShell =
        MediaQuery.sizeOf(context).width >= adminWebLayoutBreakpoint;

    return Scaffold(
      appBar: useWebShell
          ? null
          : AppBar(
              titleSpacing: AppSpacing.md,
              title: const Row(
                children: [
                  AppSealBadge(size: 32, padding: 2.5, showFrame: false),
                  SizedBox(width: 10),
                  Text('PriceWatch'),
                ],
              ),
              actions: [
                const PriceWatchGuideButton(),
                const ThemeModeButton(),
                _NotificationsButton(
                  unread: dashboard?.unreadNotifications ?? 0,
                ),
                const SizedBox(width: 4),
              ],
            ),
      body: AppBackground(
        showTopGlow: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ResponsivePage(
                maxWidth: 1120,
                topPadding: AppSpacing.md,
                child: home.isLoading && dashboard == null
                    ? const ListLoadingView(cardCount: 4, shrinkWrap: true)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Greeting(
                            name: (user?.fullName ?? '').split(' ').first,
                            controller: _searchController,
                            onSearch: _search,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const _QuickActions(),
                          const SizedBox(height: AppSpacing.xl),
                          if (dashboard != null) ...[
                            _SectionHeader(
                              title: 'Shop by category',
                              actionLabel: 'All prices',
                              onAction: () => context.go('/commodities'),
                            ),
                            _CategoryGrid(
                              categories: dashboard.categories,
                              counts: dashboard.commodityCounts,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final watch = _WatchlistSection(
                                items: watchlist.items,
                                isLoading: watchlist.isLoading,
                              );
                              final updates = _LatestUpdates(
                                updates: dashboard?.latestUpdates ?? const [],
                              );
                              if (constraints.maxWidth < 860) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    watch,
                                    const SizedBox(height: AppSpacing.xl),
                                    updates,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: watch),
                                  const SizedBox(width: AppSpacing.lg),
                                  Expanded(child: updates),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsButton extends StatelessWidget {
  const _NotificationsButton({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: unread > 0 ? '$unread unread notifications' : 'Notifications',
    onPressed: () => context.push('/notifications'),
    icon: Badge(
      isLabelVisible: unread > 0,
      label: Text(unread > 99 ? '99+' : '$unread'),
      child: const Icon(Icons.notifications_none_rounded),
    ),
  );
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.name,
    required this.controller,
    required this.onSearch,
  });

  final String name;
  final TextEditingController controller;
  final ValueChanged<String> onSearch;

  String get _salutation {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [AppColors.darkPrimaryDeep, AppColors.darkSurface]
              : const [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? _salutation : '$_salutation, $name',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check today’s market prices in Lingayen before you buy.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: onSearch,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search rice, bangus, eggs, tomato…',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
              ),
              suffixIcon: IconButton(
                tooltip: 'Search',
                onPressed: () => onSearch(controller.text),
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primaryDark,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    const actions = [
      (
        Icons.flag_rounded,
        'Report a price',
        'Overpriced or missing SRP',
        '/report/new',
        Color(0xFFDD6B20),
      ),
      (
        Icons.qr_code_scanner_rounded,
        'Scan store QR',
        'Report a specific stall',
        '/scan-qr',
        Color(0xFF6B46C1),
      ),
      (
        Icons.storefront_rounded,
        'Markets & stores',
        'Stalls and their prices',
        '/stores',
        Color(0xFF2B6CB0),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        return Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickAction(
                  icon: actions[i].$1,
                  title: actions[i].$2,
                  subtitle: compact ? null : actions[i].$3,
                  color: AppColors.readableFor(context, actions[i].$5),
                  onTap: () => context.push(actions[i].$4),
                  compact: compact,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.compact,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconBox = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 21),
    );
    final label = Text(
      title,
      maxLines: 2,
      textAlign: compact ? TextAlign.center : TextAlign.start,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
    return Material(
      color: AppColors.surfaceFor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.borderFor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: compact
              ? Column(children: [iconBox, const SizedBox(height: 8), label])
              : Row(
                  children: [
                    iconBox,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label,
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondaryFor(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accentFor(context),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
      ],
    ),
  );
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories, required this.counts});

  final List<CategoryModel> categories;
  final Map<int, int> counts;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 860
          ? 5
          : constraints.maxWidth >= 520
          ? 3
          : 2;
      const gap = AppSpacing.sm;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final category in categories)
            SizedBox(
              width: width,
              child: _CategoryTile(
                category: category,
                count: counts[category.id] ?? 0,
              ),
            ),
        ],
      );
    },
  );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.count});

  final CategoryModel category;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surfaceFor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.borderFor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/commodities?categoryId=${category.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CategoryIconBadge(iconKey: category.icon, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      count == 1 ? '1 item' : '$count items',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchlistSection extends StatelessWidget {
  const _WatchlistSection({required this.items, required this.isLoading});

  final List<WatchlistViewData> items;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _SectionHeader(
        title: 'Your watchlist',
        actionLabel: items.isEmpty ? null : 'See all',
        onAction: () => context.go('/watchlist'),
      ),
      _Panel(
        child: isLoading && items.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            : items.isEmpty
            ? _EmptyHint(
                icon: Icons.bookmark_add_outlined,
                text:
                    'Save items you buy often to see their price at a glance and get alerts when they rise.',
                actionLabel: 'Browse prices',
                onAction: () => context.go('/commodities'),
              )
            : Column(
                children: [
                  for (var i = 0; i < items.length && i < 4; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _WatchRow(item: items[i]),
                  ],
                ],
              ),
      ),
    ],
  );
}

class _WatchRow extends StatelessWidget {
  const _WatchRow({required this.item});

  final WatchlistViewData item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPrice = item.updatedAt.isNotEmpty;
    final change = item.variance;
    final overThreshold =
        item.threshold != null &&
        hasPrice &&
        item.currentPrice > item.threshold!;
    final changeColor = change > 0.005
        ? AppColors.readableFor(context, AppColors.warningText)
        : change < -0.005
        ? AppColors.readableFor(context, AppColors.success)
        : AppColors.textSecondaryFor(context);
    return InkWell(
      onTap: () => context.push('/commodity/${item.commodityId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CommodityVisual(
              label: item.commodityName,
              size: 40,
              useIllustration: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.commodityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    overThreshold
                        ? 'Above your alert of ${AppFormatters.currency(item.threshold!)}'
                        : 'per ${item.unit}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: overThreshold
                          ? AppColors.readableFor(
                              context,
                              AppColors.warningText,
                            )
                          : AppColors.textSecondaryFor(context),
                      fontWeight: overThreshold ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasPrice ? AppFormatters.currency(item.currentPrice) : '—',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (hasPrice)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (change.abs() >= 0.005)
                        Icon(
                          change > 0
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 14,
                          color: changeColor,
                        ),
                      Text(
                        change.abs() < 0.005
                            ? 'No change'
                            : AppFormatters.currency(change.abs()),
                        semanticsLabel: change.abs() < 0.005
                            ? 'No change'
                            : '${change > 0 ? 'Up' : 'Down'} ${AppFormatters.currency(change.abs())}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: changeColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestUpdates extends StatelessWidget {
  const _LatestUpdates({required this.updates});

  final List<PriceUpdateItem> updates;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _SectionHeader(
        title: 'Latest prices',
        actionLabel: 'All prices',
        onAction: () => context.go('/commodities'),
      ),
      _Panel(
        child: updates.isEmpty
            ? const _EmptyHint(
                icon: Icons.sell_outlined,
                text:
                    'New market prices will appear here as stalls report them.',
              )
            : Column(
                children: [
                  for (var i = 0; i < updates.length && i < 6; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _UpdateRow(update: updates[i]),
                  ],
                ],
              ),
      ),
    ],
  );
}

class _UpdateRow extends StatelessWidget {
  const _UpdateRow({required this.update});

  final PriceUpdateItem update;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = update.commodityId;
    return InkWell(
      onTap: id == null ? null : () => context.push('/commodity/$id'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    update.commodityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          update.storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryFor(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PriceFreshnessChip(recordedAt: update.recordedAt),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppFormatters.currency(update.price),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surfaceFor(context),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: AppColors.borderFor(context)),
    ),
    child: child,
  );
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      children: [
        Icon(icon, size: 32, color: AppColors.textSecondaryFor(context)),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onAction,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: Text(actionLabel!),
          ),
        ],
      ],
    ),
  );
}
