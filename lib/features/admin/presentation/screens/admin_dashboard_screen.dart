import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/models/ui_models.dart';
import '../../../../shared/widgets/adaptive_stat_grid.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_page_frame.dart';
import '../widgets/admin_workspace_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().loadAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();
    final analytics = controller.analytics;
    final webLayout = useAdminWebLayout(context);

    return Scaffold(
      appBar: webLayout ? null : AppBar(title: const Text('Admin Dashboard')),
      body: AppBackground(
        showTopGlow: false,
        child: RefreshIndicator(
          onRefresh: () => context.read<AdminController>().loadAnalytics(),
          child: controller.isLoading && analytics == null
              ? const ListLoadingView(cardCount: 5)
              : AdminPageFrame(
                  maxWidth: 1320,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    children: [
                      AdminPageHeader(
                        title: 'Dashboard',
                        subtitle:
                            'Overview of reports, tracked items, price activity, and admin shortcuts.',
                        icon: Icons.dashboard_rounded,
                        webActionAtTop: true,
                        action: SizedBox(
                          width: webLayout ? 220 : double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => context.go('/admin/reports'),
                            icon: const Icon(Icons.flag_rounded),
                            label: const Text('Open reports'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ),
                      ),
                      if (controller.error != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        AdminErrorBanner(message: controller.error!),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      AdaptiveStatGrid(
                        minTileWidth: 220,
                        maxColumns: webLayout ? 4 : 2,
                        children: [
                          _DashboardStatCard(
                            title: 'Reports',
                            value: '${analytics?.totalReports ?? 0}',
                            icon: Icons.flag_outlined,
                            accent: AppColors.warning,
                          ),
                          _DashboardStatCard(
                            title: 'Pending review',
                            value: '${analytics?.pendingReports ?? 0}',
                            icon: Icons.pending_actions_outlined,
                            accent: AppColors.warning,
                          ),
                          _DashboardStatCard(
                            title: 'Watched items',
                            value: '${analytics?.watchedItemsCount ?? 0}',
                            icon: Icons.bookmark_added_outlined,
                            accent: AppColors.primaryDark,
                          ),
                          _DashboardStatCard(
                            title: 'Price updates',
                            value: '${analytics?.latestUpdatesCount ?? 0}',
                            icon: Icons.price_change_outlined,
                            accent: AppColors.sky,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _DashboardSummaryCard(analytics: analytics),
                      const SizedBox(height: AppSpacing.xl),
                      _AnalyticsPreview(analytics: analytics),
                      const SizedBox(height: AppSpacing.xl),
                      const _QuickActionsCard(),
                      const SizedBox(height: AppSpacing.xl),
                      _OperationsSnapshot(analytics: analytics),
                      const SizedBox(height: AppSpacing.xl),
                      _AuditActivity(logs: controller.auditLogs),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _AuditActivity extends StatelessWidget {
  const _AuditActivity({required this.logs});

  final List<Map<String, Object?>> logs;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Security activity',
      subtitle: 'Recent administrative changes recorded for accountability.',
      child: logs.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text('No administrative changes have been recorded yet.'),
            )
          : Column(
              children: [
                for (var index = 0; index < logs.length; index++) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.history_rounded),
                    ),
                    title: Text(
                      logs[index]['description'] as String? ?? 'Admin change',
                    ),
                    subtitle: Text(
                      '${logs[index]['actor_name'] ?? 'Administrator'} • ${logs[index]['created_at'] ?? ''}',
                    ),
                    trailing: Chip(
                      label: Text(
                        (logs[index]['action'] as String? ?? 'change')
                            .toUpperCase(),
                      ),
                    ),
                  ),
                  if (index != logs.length - 1) const Divider(height: 1),
                ],
              ],
            ),
    );
  }
}

class _AnalyticsPreview extends StatelessWidget {
  const _AnalyticsPreview({required this.analytics});

  final AdminAnalyticsData? analytics;

  @override
  Widget build(BuildContext context) {
    final data = analytics;
    final trend = data?.marketTrend ?? const <MarketPriceTrendPoint>[];
    final resolutionRate = data == null || data.totalReports == 0
        ? 0.0
        : data.resolvedReports / data.totalReports * 100;

    return AdminSectionCard(
      title: 'Analytics preview',
      subtitle:
          'A live snapshot of market movement and moderation performance.',
      action: OutlinedButton.icon(
        onPressed: () => context.go('/admin/analytics'),
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('View full analytics'),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chart = _OverviewTrendChart(points: trend);
          final insights = Column(
            children: [
              _PreviewInsight(
                label: 'Above SRP records',
                value: '${data?.aboveSrpCount ?? 0}',
                caption: 'Entries requiring market review',
                icon: Icons.trending_up_rounded,
                color: AppColors.warning,
              ),
              const SizedBox(height: AppSpacing.sm),
              _PreviewInsight(
                label: 'Resolution rate',
                value: '${resolutionRate.toStringAsFixed(0)}%',
                caption: '${data?.resolvedReports ?? 0} resolved reports',
                icon: Icons.task_alt_rounded,
                color: const Color(0xFF0F9F7A),
              ),
              const SizedBox(height: AppSpacing.sm),
              _PreviewInsight(
                label: 'Fresh price updates',
                value: '${data?.latestUpdatesCount ?? 0}',
                caption: 'Recorded within the last 7 days',
                icon: Icons.bolt_rounded,
                color: const Color(0xFF3B82F6),
              ),
            ],
          );

          if (constraints.maxWidth < 980) {
            return Column(
              children: [
                chart,
                const SizedBox(height: AppSpacing.lg),
                insights,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: chart),
              const SizedBox(width: AppSpacing.xl),
              Expanded(flex: 3, child: insights),
            ],
          );
        },
      ),
    );
  }
}

class _OverviewTrendChart extends StatelessWidget {
  const _OverviewTrendChart({required this.points});
  final List<MarketPriceTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(child: Text('Price history will appear here.')),
      );
    }
    final values = points
        .expand((point) => [point.averagePrice, point.averageSrp])
        .toList();
    final lowest = values.reduce((a, b) => a < b ? a : b);
    final highest = values.reduce((a, b) => a > b ? a : b);
    final yPadding = ((highest - lowest).abs() * .18).clamp(4.0, 80.0);
    return Container(
      height: 290,
      padding: const EdgeInsets.fromLTRB(14, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? AppColors.surfaceMutedFor(context)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: points.length > 1 ? (points.length - 1).toDouble() : 1,
          minY: (lowest - yPadding).clamp(0, double.infinity),
          maxY: highest + yPadding,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.borderFor(context), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  if (!_showDateLabel(index, points.length)) {
                    return const SizedBox.shrink();
                  }
                  final date = points[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(
                      '${date.month}/${date.day}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, _) => Text(
                  value.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
          lineBarsData: [
            _line(
              points.map((item) => item.averagePrice).toList(),
              const Color(0xFFE11D67),
              true,
              false,
            ),
            _line(
              points.map((item) => item.averageSrp).toList(),
              AppColors.warning,
              false,
              true,
            ),
          ],
        ),
      ),
    );
  }

  bool _showDateLabel(int index, int length) {
    if (length <= 5) return true;
    final step = (length - 1) / 4;
    return List.generate(5, (item) => (item * step).round()).contains(index);
  }

  LineChartBarData _line(
    List<double> values,
    Color color,
    bool fill,
    bool dashed,
  ) => LineChartBarData(
    spots: List.generate(
      values.length,
      (index) => FlSpot(index.toDouble(), values[index]),
    ),
    isCurved: true,
    curveSmoothness: .22,
    preventCurveOverShooting: true,
    color: color,
    barWidth: 3,
    dashArray: dashed ? [8, 5] : null,
    dotData: FlDotData(show: values.length <= 12),
    belowBarData: BarAreaData(show: fill, color: color.withValues(alpha: .08)),
  );
}

