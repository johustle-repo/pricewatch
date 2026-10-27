import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/ui_models.dart';
import '../../../../shared/widgets/price_freshness_chip.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_notification_button.dart';
import '../../../../shared/widgets/app_shell_menu_button.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/commodity_visual.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/price_trend_badge.dart';
import '../../../../shared/widgets/responsive_page.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/watchlist_controller.dart';
import '../../../../shared/widgets/theme_mode_button.dart';
import '../../../admin/presentation/widgets/admin_page_frame.dart';
import '../../../../shared/widgets/pricewatch_help.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthController>().currentUser?.id;
      if (userId != null) {
        context.read<WatchlistController>().load(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final controller = context.watch<WatchlistController>();
    final userId = auth.currentUser?.id;
    final items = controller.items;
    final query = _searchController.text.trim().toLowerCase();
    final visibleItems = items
        .where(
          (item) =>
              query.isEmpty || item.commodityName.toLowerCase().contains(query),
        )
        .toList();
    final activeAlerts = items
        .where(
          (item) =>
              item.threshold != null && item.currentPrice > item.threshold!,
        )
        .length;
    final useWebShell =
        MediaQuery.sizeOf(context).width >= adminWebLayoutBreakpoint;

    return Scaffold(
      appBar: useWebShell
          ? null
          : AppBar(
              leading: const AppShellMenuButton(),
              title: const Text('Watchlist'),
              actions: [
                const PriceWatchGuideButton(),
                const ThemeModeButton(),
                const AppNotificationButton(),
                IconButton(
                  onPressed: () => context.push('/commodities'),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
      body: userId == null
          ? const SizedBox.shrink()
          : AppBackground(
              child: ResponsivePage(
                maxWidth: 1140,
                expandHeight: true,
                horizontalPadding: 0,
                topPadding: 0,
                bottomPadding: 0,
                edgeToEdgeDesktopOnly: true,
                child: RefreshIndicator(
                  onRefresh: () =>
                      context.read<WatchlistController>().load(userId),
                  child: controller.isLoading
                      ? const ListLoadingView(cardCount: 5)
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          children: [
                            const SizedBox(height: AppSpacing.md),
                            _WatchlistSummary(
                              itemCount: items.length,
                              activeAlerts: activeAlerts,
                            ),
                            if (controller.error != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              AppSurfaceCard(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: AppColors.warning,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(controller.error!)),
                                    TextButton.icon(
                                      onPressed: () => controller.load(userId),
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 360;
                                final title = Text(
                                  'Tracked essentials',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                );
                                final action = TextButton.icon(
                                  onPressed: () => context.push('/commodities'),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add item'),
                                );

                                if (compact) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      title,
                                      const SizedBox(height: 8),
                                      action,
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: title),
                                    action,
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search_rounded),
                                hintText: 'Search tracked commodities',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (visibleItems.isEmpty)
                              EmptyStateView(
                                title: query.isEmpty
                                    ? 'No watched commodities'
                                    : 'No matching watched commodity',
                                message:
                                    'Bookmark commodities to track current prices, threshold alerts, and market movement.',
                                icon: Icons.bookmark_add_rounded,
                                action: SizedBox(
                                  width: 220,
                                  child: AppPrimaryButton(
                                    label: 'Browse commodities',
                                    icon: Icons.shopping_bag_outlined,
                                    onPressed: () =>
                                        context.push('/commodities'),
                                  ),
                                ),
                              )
                            else
                              ...visibleItems.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _WatchlistCard(
                                    item: item,
                                    onTap: () => context.push(
                                      '/commodity/${item.commodityId}',
                                    ),
                                    onEdit: () => _editThreshold(
                                      userId,
                                      item.watchlistId,
                                    ),
                                    onRemove: () => context
                                        .read<WatchlistController>()
                                        .remove(
                                          userId: userId,
                                          watchlistId: item.watchlistId,
                                        ),
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

  Future<void> _editThreshold(int userId, int watchlistId) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();

    final result = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update threshold'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Threshold price',
              hintText: 'Leave blank to clear alert threshold',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return null;
              }
              return Validators.price(value, label: 'Threshold');
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }
              Navigator.of(context).pop(
                controller.text.trim().isEmpty
                    ? null
                    : double.parse(controller.text.trim()),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted) {
      return;
    }

    await context.read<WatchlistController>().updateThreshold(
      userId: userId,
      watchlistId: watchlistId,
      threshold: result,
    );
  }
}

class _WatchlistCard extends StatelessWidget {
  const _WatchlistCard({
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onRemove,
  });

  final WatchlistViewData item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPrice = item.updatedAt.isNotEmpty;
    final aboveThreshold =
        hasPrice &&
        item.threshold != null &&
        item.currentPrice > item.threshold!;
    final change = item.variance;
    final flat = !hasPrice || change.abs() < 0.005;

    return AppSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderColor: aboveThreshold
          ? AppColors.warning.withValues(alpha: 0.35)
          : AppColors.borderFor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CommodityVisual(
                label: item.commodityName,
                size: 48,
                useIllustration: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.commodityName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'per ${item.unit}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryFor(context),
                          ),
                        ),
                        PriceFreshnessChip(recordedAt: item.updatedAt),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                hasPrice ? AppFormatters.currency(item.currentPrice) : '\u2014',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'More options',
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'remove') {
                    onRemove();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit alert')),
                  PopupMenuItem(value: 'remove', child: Text('Remove item')),
                ],
              ),
            ],
          ),
          if (hasPrice) ...[
            const SizedBox(height: 10),
            _MiniTrendChart(item: item),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasPrice)
                PriceTrendBadge(
                  delta: flat ? 0 : change,
                  label: flat
                      ? 'No change'
                      : '${AppFormatters.currency(change.abs())} vs previous',
                ),
              AppStatusBadge(
                label: 'SRP ${AppFormatters.currency(item.srp)}',
                color: AppColors.textSecondaryFor(context),
              ),
              AppStatusBadge(
                label: item.threshold == null
                    ? 'Set an alert'
                    : aboveThreshold
                    ? 'Above alert ${AppFormatters.currency(item.threshold!)}'
                    : 'Alert at ${AppFormatters.currency(item.threshold!)}',
                color: aboveThreshold
                    ? AppColors.warningText
                    : AppColors.primaryDark,
                icon: aboveThreshold
                    ? Icons.warning_amber_rounded
                    : Icons.notifications_none_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniTrendChart extends StatelessWidget {
  const _MiniTrendChart({required this.item});

  final WatchlistViewData item;

  @override
  Widget build(BuildContext context) {
    final isUp = item.variance > 0.005;
    final color = isUp
        ? AppColors.warning
        : AppColors.readableFor(context, AppColors.primaryDark);
    final values = item.history.isEmpty
        ? [item.previousPrice, item.currentPrice]
        : item.history.map((point) => point.value).toList();
    final minPrice = values.reduce((a, b) => a < b ? a : b);
    final maxPrice = values.reduce((a, b) => a > b ? a : b);
    final rangePadding = ((maxPrice - minPrice) * 0.15).clamp(2.0, 50.0);
    final spots = values.length == 1
        ? [FlSpot(0, values.first), FlSpot(1, values.first)]
        : List.generate(
            values.length,
            (index) => FlSpot(index.toDouble(), values[index]),
          );

    return SizedBox(
      height: 42,
      child: LineChart(
        LineChartData(
          minY: minPrice - rangePadding,
          maxY: maxPrice + rangePadding,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.08),
              ),
              spots: spots,
            ),
          ],
        ),
      ),
    );
  }
}

/// One-line summary of the watchlist; the items themselves come right after.
class _WatchlistSummary extends StatelessWidget {
  const _WatchlistSummary({
    required this.itemCount,
    required this.activeAlerts,
  });

  final int itemCount;
  final int activeAlerts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.accentFor(context);
    final alertColor = AppColors.readableFor(context, AppColors.warningText);
    Widget stat(IconData icon, Color color, String value, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
            ),
          ],
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.sm,
        children: [
          stat(
            Icons.bookmark_rounded,
            accent,
            '$itemCount',
            itemCount == 1 ? 'item tracked' : 'items tracked',
          ),
          stat(
            Icons.notifications_active_rounded,
            activeAlerts > 0 ? alertColor : AppColors.textSecondaryFor(context),
            '$activeAlerts',
            activeAlerts == 1 ? 'above your alert' : 'above your alerts',
          ),
        ],
      ),
    );
  }
}
