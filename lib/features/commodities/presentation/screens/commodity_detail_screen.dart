import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../shared/widgets/price_increase_history.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_notification_button.dart';
import '../../../../shared/widgets/app_shell_menu_button.dart';
import '../../../../shared/widgets/commodity_visual.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/price_trend_badge.dart';
import '../../../../shared/widgets/responsive_page.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/commodity_controller.dart';

class CommodityDetailScreen extends StatefulWidget {
  const CommodityDetailScreen({super.key, required this.commodityId});

  final int commodityId;

  @override
  State<CommodityDetailScreen> createState() => _CommodityDetailScreenState();
}

class _CommodityDetailScreenState extends State<CommodityDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthController>().currentUser?.id;
      if (userId != null) {
        context.read<CommodityController>().loadDetail(
          commodityId: widget.commodityId,
          userId: userId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final useWebShell = MediaQuery.sizeOf(context).width >= 1024;
    final controller = context.watch<CommodityController>();
    final auth = context.watch<AuthController>();
    final detail = controller.detail;
    final userId = auth.currentUser?.id;

    return Scaffold(
      appBar: useWebShell
          ? null
          : AppBar(
              leading: const AppShellMenuButton(),
              title: const Text('Commodity Details'),
              actions: [
                const AppNotificationButton(),
                IconButton(
                  onPressed: () => context.push(
                    '/report/new?commodityId=${widget.commodityId}',
                  ),
                  icon: const Icon(Icons.flag_outlined),
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: detail == null || userId == null
          ? null
          : _WatchCtaButton(
              isWatched: detail.isWatched,
              onTap: () => _showWatchDialog(userId, detail.isWatched),
            ),
      body: AppBackground(
        child: controller.isLoading && detail == null
            ? const ListLoadingView(cardCount: 4)
            : detail == null
            ? const EmptyStateView(
                title: 'Commodity not found',
                message: 'We could not load this local item.',
              )
            : ResponsivePage(
                maxWidth: 1120,
                expandHeight: true,
                horizontalPadding: 0,
                topPadding: 0,
                bottomPadding: 0,
                edgeToEdgeDesktopOnly: true,
                child: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
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
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxWidth < 360;
                              final info = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    detail.commodity.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${detail.category.name} | ${detail.commodity.unit}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.86,
                                          ),
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  PriceTrendBadge(
                                    delta:
                                        detail.averagePrice -
                                        detail.commodity.srp,
                                  ),
                                ],
                              );

                              if (compact) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CommodityVisual(
                                      label: detail.commodity.name,
                                      category: detail.category.name,
                                      size: 96,
                                      heroTag:
                                          'commodity-visual-${detail.commodity.id ?? widget.commodityId}',
                                    ),
                                    const SizedBox(height: 18),
                                    info,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CommodityVisual(
                                    label: detail.commodity.name,
                                    category: detail.category.name,
                                    size: 96,
                                    heroTag:
                                        'commodity-visual-${detail.commodity.id ?? widget.commodityId}',
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(child: info),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            detail.commodity.description ??
                                'No description available for this commodity.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: _HeroDataPill(
                                  label: 'Average',
                                  value: AppFormatters.currency(
                                    detail.averagePrice,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _HeroDataPill(
                                  label: 'Stores',
                                  value: '${detail.latestStorePrices.length}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 360;
                        final cards = [
                          _PriceMetricCard(
                            label: 'SRP',
                            value: AppFormatters.currency(detail.commodity.srp),
                            accent: AppColors.primary,
                          ),
                          _PriceMetricCard(
                            label: 'Lowest',
                            value: AppFormatters.currency(detail.lowestPrice),
                            accent: AppColors.primarySoft,
                          ),
                          _PriceMetricCard(
                            label: 'Highest',
                            value: AppFormatters.currency(detail.highestPrice),
                            accent: AppColors.warning,
                          ),
                        ];

                        if (compact) {
                          return Column(
                            children: [
                              for (var i = 0; i < cards.length; i++) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: cards[i],
                                ),
                                if (i != cards.length - 1)
                                  const SizedBox(height: 12),
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
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PriceIncreaseHistory(
                      entries: detail.priceEntries,
                      stores: detail.latestStorePrices,
                      unit: detail.commodity.unit,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Price history',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: SizedBox(
                        height: 250,
                        child: LineChart(
                          LineChartData(
                            minY:
                                (detail.history.isEmpty
                                    ? detail.commodity.srp
                                    : detail.history
                                          .map((e) => e.value)
                                          .reduce((a, b) => a < b ? a : b)) -
                                10,
                            maxY:
                                (detail.history.isEmpty
                                    ? detail.commodity.srp
                                    : detail.history
                                          .map((e) => e.value)
                                          .reduce((a, b) => a > b ? a : b)) +
                                10,
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: 10,
                              getDrawingHorizontalLine: (value) => const FlLine(
                                color: AppColors.border,
                                strokeWidth: 1,
                              ),
                              drawVerticalLine: false,
                            ),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toStringAsFixed(0),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 ||
                                        index >= detail.history.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final date = detail.history[index].date;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '${date.month}/${date.day}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                isCurved: true,
                                color: AppColors.primary,
                                barWidth: 4,
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.25),
                                      AppColors.primary.withValues(alpha: 0.02),
                                    ],
                                  ),
                                ),
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, bar, index) =>
                                      FlDotCirclePainter(
                                        radius: 4.5,
                                        color: Colors.white,
                                        strokeColor: AppColors.primaryDark,
                                        strokeWidth: 2.5,
                                      ),
                                ),
                                spots: List.generate(
                                  detail.history.length,
                                  (index) => FlSpot(
                                    index.toDouble(),
                                    detail.history[index].value,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Store prices',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (detail.latestStorePrices.isEmpty)
                      const EmptyStateView(
                        title: 'No store prices yet',
                        message: 'Add a price entry from the admin dashboard.',
                      )
                    else
                      ...detail.latestStorePrices.asMap().entries.map((entry) {
                        final index = entry.key;
                        final store = entry.value;
                        final isBest = index == 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () =>
                                context.push('/store/${store.storeId}'),
                            borderRadius: BorderRadius.circular(28),
                            child: Ink(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: isBest
                                    ? const Color(0xFFFFF1F7)
                                    : Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: isBest
                                      ? AppColors.primarySoft.withValues(
                                          alpha: 0.4,
                                        )
                                      : AppColors.border,
                                ),
                                boxShadow: isBest
                                    ? const [
                                        BoxShadow(
                                          color: AppColors.glowSoft,
                                          blurRadius: 24,
                                          offset: Offset(0, 10),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: isBest
                                          ? AppColors.primary.withValues(
                                              alpha: 0.12,
                                            )
                                          : AppColors.backgroundAlt,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(
                                      Icons.storefront_rounded,
                                      color: isBest
                                          ? AppColors.primaryDark
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                store.storeName,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                            if (isBest)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                                child: Text(
                                                  'Best price',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: AppColors
                                                            .primaryDark,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          store.address,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          AppFormatters.dateTime(
                                            store.recordedAt,
                                          ),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        AppFormatters.currency(store.price),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      PriceTrendBadge(
                                        delta: store.differenceFromSrp,
                                        label: store.differenceFromSrp >= 0
                                            ? 'Above SRP'
                                            : 'Below SRP',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _showWatchDialog(int userId, bool isWatched) async {
    if (isWatched) {
      await context.read<CommodityController>().toggleWatchlist(
        userId: userId,
        commodityId: widget.commodityId,
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final thresholdController = TextEditingController();
    final threshold = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Watch commodity'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: thresholdController,
            decoration: const InputDecoration(
              labelText: 'Optional alert threshold',
              hintText: 'e.g. 60.00',
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
                thresholdController.text.trim().isEmpty
                    ? null
                    : double.parse(thresholdController.text.trim()),
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

    await context.read<CommodityController>().toggleWatchlist(
      userId: userId,
      commodityId: widget.commodityId,
      threshold: threshold,
    );
  }
}

class _WatchCtaButton extends StatelessWidget {
  const _WatchCtaButton({required this.isWatched, required this.onTap});

  final bool isWatched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width < 340
          ? MediaQuery.sizeOf(context).width - 40
          : 220,
      decoration: BoxDecoration(
        gradient: isWatched
            ? const LinearGradient(
                colors: [Color(0xFF1F2937), Color(0xFF374151)],
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.glowMedium,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isWatched
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_add_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  isWatched ? 'Watching item' : 'Add to watchlist',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroDataPill extends StatelessWidget {
  const _HeroDataPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceMetricCard extends StatelessWidget {
  const _PriceMetricCard({
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
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.circle, size: 14, color: accent),
          ),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
