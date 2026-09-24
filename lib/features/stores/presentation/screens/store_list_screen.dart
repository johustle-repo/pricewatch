import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/ui_models.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_notification_button.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/app_shell_menu_button.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/responsive_page.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../controllers/store_controller.dart';

class StoreListScreen extends StatefulWidget {
  const StoreListScreen({super.key});

  @override
  State<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreController>().loadStores();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StoreController>();
    final useWebShell = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      appBar: useWebShell
          ? null
          : AppBar(
              leading: const AppShellMenuButton(),
              title: const Text('Markets & Stores'),
              actions: const [AppNotificationButton(), SizedBox(width: 8)],
            ),
      body: AppBackground(
        child: ResponsivePage(
          maxWidth: 1180,
          expandHeight: true,
          horizontalPadding: 0,
          topPadding: 0,
          bottomPadding: 0,
          edgeToEdgeDesktopOnly: true,
          child: RefreshIndicator(
            onRefresh: () => context.read<StoreController>().loadStores(
              query: _searchController.text,
            ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                Container(
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
                        'Nearby markets',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Browse trusted stores, monitor local report activity, and jump into fresh price lists quickly.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppSearchField(
                        controller: _searchController,
                        hintText: 'Search stores, markets, or city',
                        onChanged: (value) => context
                            .read<StoreController>()
                            .loadStores(query: value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 540;
                    final title = Text(
                      'Local store directory',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    );
                    final count = Text(
                      '${controller.stores.length} results',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [title, const SizedBox(height: 6), count],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: title),
                        const SizedBox(width: 12),
                        count,
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                if (controller.isLoading)
                  const SizedBox(
                    height: 420,
                    child: ListLoadingView(cardCount: 5),
                  )
                else if (controller.stores.isEmpty)
                  const EmptyStateView(
                    title: 'No stores found',
                    message: 'Try another keyword or refresh the list.',
                    icon: Icons.storefront_outlined,
                  )
                else if (MediaQuery.sizeOf(context).width >= 1024)
                  _StoreDesktopTable(stores: controller.stores)
                else
                  ...controller.stores.map(
                    (store) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: AppSurfaceCard(
                        onTap: () => context.push('/store/${store.id}'),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 520;
                            final leading = Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.backgroundAltFor(context),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: AppColors.primaryDark,
                                size: 28,
                              ),
                            );
                            final summary = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  store.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  store.marketName ?? 'Local market',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${store.address}${store.city == null ? '' : ' | ${store.city}'}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            );
                            final badges = Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                AppStatusBadge(
                                  label:
                                      '${store.rating.toStringAsFixed(1)} rating',
                                  color: AppColors.primaryDark,
                                  icon: Icons.star_rounded,
                                ),
                                AppStatusBadge(
                                  label: '${store.reportCount} reports',
                                  color: AppColors.warning,
                                  icon: Icons.flag_rounded,
                                ),
                                AppStatusBadge(
                                  label:
                                      '${store.latestPriceCount} price updates',
                                  color: AppColors.sky,
                                  icon: Icons.price_change_rounded,
                                ),
                              ],
                            );
                            final chevron = Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textSecondaryFor(context),
                              ),
                            );

                            if (compact) {
                              return ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 154,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        leading,
                                        const SizedBox(width: 16),
                                        Expanded(child: summary),
                                        const SizedBox(width: 8),
                                        chevron,
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    badges,
                                  ],
                                ),
                              );
                            }

                            return ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 124),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  leading,
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        summary,
                                        const SizedBox(height: 12),
                                        badges,
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  chevron,
                                ],
                              ),
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
      ),
    );
  }
}

class _StoreDesktopTable extends StatefulWidget {
  const _StoreDesktopTable({required this.stores});
  final List<StoreSummary> stores;

  @override
  State<_StoreDesktopTable> createState() => _StoreDesktopTableState();
}

class _StoreDesktopTableState extends State<_StoreDesktopTable> {
  bool _ascending = true;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final stores = [...widget.stores]
      ..sort((a, b) => (_ascending ? 1 : -1) * a.name.compareTo(b.name));
    final pageCount = stores.isEmpty ? 1 : (stores.length / 10).ceil();
    if (_page >= pageCount) _page = pageCount - 1;
    final pageStores = stores.skip(_page * 10).take(10).toList();
    return Column(
      children: [
        Row(
          children: [
            Text(
              '${stores.length} verified stores',
              style: TextStyle(
                color: AppColors.textSecondaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() {
                _ascending = !_ascending;
                _page = 0;
              }),
              icon: Icon(
                _ascending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 17,
              ),
              label: const Text('Sort by name'),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
              columns: const [
                DataColumn(label: Text('Verified store')),
                DataColumn(label: Text('Market')),
                DataColumn(label: Text('Location')),
                DataColumn(label: Text('Prices'), numeric: true),
                DataColumn(label: Text('Reports'), numeric: true),
                DataColumn(label: Text('Rating'), numeric: true),
                DataColumn(label: Text('')),
              ],
              rows: [
                for (final store in pageStores)
                  DataRow(
                    onSelectChanged: (_) => context.push('/store/${store.id}'),
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF0F9F76),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              store.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(store.marketName ?? 'Local market')),
                      DataCell(
                        SizedBox(
                          width: 250,
                          child: Text(
                            '${store.address}${store.city == null ? '' : ', ${store.city}'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text('${store.latestPriceCount}')),
                      DataCell(Text('${store.reportCount}')),
                      DataCell(Text(store.rating.toStringAsFixed(1))),
                      const DataCell(Icon(Icons.chevron_right_rounded)),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _StoreTablePager(
          page: _page,
          pageCount: pageCount,
          onPrevious: _page == 0 ? null : () => setState(() => _page--),
          onNext: _page + 1 >= pageCount ? null : () => setState(() => _page++),
        ),
      ],
    );
  }
}

class _StoreTablePager extends StatelessWidget {
  const _StoreTablePager({
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
