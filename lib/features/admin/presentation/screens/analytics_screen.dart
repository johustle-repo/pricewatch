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
                        webActionAtTop: true,
                        action: SizedBox(
                          width: webLayout ? 220 : double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => context
                                    .read<AdminController>()
                                    .loadAnalytics(),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Refresh'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: webLayout
                                      ? Colors.white
                                      : null,
                                  side: webLayout
                                      ? const BorderSide(
                                          color: Color(0xFF8190AA),
                                        )
                                      : null,
                                  minimumSize: const Size.fromHeight(48),
                                ),
                              ),
                              const SizedBox(height: 10),
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
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryDark,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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

enum _TrendInterval { day, week, month, year }

class _MarketTrendChart extends StatefulWidget {
  const _MarketTrendChart({required this.analytics});

  final AdminAnalyticsData analytics;

  @override
  State<_MarketTrendChart> createState() => _MarketTrendChartState();
}

class _MarketTrendChartState extends State<_MarketTrendChart> {
  _TrendInterval _interval = _TrendInterval.day;
  int? _commodityId;
  int? _storeId;

  @override
  Widget build(BuildContext context) {
    final trends = widget.analytics.commodityPriceTrends;
    final selectedTrend = trends.isEmpty
        ? null
        : trends
                  .where((item) => item.commodityId == _commodityId)
                  .firstOrNull ??
              trends.reduce(
                (current, next) => next.history.length > current.history.length
                    ? next
                    : current,
              );
    final history = selectedTrend == null
        ? const <CommodityPriceHistoryPoint>[]
        : selectedTrend.history;
    final marketPoints = selectedTrend == null
        ? const <MarketPriceTrendPoint>[]
        : _aggregate(history, selectedTrend.srp, _interval);
    final selectedStoreHistory = _storeId == null
        ? const <CommodityPriceHistoryPoint>[]
        : history.where((point) => point.storeId == _storeId).toList();
    final storePoints = selectedTrend == null || _storeId == null
        ? const <MarketPriceTrendPoint>[]
        : _aggregate(selectedStoreHistory, selectedTrend.srp, _interval);
    final selectedStoreName = selectedStoreHistory.firstOrNull?.storeName;
    final displayedPoints = storePoints.isEmpty ? marketPoints : storePoints;
    final chartDates = [
      ...marketPoints,
      ...storePoints,
    ].map((point) => point.date).toSet().toList()..sort();
    final values = [
      ...marketPoints.map((point) => point.averagePrice),
      ...storePoints.map((point) => point.averagePrice),
      if (selectedTrend != null) selectedTrend.srp,
    ];
    final lowest = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a < b ? a : b);
    final highest = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b);
    final padding = ((highest - lowest).abs() * .18).clamp(4.0, 80.0);
    final firstDateX = chartDates.isEmpty ? 0.0 : _dateX(chartDates.first);
    final lastDateX = chartDates.isEmpty ? 1.0 : _dateX(chartDates.last);
    return AdminSectionCard(
      title: selectedTrend == null
          ? 'Commodity price history'
          : '${selectedTrend.commodityName} price history',
      subtitle:
          '${_windowDescription(_interval)} Market average and optional store '
          'price per ${selectedTrend?.unit ?? 'unit'}, compared with SRP.',
      action: SegmentedButton<_TrendInterval>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: _TrendInterval.day, label: Text('Day')),
          ButtonSegment(value: _TrendInterval.week, label: Text('Week')),
          ButtonSegment(value: _TrendInterval.month, label: Text('Month')),
          ButtonSegment(value: _TrendInterval.year, label: Text('Year')),
        ],
        selected: {_interval},
        onSelectionChanged: (selection) {
          setState(() => _interval = selection.first);
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(
            Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ),
      child: selectedTrend == null
          ? const EmptyStateView(
              title: 'No price history yet',
              message: 'Recorded commodity prices will build this trend.',
              icon: Icons.timeline_rounded,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TrendFilters(
                  trends: trends,
                  selectedCommodityId: selectedTrend.commodityId,
                  selectedStoreId: _storeId,
                  onCommodityChanged: (value) => setState(() {
                    _commodityId = value;
                    _storeId = null;
                  }),
                  onStoreChanged: (value) => setState(() => _storeId = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (marketPoints.isEmpty)
                  const EmptyStateView(
                    title: 'No matching price records',
                    message:
                        'This commodity and store do not have records for the selected view.',
                    icon: Icons.filter_alt_off_rounded,
                  )
                else ...[
                  _TrendSummary(
                    points: displayedPoints,
                    unit: selectedTrend.unit,
                    scopeLabel: selectedStoreName ?? 'Market average',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PriceHistoryLegend(
                    showStore: storePoints.isNotEmpty,
                    storeName: selectedStoreName,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 390,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final requiredWidth = chartDates.length * 110.0;
                        final chartWidth = requiredWidth > constraints.maxWidth
                            ? requiredWidth
                            : constraints.maxWidth;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: chartWidth,
                            height: 380,
                            child: LineChart(
                              LineChartData(
                                minX: chartDates.length > 1
                                    ? firstDateX
                                    : firstDateX - 1,
                                maxX: chartDates.length > 1
                                    ? lastDateX
                                    : firstDateX + 1,
                                minY: (lowest - padding).clamp(
                                  0,
                                  double.infinity,
                                ),
                                maxY: highest + padding,
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border(
                                    left: BorderSide(
                                      color: AppColors.borderFor(context),
                                    ),
                                    bottom: BorderSide(
                                      color: AppColors.borderFor(context),
                                    ),
                                  ),
                                ),
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
                                    axisNameSize: 24,
                                    axisNameWidget: Text(
                                      'Price (PHP)',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 58,
                                      getTitlesWidget: (value, _) => Text(
                                        value.toStringAsFixed(0),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    axisNameSize: 24,
                                    axisNameWidget: Text(
                                      'Date',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      reservedSize: 58,
                                      getTitlesWidget: (value, _) {
                                        final date = chartDates
                                            .where(
                                              (date) =>
                                                  (_dateX(date) - value).abs() <
                                                  .02,
                                            )
                                            .firstOrNull;
                                        if (date == null) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 10,
                                          ),
                                          child: Transform.rotate(
                                            angle: -.48,
                                            child: Text(
                                              _axisDate(date, _interval),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    maxContentWidth: 240,
                                    fitInsideHorizontally: true,
                                    fitInsideVertically: true,
                                    tooltipPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    tooltipMargin: 12,
                                    tooltipBorderRadius: BorderRadius.circular(
                                      12,
                                    ),
                                    tooltipBorder: const BorderSide(
                                      color: Color(0xFF64748B),
                                    ),
                                    getTooltipColor: (_) =>
                                        const Color(0xFF1E293B),
                                    getTooltipItems: (spots) => spots.map((
                                      spot,
                                    ) {
                                      final date = chartDates.reduce(
                                        (current, next) =>
                                            (_dateX(next) - spot.x).abs() <
                                                (_dateX(current) - spot.x).abs()
                                            ? next
                                            : current,
                                      );
                                      final series = spot.barIndex == 0
                                          ? 'Market average'
                                          : spot.barIndex == 1 &&
                                                storePoints.isNotEmpty
                                          ? selectedStoreName ?? 'Store price'
                                          : 'Published SRP';
                                      final seriesPoints = spot.barIndex == 0
                                          ? marketPoints
                                          : spot.barIndex == 1 &&
                                                storePoints.isNotEmpty
                                          ? storePoints
                                          : const <MarketPriceTrendPoint>[];
                                      final movement = _movementAt(
                                        seriesPoints,
                                        date,
                                      );
                                      return LineTooltipItem(
                                        '$series: ${AppFormatters.currency(spot.y)}\n'
                                        '${_tooltipDate(date, _interval)}'
                                        '${movement == null ? '' : '\nChange: $movement'}',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          height: 1.35,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                lineBarsData: [
                                  _trendBar(
                                    marketPoints,
                                    (point) => point.averagePrice,
                                    const Color(0xFF2563EB),
                                    false,
                                    selectedTrend.srp,
                                  ),
                                  if (storePoints.isNotEmpty)
                                    _trendBar(
                                      storePoints,
                                      (point) => point.averagePrice,
                                      const Color(0xFFDB2777),
                                      false,
                                      selectedTrend.srp,
                                    ),
                                  _trendBar(
                                    chartDates
                                        .map(
                                          (date) => MarketPriceTrendPoint(
                                            date: date,
                                            averagePrice: selectedTrend.srp,
                                            averageSrp: selectedTrend.srp,
                                          ),
                                        )
                                        .toList(),
                                    (point) => point.averageSrp,
                                    AppColors.warning,
                                    true,
                                    null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  LineChartBarData _trendBar(
    List<MarketPriceTrendPoint> points,
    double Function(MarketPriceTrendPoint point) valueOf,
    Color color,
    bool dashed,
    double? benchmark,
  ) => LineChartBarData(
    spots: points
        .map((point) => FlSpot(_dateX(point.date), valueOf(point)))
        .toList(),
    isCurved: true,
    curveSmoothness: .22,
    preventCurveOverShooting: true,
    color: color,
    barWidth: 3,
    dashArray: dashed ? [8, 5] : null,
    dotData: FlDotData(
      show: !dashed,
      getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
        radius: 4,
        color: Colors.white,
        strokeWidth: 2,
        strokeColor: benchmark != null && spot.y > benchmark
            ? AppColors.warning
            : color,
      ),
    ),
    belowBarData: BarAreaData(show: false),
  );

  double _dateX(DateTime date) =>
      date.millisecondsSinceEpoch / Duration.millisecondsPerDay;

  String? _movementAt(List<MarketPriceTrendPoint> points, DateTime date) {
    final index = points.indexWhere((point) => point.date == date);
    if (index <= 0) return null;
    final current = points[index].averagePrice;
    final previous = points[index - 1].averagePrice;
    final difference = current - previous;
    final percent = previous == 0 ? 0.0 : difference / previous * 100;
    final sign = difference > 0 ? '+' : '';
    return '$sign${AppFormatters.currency(difference)} '
        '($sign${percent.toStringAsFixed(1)}%)';
  }

  List<MarketPriceTrendPoint> _aggregate(
    List<CommodityPriceHistoryPoint> source,
    double srp,
    _TrendInterval interval,
  ) {
    final buckets = <DateTime, _TrendBucket>{};
    for (final point in source) {
      final key = switch (interval) {
        _TrendInterval.day => DateTime(
          point.date.year,
          point.date.month,
          point.date.day,
        ),
        _TrendInterval.week => DateTime(
          point.date.year,
          point.date.month,
          point.date.day,
        ).subtract(Duration(days: point.date.weekday - 1)),
        _TrendInterval.month => DateTime(point.date.year, point.date.month),
        _TrendInterval.year => DateTime(point.date.year),
      };
      buckets.putIfAbsent(key, _TrendBucket.new).add(point.price, srp);
    }

    final result =
        buckets.entries
            .map(
              (entry) => MarketPriceTrendPoint(
                date: entry.key,
                averagePrice: entry.value.priceTotal / entry.value.count,
                averageSrp: entry.value.srpTotal / entry.value.count,
              ),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final limit = switch (interval) {
      _TrendInterval.day => 30,
      _TrendInterval.week => 12,
      _TrendInterval.month => 12,
      _TrendInterval.year => 5,
    };
    return result.length <= limit
        ? result
        : result.sublist(result.length - limit);
  }

  String _windowDescription(_TrendInterval interval) => switch (interval) {
    _TrendInterval.day => 'Latest 30 daily reporting points.',
    _TrendInterval.week => 'Latest 12 weekly averages.',
    _TrendInterval.month => 'Latest 12 monthly averages.',
    _TrendInterval.year => 'Latest 5 yearly averages.',
  };

  String _axisDate(DateTime date, _TrendInterval interval) =>
      switch (interval) {
        _TrendInterval.day => DateFormat('MMM d').format(date),
        _TrendInterval.week => DateFormat('MMM d').format(date),
        _TrendInterval.month => DateFormat('MMM yy').format(date),
        _TrendInterval.year => DateFormat('yyyy').format(date),
      };

  String _tooltipDate(DateTime date, _TrendInterval interval) =>
      switch (interval) {
        _TrendInterval.day => DateFormat('MMM d, y').format(date),
        _TrendInterval.week => 'Week of ${DateFormat('MMM d, y').format(date)}',
        _TrendInterval.month => DateFormat('MMMM y').format(date),
        _TrendInterval.year => DateFormat('yyyy').format(date),
      };
}

class _TrendBucket {
  double priceTotal = 0;
  double srpTotal = 0;
  int count = 0;

  void add(double price, double srp) {
    priceTotal += price;
    srpTotal += srp;
    count++;
  }
}

class _TrendFilters extends StatelessWidget {
  const _TrendFilters({
    required this.trends,
    required this.selectedCommodityId,
    required this.selectedStoreId,
    required this.onCommodityChanged,
    required this.onStoreChanged,
  });

  final List<CommodityPriceTrend> trends;
  final int selectedCommodityId;
  final int? selectedStoreId;
  final ValueChanged<int> onCommodityChanged;
  final ValueChanged<int?> onStoreChanged;

  @override
  Widget build(BuildContext context) {
    final selected = trends.firstWhere(
      (item) => item.commodityId == selectedCommodityId,
    );
    final stores = <int, String>{
      for (final point in selected.history) point.storeId: point.storeName,
    };
    final storeItems = stores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth = constraints.maxWidth >= 720
            ? (constraints.maxWidth - AppSpacing.md) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: fieldWidth,
              child: DropdownButtonFormField<int>(
                initialValue: selectedCommodityId,
                decoration: const InputDecoration(
                  labelText: 'Commodity',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                isExpanded: true,
                items: trends
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.commodityId,
                        child: Text(
                          '${item.commodityName} | ${item.unit}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onCommodityChanged(value);
                },
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: DropdownButtonFormField<int?>(
                initialValue: selectedStoreId,
                decoration: const InputDecoration(
                  labelText: 'Store comparison',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Market average only'),
                  ),
                  ...storeItems.map(
                    (item) => DropdownMenuItem<int?>(
                      value: item.key,
                      child: Text(item.value, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: onStoreChanged,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrendSummary extends StatelessWidget {
  const _TrendSummary({
    required this.points,
    required this.unit,
    required this.scopeLabel,
  });

  final List<MarketPriceTrendPoint> points;
  final String unit;
  final String scopeLabel;

  @override
  Widget build(BuildContext context) {
    final prices = points.map((point) => point.averagePrice).toList();
    final current = prices.last;
    final previous = prices.length > 1 ? prices[prices.length - 2] : current;
    final change = previous == 0 ? 0.0 : (current - previous) / previous * 100;
    final low = prices.reduce((a, b) => a < b ? a : b);
    final high = prices.reduce((a, b) => a > b ? a : b);
    final srp = points.last.averageSrp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _TrendMetric(
              label: '$scopeLabel / $unit',
              value: AppFormatters.currency(current),
            ),
            _TrendMetric(
              label: 'Published SRP',
              value: AppFormatters.currency(srp),
            ),
            _TrendMetric(
              label: 'Period low',
              value: AppFormatters.currency(low),
            ),
            _TrendMetric(
              label: 'Period high',
              value: AppFormatters.currency(high),
            ),
            _TrendMetric(
              label: 'Latest change',
              value: '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
              valueColor: change > 0
                  ? AppColors.warning
                  : change < 0
                  ? const Color(0xFF0F9F7A)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _PriceHistoryLegend extends StatelessWidget {
  const _PriceHistoryLegend({required this.showStore, this.storeName});

  final bool showStore;
  final String? storeName;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.lg,
    runSpacing: AppSpacing.sm,
    children: [
      const _ChartLegend(
        color: Color(0xFF2563EB),
        label: 'Market average',
        showPoint: true,
      ),
      if (showStore)
        _ChartLegend(
          color: const Color(0xFFDB2777),
          label: storeName ?? 'Selected store',
          showPoint: true,
        ),
      const _ChartLegend(
        color: AppColors.warning,
        label: 'Published SRP',
        dashed: true,
      ),
    ],
  );
}

class _TrendMetric extends StatelessWidget {
  const _TrendMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 138),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: AppColors.surfaceMutedFor(context),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.borderFor(context)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({
    required this.color,
    required this.label,
    this.dashed = false,
    this.showPoint = false,
  });

  final Color color;
  final String label;
  final bool dashed;
  final bool showPoint;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 30,
        height: 12,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: List.generate(
                dashed ? 3 : 1,
                (_) => Expanded(
                  child: Container(
                    height: 3,
                    margin: dashed
                        ? const EdgeInsets.symmetric(horizontal: 2)
                        : EdgeInsets.zero,
                    color: color,
                  ),
                ),
              ),
            ),
            if (showPoint)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(width: 7),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _CategoryAverageChart extends StatelessWidget {
  const _CategoryAverageChart({required this.analytics});

  final AdminAnalyticsData analytics;

  @override
  Widget build(BuildContext context) {
    final items = analytics.categoryAverages;
    final highestValue = items.fold<double>(
      0,
      (highest, item) => [
        highest,
        item.averagePrice,
        item.averageSrp,
      ].reduce((a, b) => a > b ? a : b),
    );
    final maxY = highestValue <= 0
        ? 100.0
        : ((highestValue * 1.18) / 50).ceil() * 50.0;
    final interval = maxY / 5;

    return AdminSectionCard(
      title: 'Category price vs SRP',
      subtitle:
          'Latest market averages compared with the published suggested retail price.',
      action: const Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _ChartLegend(
            color: Color(0xFF3B82F6),
            label: 'Market average',
            showPoint: false,
          ),
          _ChartLegend(
            color: AppColors.warning,
            label: 'Average SRP',
            showPoint: false,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 340,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
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
                      interval: interval,
                      getTitlesWidget: (value, meta) => Text(
                        value == 0 ? '0' : '₱${value.toStringAsFixed(0)}',
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
                      reservedSize: 42,
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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondaryFor(context),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceFor(context),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = items[groupIndex];
                      final series = rodIndex == 0
                          ? 'Market average'
                          : 'Average SRP';
                      return BarTooltipItem(
                        '${item.categoryName}\n',
                        Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: AppColors.textPrimaryFor(context),
                          fontWeight: FontWeight.w800,
                        ),
                        children: [
                          TextSpan(
                            text: '$series: ${AppFormatters.currency(rod.toY)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondaryFor(context),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                barGroups: List.generate(
                  items.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barsSpace: 6,
                    barRods: [
                      BarChartRodData(
                        toY: items[index].averagePrice,
                        color: const Color(0xFF3B82F6),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                      BarChartRodData(
                        toY: items[index].averageSrp,
                        color: AppColors.warning,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map((item) {
              final isAbove = item.variance > 0.005;
              final isBelow = item.variance < -0.005;
              final accent = isAbove
                  ? AppColors.warning
                  : isBelow
                  ? AppColors.success
                  : AppColors.sky;
              final status = isAbove
                  ? '${item.variancePercent.toStringAsFixed(1)}% above SRP'
                  : isBelow
                  ? '${item.variancePercent.abs().toStringAsFixed(1)}% below SRP'
                  : 'At SRP';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.28)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.categoryName}  $status',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Based on ${items.fold<int>(0, (sum, item) => sum + item.priceRecordCount)} latest store price records across ${items.fold<int>(0, (sum, item) => sum + item.commodityCount)} tracked commodities.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
        ],
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
