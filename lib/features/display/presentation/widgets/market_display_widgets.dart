import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_seal_badge.dart';
import '../../../../shared/widgets/commodity_visual.dart';
import '../../domain/market_display_models.dart';

class MarketDisplayHeader extends StatelessWidget {
  const MarketDisplayHeader({
    super.key,
    required this.data,
    required this.currentTime,
    required this.onLogin,
    required this.onRefresh,
    required this.compact,
  });

  final MarketDisplayData data;
  final DateTime currentTime;
  final VoidCallback onLogin;
  final VoidCallback onRefresh;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat(
      compact ? 'MMM d, y | h:mm a' : 'EEEE, MMM d, y | h:mm a',
    ).format(currentTime);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.lg : AppSpacing.xl,
        vertical: compact ? AppSpacing.sm : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.isDark(context)
            ? AppColors.darkHeroGradient
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF101A31),
                  Color(0xFF172844),
                  Color(0xFF213857),
                ],
              ),
        borderRadius: BorderRadius.circular(compact ? 24 : 26),
        boxShadow: [
          BoxShadow(
            color: const Color(0x260F172A),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderBrand(data: data, compact: compact),
                const SizedBox(height: AppSpacing.md),
                _HeaderMeta(
                  currentTimeLabel: timeLabel,
                  lastUpdatedLabel: AppFormatters.dateTime(data.lastUpdatedAt),
                  onLogin: onLogin,
                  onRefresh: onRefresh,
                  compact: compact,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _HeaderBrand(data: data, compact: compact),
                ),
                const SizedBox(width: AppSpacing.sm),
                _HeaderMeta(
                  currentTimeLabel: timeLabel,
                  lastUpdatedLabel: AppFormatters.dateTime(data.lastUpdatedAt),
                  onLogin: onLogin,
                  onRefresh: onRefresh,
                  compact: compact,
                ),
              ],
            ),
    );
  }
}

class MarketDisplayGridPanel extends StatelessWidget {
  const MarketDisplayGridPanel({
    super.key,
    required this.data,
    required this.pageIndex,
    required this.itemsPerPage,
    required this.compact,
    required this.wideLayout,
    required this.stretchForMobile,
  });

  final MarketDisplayData data;
  final int pageIndex;
  final int itemsPerPage;
  final bool compact;
  final bool wideLayout;
  final bool stretchForMobile;

