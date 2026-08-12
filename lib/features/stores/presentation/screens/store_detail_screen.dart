import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/adaptive_stat_grid.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_notification_button.dart';
import '../../../../shared/widgets/app_shell_menu_button.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/commodity_visual.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/price_trend_badge.dart';
import '../../../../shared/widgets/responsive_page.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../controllers/store_controller.dart';

class StoreDetailScreen extends StatefulWidget {
  const StoreDetailScreen({super.key, required this.storeId});

  final int storeId;

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreController>().loadDetail(widget.storeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final useWebShell = MediaQuery.sizeOf(context).width >= 1024;
    final controller = context.watch<StoreController>();
    final detail = controller.detail;

    return Scaffold(
      appBar: useWebShell
          ? null
          : AppBar(
              leading: const AppShellMenuButton(),
              title: const Text('Store Details'),
              actions: const [AppNotificationButton(), SizedBox(width: 8)],
            ),
      body: AppBackground(
        child: controller.isLoading && detail == null
            ? const ListLoadingView(cardCount: 5)
            : detail == null
            ? const EmptyStateView(
                title: 'Store unavailable',
                message: 'We could not load this market right now.',
                icon: Icons.store_mall_directory_outlined,
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 360;
                          final icon = Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          );
                          final info = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detail.store.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                detail.store.marketName ?? 'Local market',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.86,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                detail.store.address,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.86,
                                      ),
                                    ),
                              ),
                              if (detail.store.city != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  detail.store.city!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.76,
                                        ),
                                      ),
                                ),
                              ],
                            ],
                          );

                          if (compact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                icon,
                                const SizedBox(height: 16),
                                info,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              icon,
                              const SizedBox(width: 16),
                              Expanded(child: info),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AdaptiveStatGrid(
                      children: [
                        StatCard(
                          title: 'Rating',
                          value: '${detail.rating.toStringAsFixed(1)} / 5',
                          icon: Icons.star_outline_rounded,
                          highlight: true,
                        ),
                        StatCard(
                          title: 'Reports',
                          value: '${detail.reportCount}',
                          icon: Icons.flag_outlined,
                        ),
                        StatCard(
                          title: 'Pending',
                          value: '${detail.pendingReports}',
                          icon: Icons.pending_actions_outlined,
                        ),
                        StatCard(
                          title: 'Resolved',
                          value: '${detail.resolvedReports}',
                          icon: Icons.verified_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Current price list',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        AppStatusBadge(
                          label: '${detail.prices.length} items',
                          color: AppColors.primaryDark,
                          icon: Icons.inventory_2_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (detail.prices.isEmpty)
                      const EmptyStateView(
                        title: 'No price list available',
                        message: 'Add price entries from the admin dashboard.',
                        icon: Icons.price_change_outlined,
                      )
                    else
                      ...detail.prices.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: AppSurfaceCard(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 380;
                                final summary = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.commodityName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${item.unit} | SRP ${AppFormatters.currency(item.srp)}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 8),
                                    PriceTrendBadge(
                                      delta: item.latestPrice - item.srp,
                                      label: item.latestPrice >= item.srp
                                          ? 'Above SRP'
                                          : 'Below SRP',
                                    ),
                                  ],
                                );
                                final trailing = Column(
                                  crossAxisAlignment: compact
                                      ? CrossAxisAlignment.start
                                      : CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppFormatters.currency(item.latestPrice),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      AppFormatters.dateTime(item.recordedAt),
                                      maxLines: compact ? 2 : 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: compact
                                          ? TextAlign.left
                                          : TextAlign.right,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                );

                                if (compact) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CommodityVisual(
                                        label: item.commodityName,
                                        size: 68,
                                      ),
                                      const SizedBox(height: 16),
                                      summary,
                                      const SizedBox(height: 12),
                                      trailing,
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CommodityVisual(
                                      label: item.commodityName,
                                      size: 68,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(child: summary),
                                    const SizedBox(width: 12),
                                    Flexible(child: trailing),
                                  ],
                                );
                              },
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
