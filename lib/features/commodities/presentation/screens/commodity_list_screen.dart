import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/models/category_model.dart';
import '../../../../shared/models/subcategory_model.dart';
import '../../../../shared/models/ui_models.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_notification_button.dart';
import '../../../../shared/widgets/category_style.dart';
import '../../../../shared/widgets/commodity_visual.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/price_freshness_chip.dart';
import '../../../../shared/widgets/pricewatch_help.dart';
import '../../../../shared/widgets/responsive_page.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../../../../shared/widgets/theme_mode_button.dart';
import '../../../admin/presentation/widgets/admin_page_frame.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/commodity_controller.dart';

/// Buyer price browser: pick a category, narrow to a sub-category, and read
/// current prices grouped the same way the market survey is organized.
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
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyRoute());
  }

  @override
  void didUpdateWidget(covariant CommodityListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Links from Home reuse this screen with a different category or search.
    if (oldWidget.initialCategoryId != widget.initialCategoryId ||
        oldWidget.initialSearch != widget.initialSearch) {
      _searchController.text = widget.initialSearch;
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyRoute());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _applyRoute() async {
    if (!mounted) return;
    final controller = context.read<CommodityController>();
    await controller.loadCategories();
    controller.setCategory(widget.initialCategoryId);
    controller.setQuery(widget.initialSearch);
    await _reload();
  }

  Future<void> _reload() async {
    final userId = context.read<AuthController>().currentUser?.id;
    if (userId != null) {
      await context.read<CommodityController>().loadCommodities(userId: userId);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<CommodityController>().setQuery(value);
      _reload();
    });
  }

  void _selectCategory(int? categoryId) {
    context.read<CommodityController>().setCategory(categoryId);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CommodityController>();
    final useWebShell =
        MediaQuery.sizeOf(context).width >= adminWebLayoutBreakpoint;
    final selectedCategory = controller.categories
        .where((item) => item.id == controller.selectedCategoryId)
        .firstOrNull;
    final sections = _buildSections(controller, selectedCategory);
    final itemCount = sections.fold<int>(0, (sum, s) => sum + s.items.length);
    final subcategoryCounts = <int, int>{};
    for (final item in controller.commodities) {
      final id = item.subcategoryId;
      if (id != null) subcategoryCounts[id] = (subcategoryCounts[id] ?? 0) + 1;
    }

    return Scaffold(
      appBar: useWebShell
          ? null
          : AppBar(
              titleSpacing: AppSpacing.md,
              title: const Text('Prices'),
              actions: [
                IconButton(
                  tooltip: 'Markets and stores',
                  onPressed: () => context.push('/stores'),
                  icon: const Icon(Icons.storefront_outlined),
                ),
                const PriceWatchGuideButton(),
                const ThemeModeButton(),
                const AppNotificationButton(),
                const SizedBox(width: 4),
              ],
            ),
      body: AppBackground(
        showTopGlow: false,
        child: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ResponsivePage(
                maxWidth: 1120,
                topPadding: AppSpacing.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SearchBar(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onClear: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      showStoresLink: useWebShell,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CategoryChips(
                      categories: controller.categories,
                      selectedId: controller.selectedCategoryId,
                      onSelected: _selectCategory,
                    ),
                    if (selectedCategory != null &&
                        controller.subcategories.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _SubcategoryChips(
                        category: selectedCategory,
                        subcategories: controller.subcategories,
                        counts: subcategoryCounts,
                        selectedId: controller.selectedSubcategoryId,
                        onSelected: controller.setSubcategory,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    if (controller.isLoading && controller.commodities.isEmpty)
                      const ListLoadingView(cardCount: 6, shrinkWrap: true)
                    else if (sections.isEmpty)
                      EmptyStateView(
                        title: 'No matching items',
                        message: controller.query.trim().isEmpty
                            ? 'No commodities are listed here yet.'
                            : 'Nothing matches “${controller.query.trim()}”. Try another name or category.',
                        icon: Icons.search_off_rounded,
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          '$itemCount ${itemCount == 1 ? 'item' : 'items'}'
                          '${selectedCategory == null ? '' : ' in ${selectedCategory.name}'}'
                          ' · prices are the latest average across stores',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondaryFor(context),
                              ),
                        ),
                      ),
                      for (final section in sections) ...[
                        _SectionBlock(section: section),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Groups by sub-category inside a chosen category, otherwise by category.
  List<_Section> _buildSections(
    CommodityController controller,
    CategoryModel? selectedCategory,
  ) {
    final items = controller.selectedSubcategoryId == null
        ? controller.commodities
        : controller.commodities
              .where(
                (item) =>
                    item.subcategoryId == controller.selectedSubcategoryId,
              )
              .toList();
    if (items.isEmpty) return const [];

    if (selectedCategory != null) {
      final sections = <_Section>[
        for (final sub in controller.subcategories)
          _Section(
            title: sub.name,
            iconKey: selectedCategory.icon,
            items: items.where((item) => item.subcategoryId == sub.id).toList(),
          ),
        _Section(
          title: controller.subcategories.isEmpty
              ? selectedCategory.name
              : 'Other ${selectedCategory.name.toLowerCase()}',
          iconKey: selectedCategory.icon,
          items: items.where((item) => item.subcategoryId == null).toList(),
        ),
      ];
      return sections.where((section) => section.items.isNotEmpty).toList();
    }

    return [
      for (final category in controller.categories)
        _Section(
          title: category.name,
          iconKey: category.icon,
          showSubcategory: true,
          items: items.where((item) => item.categoryId == category.id).toList(),
        ),
    ].where((section) => section.items.isNotEmpty).toList();
  }
}

class _Section {
  const _Section({
    required this.title,
    required this.iconKey,
    required this.items,
    this.showSubcategory = false,
  });

  final String title;
  final String? iconKey;
  final List<CommodityOverview> items;

  /// Rows name their sub-category when the section is a whole category.
  final bool showSubcategory;
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.showStoresLink,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showStoresLink;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search rice, bangus, eggs, tomato…',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
    if (!showStoresLink) return field;
    return Row(
      children: [
        Expanded(child: field),
        const SizedBox(width: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => context.push('/stores'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
          icon: const Icon(Icons.storefront_outlined),
          label: const Text('Markets & stores'),
        ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CategoryModel> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _Chip(
          label: 'All',
          icon: Icons.apps_rounded,
          selected: selectedId == null,
          color: AppColors.accentFor(context),
          onTap: () => onSelected(null),
        ),
        for (final category in categories) ...[
          const SizedBox(width: 8),
          _Chip(
            label: category.name,
            icon: CategoryStyle.icon(category.icon),
            selected: selectedId == category.id,
            color: CategoryStyle.color(context, category.icon),
            onTap: () => onSelected(category.id),
          ),
        ],
      ],
    ),
  );
}

class _SubcategoryChips extends StatelessWidget {
  const _SubcategoryChips({
    required this.category,
    required this.subcategories,
    required this.counts,
    required this.selectedId,
    required this.onSelected,
  });

  final CategoryModel category;
  final List<SubcategoryModel> subcategories;
  final Map<int, int> counts;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final color = CategoryStyle.color(context, category.icon);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'All ${category.name.toLowerCase()}',
            selected: selectedId == null,
            color: color,
            dense: true,
            onTap: () => onSelected(null),
          ),
          for (final sub in subcategories)
            if ((counts[sub.id] ?? 0) > 0) ...[
              const SizedBox(width: 8),
              _Chip(
                label: '${sub.name} · ${counts[sub.id]}',
                selected: selectedId == sub.id,
                color: color,
                dense: true,
                onTap: () => onSelected(sub.id),
              ),
            ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.icon,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? Colors.white
        : AppColors.textPrimaryFor(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? (AppColors.isDark(context)
                  ? color.withValues(alpha: 0.85)
                  : color)
            : AppColors.surfaceFor(context),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? Colors.transparent : AppColors.borderFor(context),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 14 : 16,
              vertical: dense ? 8 : 11,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: selected ? Colors.white : color),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style:
                      (dense
                              ? Theme.of(context).textTheme.labelMedium
                              : Theme.of(context).textTheme.labelLarge)
                          ?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w700,
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

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.section});

  final _Section section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priced = section.items.where((item) => item.hasRecordedPrice);
    // A range across different units (per kg vs 25 kg bag) would mislead.
    final sameUnit = priced.map((item) => item.unit).toSet().length == 1;
    final prices = sameUnit
        ? priced.map((item) => item.latestAveragePrice).toList()
        : <double>[];
    final count = section.items.length;
    final low = prices.isEmpty ? null : prices.reduce((a, b) => a < b ? a : b);
    final high = prices.isEmpty ? null : prices.reduce((a, b) => a > b ? a : b);
    final meta = [
      count == 1 ? '1 item' : '$count items',
      if (low != null && high != null && high - low > 0.005)
        '${AppFormatters.currency(low)} – ${AppFormatters.currency(high)}',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              CategoryIconBadge(iconKey: section.iconKey, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      meta,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryFor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 3
                : constraints.maxWidth >= 640
                ? 2
                : 1;
            const gap = AppSpacing.sm;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final item in section.items)
                  SizedBox(
                    width: width,
                    child: _PriceTile(
                      item: item,
                      showSubcategory: section.showSubcategory,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PriceTile extends StatelessWidget {
  const _PriceTile({required this.item, required this.showSubcategory});

  final CommodityOverview item;
  final bool showSubcategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if (showSubcategory && item.subcategoryName != null)
        item.subcategoryName!,
      'per ${item.unit}',
    ].join(' · ');
    return Material(
      color: AppColors.surfaceFor(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.borderFor(context)),
      ),
      child: InkWell(
        onTap: () => context.push('/commodity/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CommodityVisual(
                label: item.name,
                category: item.categoryName,
                size: 46,
                heroTag: 'commodity-visual-${item.id}',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (item.isWatched) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.bookmark_rounded,
                            size: 16,
                            color: AppColors.accentFor(context),
                            semanticLabel: 'On your watchlist',
                          ),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    PriceFreshnessChip(
                      recordedAt: item.latestUpdatedAt,
                      storeCount: item.storeCount,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.hasRecordedPrice
                        ? AppFormatters.currency(item.latestAveragePrice)
                        : '—',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _SrpStatus(item: item),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Above SRP +₱10" / "At SRP" / "Below SRP" / "SRP ₱90" for unpriced items.
class _SrpStatus extends StatelessWidget {
  const _SrpStatus({required this.item});

  final CommodityOverview item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delta = item.varianceFromSrp;
    final (label, color) = !item.hasRecordedPrice
        ? (
            'SRP ${AppFormatters.currency(item.srp)}',
            AppColors.textSecondaryFor(context),
          )
        : delta > 0.005
        ? (
            'Above SRP +${AppFormatters.currency(delta)}',
            AppColors.readableFor(context, AppColors.warningText),
          )
        : delta < -0.005
        ? ('Below SRP', AppColors.readableFor(context, AppColors.success))
        : ('At SRP', AppColors.textSecondaryFor(context));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