  @override
  Widget build(BuildContext context) {
    final panelColor = AppColors.surfaceFor(
      context,
    ).withValues(alpha: AppColors.isDark(context) ? 0.96 : 0.96);
    final visibleItems = _itemsForPage(
      data.items,
      pageIndex: pageIndex,
      itemsPerPage: itemsPerPage,
    );
    final pageCount = _resolvePageCount(data.items.length, itemsPerPage);
    final panelPadding = compact ? AppSpacing.lg : AppSpacing.xl;

    return Container(
      padding: EdgeInsets.fromLTRB(
        panelPadding,
        panelPadding,
        panelPadding,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(compact ? 24 : 26),
        border: Border.all(color: AppColors.borderFor(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowFor(context).withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PriceBoardSummary(
            data: data,
            pageIndex: pageIndex,
            pageCount: pageCount,
            visibleCount: visibleItems.length,
            compact: compact,
            wideLayout: wideLayout,
          ),
          const SizedBox(height: AppSpacing.md),
          if (visibleItems.isEmpty)
            SizedBox(
              height: 160,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      color: AppColors.textSecondaryFor(context),
                      size: 34,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No commodities match the selected filters.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          else if (stretchForMobile)
            _MobilePriceBoardList(items: visibleItems, compact: true)
          else if (wideLayout)
            Expanded(child: _DesktopPriceBoardTable(items: visibleItems))
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final phoneLayout = constraints.maxWidth < 720;
                  final spacing = compact ? AppSpacing.xs : AppSpacing.sm;

                  if (phoneLayout) {
                    return _MobilePriceBoardList(
                      items: visibleItems,
                      compact: true,
                    );
                  }

                  final columnCount = _resolveBoardColumnCount(
                    itemCount: visibleItems.length,
                  );
                  final columns = _splitItemsIntoColumns(
                    visibleItems,
                    columnCount,
                  );
                  final rowCount = columns.fold<int>(
                    0,
                    (maxCount, items) => math.max(maxCount, items.length),
                  );
                  final denseRows = compact || visibleItems.length > 9;
                  final availableRowHeight =
                      (constraints.maxHeight - (spacing * (rowCount - 1))) /
                      math.max(rowCount, 1);
                  final rowHeight = math.max(96.0, availableRowHeight);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var index = 0; index < columns.length; index++) ...[
                        Expanded(
                          child: Column(
                            children: [
                              for (
                                var itemIndex = 0;
                                itemIndex < columns[index].length;
                                itemIndex++
                              ) ...[
                                SizedBox(
                                  height: rowHeight,
                                  child: _PriceBoardRow(
                                    item: columns[index][itemIndex],
                                    compact: denseRows,
                                  ),
                                ),
                                if (itemIndex < columns[index].length - 1)
                                  SizedBox(height: spacing),
                              ],
                            ],
                          ),
                        ),
                        if (index < columns.length - 1)
                          SizedBox(width: spacing),
                      ],
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DesktopPriceBoardTable extends StatelessWidget {
  const _DesktopPriceBoardTable({required this.items});
  final List<MarketDisplayPriceItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 10000) {
          final columns = constraints.maxWidth >= 1750 ? 5 : 4;
          final rows = (items.length / columns).ceil().clamp(1, 4);
          final rowHeight = ((constraints.maxHeight - ((rows - 1) * 12)) / rows)
              .clamp(190.0, 280.0);
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: rowHeight,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _PublicPriceCard(item: items[index]),
          );
        }
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderFor(context)),
          ),
          child: Column(
            children: [
              const _PublicTableHeader(),
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: AppColors.borderFor(context)),
                  itemBuilder: (context, index) => ExpandedPriceTableRow(
                    item: items[index],
                    shaded: index.isOdd,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PublicPriceCard extends StatelessWidget {
  const _PublicPriceCard({required this.item});
  final MarketDisplayPriceItem item;

  @override
  Widget build(BuildContext context) {
    final delta = item.deltaFromPrevious;
    final trendColor = delta > 0
        ? AppColors.warningText
        : delta < 0
        ? AppColors.success
        : AppColors.info;
    final statusColor = item.isAboveSrp
        ? AppColors.warningText
        : item.isBelowSrp
        ? AppColors.success
        : AppColors.info;
    final status = item.isAboveSrp
        ? 'Above SRP'
        : item.isBelowSrp
        ? 'Below SRP'
        : 'At SRP';
    final prices = [item.previousPrice, item.currentPrice, item.srp];
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final padding = ((maxPrice - minPrice) * .2).clamp(2.0, 25.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final dense = constraints.maxHeight < 235;
        return Container(
          padding: EdgeInsets.all(dense ? 14 : 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: statusColor.withValues(alpha: .22)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x100F172A),
                blurRadius: 14,
                offset: Offset(0, 6),
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
                    label: item.commodityName,
                    category: item.categoryName,
                    size: 50,
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.categoryName} • ${item.unit}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _CompactStatus(label: status, color: statusColor),
                ],
              ),
              SizedBox(height: dense ? 8 : 11),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${delta > 0
                      ? '↗ +'
                      : delta < 0
                      ? '↘ -'
                      : '→ '}${_priceBoardCurrency(delta.abs())} vs previous',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: dense ? 8 : 12),
              Row(
                children: [
                  Expanded(
                    child: _PublicPriceMetric(
                      label: 'Current',
                      value: _priceBoardCurrency(item.currentPrice),
                    ),
                  ),
                  Expanded(
                    child: _PublicPriceMetric(
                      label: 'Previous',
                      value: _priceBoardCurrency(item.previousPrice),
                    ),
                  ),
                  Expanded(
                    child: _PublicPriceMetric(
                      label: 'SRP',
                      value: _priceBoardCurrency(item.srp),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (!dense)
                SizedBox(
                  height: 44,
                  child: LineChart(
                    LineChartData(
                      minY: minPrice - padding,
                      maxY: maxPrice + padding,
                      minX: 0,
                      maxX: 1,
                      clipData: const FlClipData.all(),
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [FlSpot(0, item.srp), FlSpot(1, item.srp)],
                          isCurved: false,
                          color: AppColors.textSecondaryFor(
                            context,
                          ).withValues(alpha: .6),
                          barWidth: 1,
                          dashArray: [4, 4],
                          dotData: const FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: [
                            FlSpot(0, item.previousPrice),
                            FlSpot(1, item.currentPrice),
                          ],
                          isCurved: false,
                          color: trendColor,
                          barWidth: 2.75,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: trendColor.withValues(alpha: .09),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!dense) const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'Previous',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondaryFor(context),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Latest • ${AppFormatters.dateTime(item.recordedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondaryFor(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompactStatus extends StatelessWidget {
  const _CompactStatus({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _PublicPriceMetric extends StatelessWidget {
  const _PublicPriceMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondaryFor(context),
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _PublicTableHeader extends StatelessWidget {
  const _PublicTableHeader();

  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    color: const Color(0xFF17233B),
    child: const Row(
      children: [
        Expanded(flex: 30, child: _HeaderCell('Commodity')),
        Expanded(flex: 16, child: _HeaderCell('Category')),
        Expanded(flex: 11, child: _HeaderCell('Unit')),
        Expanded(
          flex: 16,
          child: _HeaderCell('Market price', align: TextAlign.right),
        ),
        Expanded(flex: 14, child: _HeaderCell('SRP', align: TextAlign.right)),
        Expanded(
          flex: 16,
          child: _HeaderCell('Variance', align: TextAlign.right),
        ),
        Expanded(
          flex: 16,
          child: _HeaderCell('Status', align: TextAlign.center),
        ),
        Expanded(
          flex: 17,
          child: _HeaderCell('Last updated', align: TextAlign.right),
        ),
      ],
    ),
  );
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {this.align = TextAlign.left});
  final String label;
  final TextAlign align;
  @override
  Widget build(BuildContext context) => Text(
    label,
    textAlign: align,
    style: const TextStyle(
      color: Color(0xFFE6EDF7),
      fontWeight: FontWeight.w800,
      fontSize: 13,
    ),
  );
}

class ExpandedPriceTableRow extends StatelessWidget {
  const ExpandedPriceTableRow({
    super.key,
    required this.item,
    required this.shaded,
  });
  final MarketDisplayPriceItem item;
  final bool shaded;

  @override
  Widget build(BuildContext context) {
    final variance = item.currentPrice - item.srp;
    final color = item.isAboveSrp
        ? (AppColors.isDark(context)
              ? AppColors.warning
              : AppColors.warningText)
        : item.isBelowSrp
        ? const Color(0xFF0F9F7A)
        : const Color(0xFF64748B);
    final status = item.isAboveSrp
        ? 'Above SRP'
        : item.isBelowSrp
        ? 'Below SRP'
        : 'At SRP';
    final recorded = DateFormat(
      'MMM d, h:mm a',
    ).format(DateTime.parse(item.recordedAt).toLocal());
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: AppColors.isDark(context)
          ? (shaded ? AppColors.darkSurfaceMuted : AppColors.darkSurface)
          : (shaded ? const Color(0xFFF8FAFC) : Colors.white),
      child: Row(
        children: [
          Expanded(
            flex: 30,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.isDark(context)
                        ? AppColors.darkBackgroundAlt
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: CommodityVisual(
                    label: item.commodityName,
                    category: item.categoryName,
                    size: 28,
                    useIllustration: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.commodityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 16,
            child: Text(
              item.categoryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(flex: 11, child: Text(item.unit)),
          Expanded(
            flex: 16,
            child: Text(
              _priceBoardCurrency(item.currentPrice),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              _priceBoardCurrency(item.srp),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 16,
            child: Text(
              '${variance >= 0 ? '+' : '-'}${_priceBoardCurrency(variance.abs())}',
              textAlign: TextAlign.right,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            flex: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 17,
            child: Text(
              recorded,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobilePriceBoardList extends StatelessWidget {
  const _MobilePriceBoardList({required this.items, required this.compact});

  final List<MarketDisplayPriceItem> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final spacing = compact ? AppSpacing.xs : AppSpacing.sm;
    return ListView.separated(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) =>
          SizedBox(height: 250, child: _PublicPriceCard(item: items[index])),
    );
  }
}

class _PriceBoardSummary extends StatelessWidget {
  const _PriceBoardSummary({
    required this.data,
    required this.pageIndex,
    required this.pageCount,
    required this.visibleCount,
    required this.compact,
    required this.wideLayout,
  });

  final MarketDisplayData data;
  final int pageIndex;
  final int pageCount;
  final int visibleCount;
  final bool compact;
  final bool wideLayout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final chips = [
      _BoardMetricChip(label: 'Items', value: '${data.itemCount}'),
      _BoardMetricChip(
        label: 'Showing',
        value: '$visibleCount / ${data.itemCount}',
        color: AppColors.textPrimaryFor(context),
      ),
      _BoardMetricChip(
        label: 'Page',
        value: '${pageIndex + 1}/$pageCount',
        color: AppColors.sky,
      ),
      _BoardMetricChip(
        label: 'Below SRP',
        value: '${data.belowSrpCount}',
        color: AppColors.primaryDark,
      ),
      _BoardMetricChip(
        label: 'Above SRP',
        value: '${data.aboveSrpCount}',
        color: AppColors.warning,
      ),
    ];

    return wideLayout
        ? Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Official commodity price register',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimaryFor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current market prices compared with published suggested retail prices.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: chips,
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Official commodity price register',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Current market prices compared with suggested retail prices.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: chips,
              ),
            ],
          );
  }
}

class _BoardMetricChip extends StatelessWidget {
  const _BoardMetricChip({
    required this.label,
    required this.value,
    this.color = AppColors.primary,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final labelColor = AppColors.isDark(context)
        ? color.withValues(alpha: 0.95)
        : color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark(context) ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(
            alpha: AppColors.isDark(context) ? 0.24 : 0.12,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBoardRow extends StatelessWidget {
  const _PriceBoardRow({required this.item, required this.compact});

  final MarketDisplayPriceItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useDark = AppColors.isDark(context);
    final accent = item.isAboveSrp ? AppColors.warning : AppColors.primaryDark;
    final effectiveAccent = useDark
        ? (item.isAboveSrp ? AppColors.warning : AppColors.darkPrimarySoft)
        : accent;
    final statusLabel = item.isAboveSrp
        ? 'Above SRP'
        : item.isBelowSrp
        ? 'Below SRP'
        : 'At SRP';
    final recordedLabel = DateFormat(
      'h:mm a',
    ).format(DateTime.parse(item.recordedAt).toLocal());

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.surfaceGradientFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderFor(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowFor(context).withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommodityVisual(
            label: item.commodityName,
            category: item.categoryName,
            size: compact ? 60 : 68,
            useIllustration: false,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.commodityName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.categoryName} | ${item.unit}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: effectiveAccent.withValues(
                      alpha: useDark ? 0.18 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: effectiveAccent,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        recordedLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: effectiveAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _priceBoardCurrency(item.currentPrice),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: compact ? 20 : 22,
                  color: AppColors.textPrimaryFor(context),
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'SRP ${_priceBoardCurrency(item.srp)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: effectiveAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: effectiveAccent.withValues(
                    alpha: useDark ? 0.18 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: effectiveAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MarketDisplayFooterStrip extends StatelessWidget {
  const MarketDisplayFooterStrip({
    super.key,
    required this.data,
    required this.compact,
  });

  final MarketDisplayData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastUpdated = DateFormat(
      compact ? 'MMM d | h:mm a' : 'MMM d, y | h:mm a',
    ).format(DateTime.parse(data.lastUpdatedAt).toLocal());

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.md : AppSpacing.lg,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(
          context,
        ).withValues(alpha: AppColors.isDark(context) ? 0.94 : 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FooterMessage(theme: theme),
                const SizedBox(height: 4),
                Text(
                  'Last sync: $lastUpdated',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: _FooterMessage(theme: theme)),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Last sync: $lastUpdated',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}

class _HeaderBrand extends StatelessWidget {
  const _HeaderBrand({required this.data, required this.compact});

  final MarketDisplayData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supportingLine =
        '${data.marketName ?? data.storeName}  •  ${data.city ?? data.address}  •  Verified market updates';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppSealBadge(size: compact ? 52 : 56, showFrame: false),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MUNICIPALITY OF LINGAYEN  •  PUBLIC INFORMATION',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFFFF8BA7),
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Public Market Commodity Price Board',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontSize: compact ? 18 : 22,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                compact
                    ? 'Verified local market price information'
                    : supportingLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (compact) ...[
                const SizedBox(height: 2),
                Text(
                  '${data.marketName ?? data.storeName} | ${data.city ?? data.address}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderMeta extends StatelessWidget {
  const _HeaderMeta({
    required this.currentTimeLabel,
    required this.lastUpdatedLabel,
    required this.onLogin,
    required this.onRefresh,
    required this.compact,
  });

  final String currentTimeLabel;
  final String lastUpdatedLabel;
  final VoidCallback onLogin;
  final VoidCallback onRefresh;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionsInline = !compact;

    if (actionsInline) {
      return SizedBox(
        width: 500,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: Colors.white.withValues(alpha: 0.82),
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Updated $lastUpdatedLabel | $currentTimeLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              width: 104,
              child: OutlinedButton.icon(
                onPressed: onRefresh,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(38),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.26)),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Refresh'),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              width: 92,
              child: FilledButton.icon(
                onPressed: onLogin,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDark,
                  minimumSize: const Size.fromHeight(38),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                icon: const Icon(Icons.login_rounded, size: 15),
                label: const Text('Login'),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: Colors.white.withValues(alpha: 0.82),
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Updated $lastUpdatedLabel',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentTimeLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRefresh,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    minimumSize: const Size.fromHeight(46),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onLogin,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.26),
                    ),
                  ),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Login'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterMessage extends StatelessWidget {
  const _FooterMessage({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Prices may change during the day. Please confirm with the vendor before buying.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

int _resolveBoardColumnCount({required int itemCount}) {
  if (itemCount <= 1) {
    return 1;
  }

  if (itemCount <= 3) {
    return itemCount;
  }

  return math.min(3, itemCount);
}

List<List<MarketDisplayPriceItem>> _splitItemsIntoColumns(
  List<MarketDisplayPriceItem> items,
  int columnCount,
) {
  final chunkSize = (items.length / columnCount).ceil();
  final columns = <List<MarketDisplayPriceItem>>[];

  for (var columnIndex = 0; columnIndex < columnCount; columnIndex++) {
    final start = columnIndex * chunkSize;
    if (start >= items.length) {
      break;
    }

    final end = math.min(start + chunkSize, items.length);
    columns.add(items.sublist(start, end));
  }

  return columns;
}

String _priceBoardCurrency(double value) => '\u20B1${value.toStringAsFixed(2)}';

List<MarketDisplayPriceItem> _itemsForPage(
  List<MarketDisplayPriceItem> items, {
  required int pageIndex,
  required int itemsPerPage,
}) {
  if (items.isEmpty) {
    return const [];
  }

  final start = (pageIndex * itemsPerPage) % items.length;
  final end = math.min(start + itemsPerPage, items.length);
  return items.sublist(start, end);
}

int _resolvePageCount(int itemCount, int itemsPerPage) {
  final pageCount = (itemCount / itemsPerPage).ceil();
  return pageCount <= 0 ? 1 : pageCount;
}