class _PreviewInsight extends StatelessWidget {
  const _PreviewInsight({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: .16)),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      radius: 20,
      padding: const EdgeInsets.all(20),
      gradient: AppColors.isDark(context)
          ? null
          : const LinearGradient(colors: [Colors.white, Color(0xFFFBFCFE)]),
      borderColor: AppColors.isDark(context) ? null : const Color(0xFFE2E8F0),
      shadowColor: AppColors.isDark(context) ? null : const Color(0x140F172A),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryFor(context),
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

class _DashboardSummaryCard extends StatelessWidget {
  const _DashboardSummaryCard({required this.analytics});

  final AdminAnalyticsData? analytics;

  @override
  Widget build(BuildContext context) {
    final topStore = analytics?.topReportedStores.isNotEmpty == true
        ? analytics!.topReportedStores.first
        : null;

    return AppSurfaceCard(
      radius: 26,
      padding: const EdgeInsets.all(AppSpacing.xl),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF111C35), Color(0xFF1B2D4D), Color(0xFF263E65)],
      ),
      borderColor: Colors.transparent,
      shadowColor: const Color(0x220F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workspace summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            analytics == null
                ? 'Analytics will appear here once local data is loaded.'
                : '${analytics!.pendingReports} reports still need review and ${analytics!.latestUpdatesCount} recent price entries are already available.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top reported store',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        topStore == null
                            ? 'No report data yet'
                            : '${topStore.storeName} (${topStore.count})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    final webLayout = useAdminWebLayout(context);

    return AdminSectionCard(
      title: 'Quick actions',
      subtitle: 'Most-used admin shortcuts.',
      child: AdaptiveStatGrid(
        minTileWidth: 220,
        maxColumns: webLayout ? 3 : 1,
        children: [
          _QuickActionButton(
            label: 'Review reports',
            icon: Icons.flag_rounded,
            accent: AppColors.warning,
            description: 'Moderate pending community overpricing complaints.',
            onTap: () => context.go('/admin/reports'),
          ),
          _QuickActionButton(
            label: 'Add commodity price',
            icon: Icons.price_change_rounded,
            accent: AppColors.primary,
            description: 'Record a fresh local price update for a market.',
            onTap: () => context.go('/admin/prices'),
          ),
          _QuickActionButton(
            label: 'Open analytics',
            icon: Icons.query_stats_rounded,
            accent: AppColors.sky,
            description: 'Review category averages and report activity.',
            onTap: () => context.go('/admin/analytics'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.description,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      onTap: onTap,
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.arrow_forward_rounded, color: accent),
        ],
      ),
    );
  }
}

class _OperationsSnapshot extends StatelessWidget {
  const _OperationsSnapshot({required this.analytics});

