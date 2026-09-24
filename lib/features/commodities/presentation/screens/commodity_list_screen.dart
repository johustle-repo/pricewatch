import 'package:flutter/material.dart';
import '../../../../shared/widgets/pricewatch_help.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/models/ui_models.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_seal_badge.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/app_shell_menu_button.dart';
import '../../../../shared/widgets/commodity_visual.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/price_trend_badge.dart';
import '../../../../shared/widgets/responsive_page.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/commodity_controller.dart';

class CommodityListScreen extends StatefulWidget {
  const CommodityListScreen({
    super.key,
    this.initialCategoryId,
    this.initialSearch = '',
  });

  final int? initialCategoryId;
  final String initialSearch;

  @override
  State<CommodityListScreen> createState() => _CommodityListScreenState();
}

class _CommodityListScreenState extends State<CommodityListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthController>();
      final controller = context.read<CommodityController>();
      await controller.loadCategories();
      controller.setCategory(widget.initialCategoryId);
      controller.setQuery(widget.initialSearch);
      final userId = auth.currentUser?.id;
      if (userId != null) {
        await controller.loadCommodities(userId: userId);
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
    final controller = context.watch<CommodityController>();
    final userId = auth.currentUser?.id;
    final useDark = AppColors.isDark(context);
    final theme = Theme.of(context);
    final useMobileHeader = MediaQuery.sizeOf(context).width < 720;
    final useWebShell = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      appBar: useWebShell
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              leading: useMobileHeader ? null : const AppShellMenuButton(),
              titleSpacing: useMobileHeader ? AppSpacing.xl : null,
              title: useMobileHeader
                  ? const Row(
                      children: [
                        AppSealBadge(size: 32, padding: 2.5, showFrame: false),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'PriceWatch',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : const Text('Commodities'),
              actions: useMobileHeader
                  ? [
                      IconButton(
                        tooltip: 'Markets and stores',
                        onPressed: () => context.push('/stores'),
                        icon: const Icon(Icons.storefront_outlined),
                      ),
                      IconButton(
                        tooltip: 'Notifications',
                        onPressed: () => context.push('/notifications'),
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                      const SizedBox(width: 8),
                    ]
                  : null,
            ),
      body: AppBackground(
        showTopGlow: false,
        child: ResponsivePage(
          maxWidth: 1160,
          expandHeight: true,
          horizontalPadding: 0,
          topPadding: AppSpacing.sm,
          bottomPadding: 0,
          edgeToEdgeDesktopOnly: true,
          child: RefreshIndicator(
            onRefresh: () async {
              if (userId != null) {
                await controller.loadCommodities(userId: userId);
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                const PriceWatchHelp(),

                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceFor(context),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderFor(context)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowFor(
                          context,
                        ).withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily essentials',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimaryFor(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Search products, review price movement, and jump into details quickly.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondaryFor(context),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppSearchField(
                        controller: _searchController,
                        hintText: 'Search rice, eggs, fish, or vegetables...',
                        onChanged: (value) async {
                          controller.setQuery(value);
                          if (userId != null) {
                            await controller.loadCommodities(userId: userId);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: controller.selectedCategoryId == null,
                            selectedColor: useDark
                                ? AppColors.darkPrimary
                                : AppColors.primaryDark,
                            backgroundColor: AppColors.surfaceMutedFor(context),
                            labelStyle: theme.textTheme.labelMedium?.copyWith(
                              color: controller.selectedCategoryId == null
                                  ? Colors.white
                                  : AppColors.textPrimaryFor(context),
                              fontWeight: FontWeight.w800,
                            ),
                            side: BorderSide(
                              color: controller.selectedCategoryId == null
                                  ? Colors.transparent
                                  : AppColors.borderFor(context),
                            ),
                            onSelected: (_) async {
                              controller.setCategory(null);
                              if (userId != null) {
                                await controller.loadCommodities(
                                  userId: userId,
                                );
                              }
                            },
                          ),
                          ...controller.categories.map(
                            (category) => ChoiceChip(
                              label: Text(category.name),
                              selected:
                                  controller.selectedCategoryId == category.id,
                              selectedColor: useDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primaryDark,
                              backgroundColor: AppColors.surfaceMutedFor(
                                context,
                              ),
                              labelStyle: theme.textTheme.labelMedium?.copyWith(
                                color:
                                    controller.selectedCategoryId == category.id
                                    ? Colors.white
                                    : AppColors.textPrimaryFor(context),
                                fontWeight: FontWeight.w800,
                              ),
                              side: BorderSide(
                                color:
                                    controller.selectedCategoryId == category.id
                                    ? Colors.transparent
                                    : AppColors.borderFor(context),
                              ),
                              onSelected: (_) async {
                                controller.setCategory(category.id);
                                if (userId != null) {
                                  await controller.loadCommodities(
                                    userId: userId,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (controller.isLoading)
                  const ListLoadingView(cardCount: 7, shrinkWrap: true)
                else if (controller.commodities.isEmpty)
                  const EmptyStateView(
                    title: 'No commodities found',
                    message:
                        'Try another category or search keyword to see local items.',
                  )
                else if (MediaQuery.sizeOf(context).width >= 1024)
                  _CommodityDesktopTable(items: controller.commodities)
                else
                  for (
                    var index = 0;
                    index < controller.commodities.length;
                    index++
                  ) ...[
                    _CommodityListCard(item: controller.commodities[index]),
                    if (index < controller.commodities.length - 1)
                      const SizedBox(height: 14),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommodityDesktopTable extends StatefulWidget {
  const _CommodityDesktopTable({required this.items});
  final List<CommodityOverview> items;

  @override
  State<_CommodityDesktopTable> createState() => _CommodityDesktopTableState();
}

class _CommodityDesktopTableState extends State<_CommodityDesktopTable> {
  String _status = 'all';
  bool _ascending = true;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final items =
        widget.items
            .where(
              (item) => switch (_status) {
                'above' => item.varianceFromSrp > 0,
                'below' => item.varianceFromSrp < 0,
                'at' => item.varianceFromSrp == 0,
                'watched' => item.isWatched,
                _ => true,
              },
            )
            .toList()
          ..sort((a, b) => (_ascending ? 1 : -1) * a.name.compareTo(b.name));
    final pageCount = items.isEmpty ? 1 : (items.length / 10).ceil();
    if (_page >= pageCount) _page = pageCount - 1;
    final pageItems = items.skip(_page * 10).take(10).toList();
    return Column(
      children: [
        Row(
          children: [
            Text(
              '${items.length} matching products',
              style: TextStyle(
                color: AppColors.textSecondaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Price status',
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All prices')),
                  DropdownMenuItem(value: 'above', child: Text('Above SRP')),
                  DropdownMenuItem(value: 'at', child: Text('At SRP')),
                  DropdownMenuItem(value: 'below', child: Text('Below SRP')),
                  DropdownMenuItem(value: 'watched', child: Text('Watched')),
                ],
                onChanged: (value) => setState(() {
                  _status = value ?? 'all';
                  _page = 0;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderFor(context)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(
                AppColors.surfaceMutedFor(context),
              ),
              sortColumnIndex: 0,
              sortAscending: _ascending,
              columns: [
                DataColumn(
                  label: const Text('Commodity'),
                  onSort: (_, ascending) => setState(() {
                    _ascending = ascending;
                    _page = 0;
                  }),
                ),
                const DataColumn(label: Text('Category')),
                const DataColumn(label: Text('Unit')),
                const DataColumn(label: Text('Current'), numeric: true),
                const DataColumn(label: Text('SRP'), numeric: true),
                const DataColumn(label: Text('Variance')),
                const DataColumn(label: Text('Updated')),
                const DataColumn(label: Text('')),
              ],
              rows: [
                for (final item in pageItems)
                  DataRow(
                    onSelectChanged: (_) =>
                        context.push('/commodity/${item.id}'),
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            CommodityVisual(
                              label: item.name,
                              category: item.categoryName,
                              size: 38,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (item.isWatched) ...[
                              const SizedBox(width: 7),
                              const Icon(
                                Icons.bookmark_rounded,
                                size: 15,
                                color: AppColors.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                      DataCell(Text(item.categoryName)),
                      DataCell(Text(item.unit)),
                      DataCell(
                        Text(AppFormatters.currency(item.latestAveragePrice)),
                      ),
                      DataCell(Text(AppFormatters.currency(item.srp))),
                      DataCell(
                        PriceTrendBadge(
                          delta: item.varianceFromSrp,
                          label: item.varianceFromSrp > 0
                              ? 'Above SRP'
                              : item.varianceFromSrp < 0
                              ? 'Below SRP'
                              : 'At SRP',
                        ),
                      ),
                      DataCell(Text(AppFormatters.date(item.latestUpdatedAt))),
                      const DataCell(Icon(Icons.chevron_right_rounded)),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _TablePager(
          page: _page,
          pageCount: pageCount,
          onPrevious: _page == 0 ? null : () => setState(() => _page--),
          onNext: _page + 1 >= pageCount ? null : () => setState(() => _page++),
        ),
      ],
    );
  }
}

class _TablePager extends StatelessWidget {
  const _TablePager({
    required this.page,
    required this.pageCount,
    this.onPrevious,
    this.onNext,
  });
  final int page;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Text('Page ${page + 1} of $pageCount'),
      const SizedBox(width: 8),
      IconButton(
        tooltip: 'Previous page',
        onPressed: onPrevious,
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      IconButton(
        tooltip: 'Next page',
        onPressed: onNext,
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ],
  );
}

class _CommodityListCard extends StatelessWidget {
  const _CommodityListCard({required this.item});

  final CommodityOverview item;

  @override
  Widget build(BuildContext context) {
    final percentage = (item.varianceFromSrp / item.srp) * 100;
    final useDark = AppColors.isDark(context);
    final theme = Theme.of(context);
    final trendColor = percentage >= 0
        ? AppColors.warning
        : (useDark ? AppColors.darkPrimarySoft : AppColors.primaryDark);
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimaryFor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (item.isWatched)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      (useDark ? AppColors.darkPrimarySoft : AppColors.primary)
                          .withValues(alpha: useDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  Icons.bookmark_rounded,
                  size: 14,
                  color: useDark
                      ? AppColors.darkPrimarySoft
                      : AppColors.primaryDark,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${item.categoryName} | ${item.unit}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        const SizedBox(height: 10),
        PriceTrendBadge(
          delta: item.varianceFromSrp,
          label: percentage >= 0
              ? '${percentage.toStringAsFixed(1)}% above SRP'
              : '${percentage.abs().toStringAsFixed(1)}% below SRP',
        ),
      ],
    );

    final priceMeta = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          AppFormatters.currency(item.latestAveragePrice),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimaryFor(context),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              percentage >= 0
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              size: 16,
              color: trendColor,
            ),
            const SizedBox(width: 4),
            Text(
              '${percentage.abs().toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: trendColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'SRP ${AppFormatters.currency(item.srp)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/commodity/${item.id}'),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.borderFor(
                context,
              ).withValues(alpha: useDark ? 0.72 : 1),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowFor(context).withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 640;

              if (compact) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 154),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommodityVisual(
                            label: item.name,
                            category: item.categoryName,
                            size: 72,
                            heroTag: 'commodity-visual-${item.id}',
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: summary),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(alignment: Alignment.centerLeft, child: priceMeta),
                    ],
                  ),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 132),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommodityVisual(
                      label: item.name,
                      category: item.categoryName,
                      size: 72,
                      heroTag: 'commodity-visual-${item.id}',
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: summary),
                    const SizedBox(width: 16),
                    Flexible(child: priceMeta),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
