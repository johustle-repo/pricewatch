import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/models/ui_models.dart';
import '../../../../shared/widgets/adaptive_stat_grid.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../controllers/admin_controller.dart';
import '../../data/admin_export_service.dart';
import '../widgets/admin_page_frame.dart';
import '../widgets/admin_workspace_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
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
      appBar: webLayout ? null : AppBar(title: const Text('Analytics')),
      body: AppBackground(
        showTopGlow: false,
        child: controller.isLoading && analytics == null
            ? const ListLoadingView(cardCount: 5)
            : analytics == null
            ? const EmptyStateView(
                title: 'Analytics unavailable',
                message: 'No analytics could be generated right now.',
                icon: Icons.query_stats_outlined,
              )
            : RefreshIndicator(
                onRefresh: () =>
                    context.read<AdminController>().loadAnalytics(),
                child: AdminPageFrame(
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
                        eyebrow: 'Market intelligence',
                        title: 'Analytics dashboard',
                        subtitle:
                            'Monitor price movement, SRP compliance, community reports, and market health from synchronized Firebase and offline data.',
                        icon: Icons.query_stats_rounded,
                        action: Wrap(
                          spacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => context
                                  .read<AdminController>()
                                  .loadAnalytics(),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Refresh'),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Export analytics',
                              onSelected: (format) =>
                                  _exportAnalytics(format, analytics),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'pdf',
                                  child: Text('Export PDF'),
                                ),
                                PopupMenuItem(
                                  value: 'xlsx',
                                  child: Text('Export Excel'),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.download_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 7),
                                    Text(
                                      'Export',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        metrics: [
                          AdminHeaderMetric(
                            label: 'Tracked reports',
                            value: '${analytics.totalReports}',
                            icon: Icons.flag_outlined,
                            accent: AppColors.warning,
                          ),
                          AdminHeaderMetric(
                            label: 'Watched items',
                            value: '${analytics.watchedItemsCount}',
                            icon: Icons.bookmark_added_outlined,
                            accent: AppColors.primaryDark,
                          ),
                          AdminHeaderMetric(
                            label: 'Fresh updates',
                            value: '${analytics.latestUpdatesCount}',
                            icon: Icons.bolt_rounded,
                            accent: AppColors.sky,
                          ),
                        ],
                      ),
                      if (controller.error != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        AdminErrorBanner(message: controller.error!),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      AdaptiveStatGrid(
                        minTileWidth: 200,
                        maxColumns: webLayout ? 4 : 2,
                        children: [
                          StatCard(
                            title: 'Above SRP now',
                            value: '${analytics.aboveSrpCount}',
                            icon: Icons.trending_up_rounded,
                            highlight: true,
                          ),
                          StatCard(
                            title: 'SRP compliance',
                            value:
                                '${analytics.complianceRate.toStringAsFixed(1)}%',
                            icon: Icons.verified_outlined,
                          ),
                          StatCard(
                            title: 'Stale price records',
                            value: '${analytics.staleCount}',
                            icon: Icons.schedule_outlined,
                          ),
                          StatCard(
                            title: 'Pending reports',
                            value: '${analytics.pendingReports}',
                            icon: Icons.pending_actions_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _MarketTrendChart(analytics: analytics),
                      const SizedBox(height: AppSpacing.xl),
                      _CommodityMonitoringTable(analytics: analytics),
                      const SizedBox(height: AppSpacing.xl),
                      _CategoryAverageChart(analytics: analytics),
                      const SizedBox(height: AppSpacing.xl),
                      _TopReportedStoresCard(analytics: analytics),
                      const SizedBox(height: AppSpacing.lg),
                      _LocationInsightsCard(analytics: analytics),
                      const SizedBox(height: AppSpacing.lg),
                      _StatusDistributionCard(analytics: analytics),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _exportAnalytics(
    String format,
    AdminAnalyticsData analytics,
  ) async {
    const headers = ['Section', 'Metric', 'Value'];
    final rows = <List<Object?>>[
      ['Summary', 'Total reports', analytics.totalReports],
      ['Summary', 'Pending reports', analytics.pendingReports],
      ['Summary', 'Reviewed reports', analytics.reviewedReports],
      ['Summary', 'Resolved reports', analytics.resolvedReports],
      ['Summary', 'Watched items', analytics.watchedItemsCount],
      ['Summary', 'Fresh updates', analytics.latestUpdatesCount],
      ['Summary', 'Above SRP entries', analytics.aboveSrpCount],
      ['Summary', 'SRP compliant entries', analytics.compliantCount],
      ['Summary', 'Compliance rate', analytics.complianceRate],
      ['Summary', 'Stale latest records', analytics.staleCount],
      ['Summary', 'Latest monitored records', analytics.monitoredPriceCount],
      ['Summary', 'Highest price', analytics.highestPrice],
      ['Summary', 'Lowest price', analytics.lowestPrice],
      ...analytics.categoryAverages.map(
        (item) => ['Category average', item.categoryName, item.averagePrice],
      ),
      ...analytics.topReportedStores.map(
        (item) => ['Top reported store', item.storeName, item.count],
      ),
      ...analytics.statusBreakdown.map(
        (item) => ['Report status', item.status, item.count],
      ),
      ...analytics.locationInsights.map(
        (item) => [
          'Location',
          item.location,
          '${item.storeCount} stores; ${item.reportCount} reports; ${item.priceUpdateCount} updates',
        ],
      ),
      ...analytics.marketTrend.map(
        (item) => [
          'Market trend',
          DateFormat('yyyy-MM-dd').format(item.date),
          'Price ${item.averagePrice.toStringAsFixed(2)}; SRP ${item.averageSrp.toStringAsFixed(2)}',
        ],
      ),
      ...analytics.commodityMonitoring.map(
        (item) => [
          'Commodity monitoring',
          item.commodityName,
          'Average ${item.averagePrice.toStringAsFixed(2)}; SRP ${item.srp.toStringAsFixed(2)}; variance ${item.variancePercent.toStringAsFixed(1)}%; ${item.storeCount} stores; ${item.isStale ? 'stale' : 'current'}',
        ],
      ),
    ];
    if (format == 'pdf') {
      await AdminExportService.savePdf(
        title: 'PriceWatch Analytics Report',
        filePrefix: 'pricewatch_analytics',
        headers: headers,
        rows: rows,
      );
    } else {
      await AdminExportService.saveXlsx(
        sheetName: 'Analytics',
        filePrefix: 'pricewatch_analytics',
        headers: headers,
        rows: rows,
      );
    }
  }
}

class _CommodityMonitoringTable extends StatelessWidget {
  const _CommodityMonitoringTable({required this.analytics});

  final AdminAnalyticsData analytics;

  @override
  Widget build(BuildContext context) {
    final rows = analytics.commodityMonitoring;
    return AdminSectionCard(
      title: 'Commodity compliance monitor',
      subtitle:
          'Latest average price per commodity across stores, compared with published SRP.',
      action: AppStatusBadge(
        label: '${rows.length} commodities',
        color: AppColors.primaryDark,
        icon: Icons.monitor_heart_outlined,
      ),
      child: rows.isEmpty
          ? const EmptyStateView(
              title: 'No prices to monitor',
              message:
                  'Import price entries to generate compliance monitoring.',
              icon: Icons.query_stats_outlined,
            )
          : AdminDataTableCard(
              minWidth: 1040,
              columns: const [
                'Commodity',
                'Category',
                'Average',
                'SRP',
                'Variance',
                'Stores',
                'Freshness',
                'Last updated',
              ],
              rows: [
                for (final item in rows)
                  DataRow(
                    cells: [
                      DataCell(
                        Text(
                          item.commodityName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      DataCell(Text(item.categoryName)),
                      DataCell(Text(AppFormatters.currency(item.averagePrice))),
                      DataCell(Text(AppFormatters.currency(item.srp))),
                      DataCell(
                        AppStatusBadge(
                          label:
                              '${item.variance >= 0 ? '+' : ''}${item.variancePercent.toStringAsFixed(1)}%',
                          color: item.isAboveSrp
                              ? AppColors.warning
                              : const Color(0xFF0F9F7A),
                          icon: item.isAboveSrp
                              ? Icons.trending_up_rounded
                              : Icons.check_rounded,
                        ),
                      ),
                      DataCell(Text('${item.storeCount}')),
                      DataCell(
                        AppStatusBadge(
                          label: item.isStale ? 'STALE' : 'CURRENT',
                          color: item.isStale
                              ? AppColors.warning
                              : const Color(0xFF0F9F7A),
                          icon: item.isStale
                              ? Icons.schedule_outlined
                              : Icons.bolt_rounded,
                        ),
                      ),
                      DataCell(
                        Text(
                          DateFormat(
                            'MMM d, y | h:mm a',
                          ).format(DateTime.parse(item.lastUpdated).toLocal()),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}

class _MarketTrendChart extends StatelessWidget {
  const _MarketTrendChart({required this.analytics});

  final AdminAnalyticsData analytics;

  @override
  Widget build(BuildContext context) {
    final points = analytics.marketTrend;
    return AdminSectionCard(
      title: '30-day market price movement',
      subtitle:
          'Daily average selling price compared with the daily average SRP.',
      action: const AppStatusBadge(
        label: 'Live market trend',
        color: AppColors.primaryDark,
        icon: Icons.show_chart_rounded,
      ),
      child: points.isEmpty
          ? const EmptyStateView(
              title: 'No price history yet',
              message: 'Recorded commodity prices will build this trend.',
              icon: Icons.timeline_rounded,
            )
          : SizedBox(
              height: 330,
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.borderFor(context),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 58,
                        getTitlesWidget: (value, _) => Text(
                          value.toStringAsFixed(0),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: points.length > 10 ? 5 : 1,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM d').format(points[index].date),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots
                          .map(
                            (spot) => LineTooltipItem(
                              AppFormatters.currency(spot.y),
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    _trendBar(
                      points.map((item) => item.averagePrice).toList(),
                      AppColors.primaryDark,
                    ),
                    _trendBar(
                      points.map((item) => item.averageSrp).toList(),
                      AppColors.warning,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  LineChartBarData _trendBar(List<double> values, Color color) =>
      LineChartBarData(
        spots: List.generate(
          values.length,
          (index) => FlSpot(index.toDouble(), values[index]),
        ),
        isCurved: true,
        color: color,
        barWidth: 3,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.08),
        ),
      );
}

class _CategoryAverageChart extends StatelessWidget {
  const _CategoryAverageChart({required this.analytics});

  final AdminAnalyticsData analytics;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Average price by category',
      subtitle: 'Current average market price derived from stored entries.',
      child: SizedBox(
        height: 320,
        child: BarChart(
          BarChartData(
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.borderFor(
                  context,
                ).withValues(alpha: AppColors.isDark(context) ? 0.7 : 1),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 58,
                  getTitlesWidget: (value, _) => Text(
                    value.toStringAsFixed(0),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final index = value.toInt();
                    if (index < 0 ||
                        index >= analytics.categoryAverages.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        analytics.categoryAverages[index].categoryName
                            .split(' ')
                            .first,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryFor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: List.generate(
              analytics.categoryAverages.length,
              (index) => BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: analytics.categoryAverages[index].averagePrice,
                    gradient: AppColors.primaryGradient,
                    width: 18,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopReportedStoresCard extends StatelessWidget {
  const _TopReportedStoresCard({required this.analytics});

  final AdminAnalyticsData analytics;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Top reported stores',
      subtitle: 'Stores most often flagged by the local community.',
      action: AppStatusBadge(
        label: '${analytics.topReportedStores.length} stores',
        color: AppColors.warning,
        icon: Icons.storefront_outlined,
      ),
      child: Column(
        children: [
          for (final item in analytics.topReportedStores) ...[
            _InlineInsightRow(
              label: item.storeName,
              value: '${item.count} reports',
              accent: AppColors.warning,
            ),
            if (item != analytics.topReportedStores.last)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _LocationInsightsCard extends StatelessWidget {
  const _LocationInsightsCard({required this.analytics});

  final AdminAnalyticsData analytics;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Market activity by location',
      subtitle:
          'Store coverage, community reports, and recorded price updates grouped by city.',
      action: AppStatusBadge(
        label: '${analytics.locationInsights.length} locations',
        color: AppColors.sky,
        icon: Icons.location_city_outlined,
      ),
      child: analytics.locationInsights.isEmpty
          ? const EmptyStateView(
              title: 'No location data',
              message:
                  'Add a city to store records to build location insights.',
              icon: Icons.location_off_outlined,
            )
          : Column(
              children: [
                for (final item in analytics.locationInsights) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMutedFor(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderFor(context)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.sky.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.sky,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.location,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${item.storeCount} stores · ${item.reportCount} reports · ${item.priceUpdateCount} price updates',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item != analytics.locationInsights.last)
                    const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _StatusDistributionCard extends StatelessWidget {
  const _StatusDistributionCard({required this.analytics});

  final AdminAnalyticsData analytics;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Report status distribution',
      subtitle: 'How report volume is spread across the workflow.',
      child: Column(
        children: [
          for (final item in analytics.statusBreakdown) ...[
            _InlineInsightRow(
              label: item.status.toUpperCase(),
              value: '${item.count}',
              accent: _accentForStatus(item.status),
            ),
            if (item != analytics.statusBreakdown.last)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  Color _accentForStatus(String status) {
    switch (status) {
      case 'resolved':
        return AppColors.primaryDark;
      case 'reviewed':
        return AppColors.sky;
      default:
        return AppColors.warning;
    }
  }
}

class _InlineInsightRow extends StatelessWidget {
  const _InlineInsightRow({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMutedFor(
          context,
        ).withValues(alpha: AppColors.isDark(context) ? 0.92 : 1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryFor(context),
            ),
          ),
        ],
      ),
    );
  }
}