  final AdminAnalyticsData? analytics;

  @override
  Widget build(BuildContext context) {
    final categories =
        analytics?.categoryAverages ?? const <CategoryPriceAverage>[];
    final highestPrice = categories.fold<double>(1, (highest, item) {
      final categoryHigh = item.averagePrice > item.averageSrp
          ? item.averagePrice
          : item.averageSrp;
      return categoryHigh > highest ? categoryHigh : highest;
    });

    return AdminSectionCard(
      title: 'Category price vs SRP',
      subtitle:
          'Compare the latest category market averages with published suggested retail prices.',
      action: OutlinedButton.icon(
        onPressed: () => context.go('/admin/analytics'),
        icon: const Icon(Icons.analytics_outlined),
        label: const Text('Open analytics'),
      ),
      child: categories.isEmpty
          ? const _CategoryComparisonEmpty()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 18,
                  runSpacing: 10,
                  children: const [
                    _ComparisonLegend(
                      color: Color(0xFF3B82F6),
                      label: 'Market average',
                    ),
                    _ComparisonLegend(
                      color: AppColors.warning,
                      label: 'Average SRP',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900 ? 2 : 1;
                    const gap = 14.0;
                    final width = columns == 1
                        ? constraints.maxWidth
                        : (constraints.maxWidth - gap) / 2;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final item in categories)
                          SizedBox(
                            width: width,
                            child: _CategoryComparisonTile(
                              item: item,
                              maxValue: highestPrice,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _ComparisonLegend extends StatelessWidget {
  const _ComparisonLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 7),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _CategoryComparisonTile extends StatelessWidget {
  const _CategoryComparisonTile({required this.item, required this.maxValue});

  final CategoryPriceAverage item;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final above = item.variance > 0.005;
    final below = item.variance < -0.005;
    final varianceColor = above
        ? AppColors.warning
        : below
        ? const Color(0xFF0F9F7A)
        : AppColors.sky;
    final varianceLabel = above
        ? '${item.variancePercent.toStringAsFixed(1)}% above SRP'
        : below
        ? '${item.variancePercent.abs().toStringAsFixed(1)}% below SRP'
        : 'At SRP';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.categoryName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: varianceColor.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: varianceColor.withValues(alpha: .24),
                  ),
                ),
                child: Text(
                  varianceLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: varianceColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _PriceComparisonBar(
            label: 'Market',
            value: item.averagePrice,
            maxValue: maxValue,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 11),
          _PriceComparisonBar(
            label: 'SRP',
            value: item.averageSrp,
            maxValue: maxValue,
            color: AppColors.warning,
          ),
          const SizedBox(height: 12),
          Text(
            '${item.commodityCount} commodities • ${item.priceRecordCount} latest store records',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceComparisonBar extends StatelessWidget {
  const _PriceComparisonBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final double value;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (value / maxValue).clamp(0.0, 1.0),
                minHeight: 9,
                color: color,
                backgroundColor: AppColors.borderFor(context),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 78,
            child: Text(
              AppFormatters.currency(value),
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ],
  );
}

class _CategoryComparisonEmpty extends StatelessWidget {
  const _CategoryComparisonEmpty();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Text(
        'Category comparisons will appear after price records are added.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ),
  );
}
