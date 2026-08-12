import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/ui_models.dart';
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
    final useWebShell = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      appBar: useWebShell
          ? null
          : AppBar(
              leading: const AppShellMenuButton(),
              title: const Text('Watchlist'),
              actions: [
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
                            _WatchlistHero(
                              userName:
                                  auth.currentUser?.fullName.split(' ').first ??
                                  'User',
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
                            const SizedBox(height: AppSpacing.lg),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 360;
                                final first = AppSurfaceCard(
                                  child: _MiniStat(
                                    label: 'Tracking',
                                    value: '${items.length} items',
                                    icon: Icons.bookmark_rounded,
                                  ),
                                );
                                final second = AppSurfaceCard(
                                  child: _MiniStat(
                                    label: 'Threshold alerts',
                                    value: '$activeAlerts active',
                                    icon: Icons.notifications_active_rounded,
                                    accent: AppColors.warning,
                                  ),
                                );

                                if (compact) {
                                  return Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: first,
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: second,
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: first),
                                    const SizedBox(width: 12),
                                    Expanded(child: second),
                                  ],
                                );
                              },
                            ),
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

class _WatchlistHero extends StatelessWidget {
  const _WatchlistHero({
    required this.userName,
    required this.itemCount,
    required this.activeAlerts,
  });

  final String userName;
  final int itemCount;
  final int activeAlerts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradientFor(context),
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: AppColors.glowStrong,
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$userName\'s watchlist',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Stay ahead of price spikes with local threshold alerts and trend tracking.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              final tracked = _HeroMetric(
                label: 'Tracked items',
                value: '$itemCount',
              );
              final alerts = _HeroMetric(
                label: 'Active alerts',
                value: '$activeAlerts',
              );

              if (compact) {
                return Column(
                  children: [
                    SizedBox(width: double.infinity, child: tracked),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: alerts),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: tracked),
                  const SizedBox(width: 12),
                  Expanded(child: alerts),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AppColors.primary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
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
    final aboveThreshold =
        item.threshold != null && item.currentPrice > item.threshold!;
    final varianceLabel =
        '${item.variance >= 0 ? '+' : '-'}${AppFormatters.currency(item.variance.abs())} vs previous';

    return AppSurfaceCard(
      onTap: onTap,
      borderColor: aboveThreshold
          ? AppColors.warning.withValues(alpha: 0.25)
          : AppColors.borderFor(context),
      gradient: aboveThreshold
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.isDark(context)
                  ? const [Color(0xFF412821), Color(0xFF28171A)]
                  : const [Color(0xFFFFFBF5), Color(0xFFFFFFFF)],
            )
          : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 380;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.commodityName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'remove') {
                        onRemove();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit threshold'),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Text('Remove item'),
                      ),
                    ],
                  ),
                ],
              ),
              Text(item.unit, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PriceTrendBadge(delta: item.variance, label: varianceLabel),
                  AppStatusBadge(
                    label: item.threshold == null
                        ? 'No threshold'
                        : 'Alert at ${AppFormatters.currency(item.threshold!)}',
                    color: aboveThreshold
                        ? AppColors.warning
                        : AppColors.primaryDark,
                    icon: aboveThreshold
                        ? Icons.warning_amber_rounded
                        : Icons.tune_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _PriceColumn(
                      label: 'Current',
                      value: AppFormatters.currency(item.currentPrice),
                    ),
                  ),
                  Expanded(
                    child: _PriceColumn(
                      label: 'Previous',
                      value: AppFormatters.currency(item.previousPrice),
                    ),
                  ),
                  Expanded(
                    child: _PriceColumn(
                      label: 'SRP',
                      value: AppFormatters.currency(item.srp),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (compact) ...[
                SizedBox(
                  width: double.infinity,
                  child: _MiniTrendChart(item: item),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    AppFormatters.dateTime(item.updatedAt),
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ] else
                Row(
                  children: [
                    Expanded(child: _MiniTrendChart(item: item)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        AppFormatters.dateTime(item.updatedAt),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommodityVisual(label: item.commodityName, size: 70),
                const SizedBox(height: 16),
                content,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommodityVisual(label: item.commodityName, size: 70),
              const SizedBox(width: 16),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

class _PriceColumn extends StatelessWidget {
  const _PriceColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _MiniTrendChart extends StatelessWidget {
  const _MiniTrendChart({required this.item});

  final WatchlistViewData item;

  @override
  Widget build(BuildContext context) {
    final isUp = item.variance >= 0;
    final color = isUp ? AppColors.warning : AppColors.primaryDark;
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
