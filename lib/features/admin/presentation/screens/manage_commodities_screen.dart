import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_icon_mapper.dart';
import '../../../../shared/models/category_model.dart';
import '../../../../shared/models/commodity_model.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_page_frame.dart';
import '../widgets/admin_workspace_widgets.dart';

class ManageCommoditiesScreen extends StatefulWidget {
  const ManageCommoditiesScreen({super.key});

  @override
  State<ManageCommoditiesScreen> createState() =>
      _ManageCommoditiesScreenState();
}

class _ManageCommoditiesScreenState extends State<ManageCommoditiesScreen> {
  final _searchController = TextEditingController();
  int? _categoryFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<AdminController>();
      await controller.loadCategories();
      await controller.loadCommodities();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();
    final webLayout = useAdminWebLayout(context);
    final categoryMap = {
      for (final category in controller.categories) category.id: category.name,
    };
    final query = _searchController.text.trim().toLowerCase();
    final visibleCommodities = controller.commodities.where((item) {
      return (query.isEmpty || item.name.toLowerCase().contains(query)) &&
          (_categoryFilter == null || item.categoryId == _categoryFilter);
    }).toList();

    return Scaffold(
      appBar: webLayout
          ? null
          : AppBar(title: const Text('Manage Commodities')),
      floatingActionButton: webLayout
          ? null
          : FloatingActionButton.extended(
              onPressed: controller.categories.isEmpty
                  ? null
                  : () => _openCommodityDialog(controller.categories),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            ),
      body: AppBackground(
        showTopGlow: false,
        child: controller.isLoading && controller.commodities.isEmpty
            ? const ListLoadingView(cardCount: 5)
            : controller.categories.isEmpty
            ? const AdminPageFrame(
                maxWidth: 1280,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  child: EmptyStateView(
                    title: 'No categories available',
                    message:
                        'Create at least one category before adding commodities.',
                    icon: Icons.category_outlined,
                  ),
                ),
              )
            : AdminPageFrame(
                maxWidth: 1280,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  children: [
                    AdminPageHeader(
                      title: 'Commodities',
                      subtitle:
                          'Manage the tracked items used in reports, watchlists, and price monitoring.',
                      icon: Icons.inventory_2_rounded,
                      webActionAtTop: true,
                      action: webLayout
                          ? SizedBox(
                              width: 220,
                              child: FilledButton.icon(
                                onPressed: controller.categories.isEmpty
                                    ? null
                                    : () => _openCommodityDialog(
                                        controller.categories,
                                      ),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add commodity'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                              ),
                            )
                          : null,
                    ),
                    if (controller.error != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      AdminErrorBanner(message: controller.error!),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final search = TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search_rounded),
                            hintText: 'Search commodities',
                          ),
                        );
                        final filter = DropdownButtonFormField<int?>(
                          initialValue: _categoryFilter,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.filter_alt_outlined),
                            labelText: 'Category',
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('All categories'),
                            ),
                            ...controller.categories.map(
                              (item) => DropdownMenuItem<int?>(
                                value: item.id,
                                child: Text(item.name),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _categoryFilter = value),
                        );
                        if (constraints.maxWidth < 700) {
                          return Column(
                            children: [
                              search,
                              const SizedBox(height: 12),
                              filter,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(flex: 3, child: search),
                            const SizedBox(width: 12),
                            Expanded(child: filter),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    visibleCommodities.isEmpty
                        ? const AppSurfaceCard(
                            radius: 28,
                            child: EmptyStateView(
                              title: 'No commodities yet',
                              message:
                                  'Use the add button to create the first tracked commodity.',
                              icon: Icons.inventory_2_outlined,
                            ),
                          )
                        : webLayout
                        ? _CommoditiesTable(
                            commodities: visibleCommodities,
                            categoryMap: categoryMap,
                            onEdit: (commodity) => _openCommodityDialog(
                              controller.categories,
                              commodity: commodity,
                            ),
                            onDelete: _confirmDelete,
                          )
                        : AppSurfaceCard(
                            radius: 28,
                            child: Column(
                              children: [
                                for (
                                  var i = 0;
                                  i < controller.commodities.length;
                                  i++
                                ) ...[
                                  _CommodityRow(
                                    item: controller.commodities[i],
                                    categoryName:
                                        categoryMap[controller
                                            .commodities[i]
                                            .categoryId] ??
                                        'Unknown',
                                    onEdit: () => _openCommodityDialog(
                                      controller.categories,
                                      commodity: controller.commodities[i],
                                    ),
                                  ),
                                  if (i != controller.commodities.length - 1)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: AppSpacing.md,
                                      ),
                                      child: Divider(height: 1),
                                    ),
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

  Future<void> _openCommodityDialog(
    List<CategoryModel> categories, {
    CommodityModel? commodity,
  }) async {
    if (categories.isEmpty) {
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: commodity?.name ?? '');
    final descriptionController = TextEditingController(
      text: commodity?.description ?? '',
    );
    final unitController = TextEditingController(text: commodity?.unit ?? '');
    final srpController = TextEditingController(
      text: commodity?.srp.toString() ?? '',
    );
    final fallbackCategoryId = categories.first.id;
    if (fallbackCategoryId == null) {
      return;
    }
    var selectedCategoryId = commodity?.categoryId ?? fallbackCategoryId;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(commodity == null ? 'Add commodity' : 'Edit commodity'),
        content: StatefulBuilder(
          builder: (context, setState) => Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map(
                          (item) => DropdownMenuItem<int>(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedCategoryId = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Name is required.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: unitController,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Unit is required.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: srpController,
                    decoration: const InputDecoration(labelText: 'SRP'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid SRP.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) {
                return;
              }
              await context.read<AdminController>().saveCommodity(
                id: commodity?.id,
                categoryId: selectedCategoryId,
                name: nameController.text,
                description: descriptionController.text,
                unit: unitController.text,
                srp: double.parse(srpController.text.trim()),
              );
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(CommodityModel commodity) async {
    if (commodity.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete commodity'),
        content: Text(
          'Delete ${commodity.name}? Commodities with prices, reports, or watchlists are protected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AdminController>().deleteCommodity(commodity.id!);
  }
}

class _CommoditiesTable extends StatelessWidget {
  const _CommoditiesTable({
    required this.commodities,
    required this.categoryMap,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CommodityModel> commodities;
  final Map<int?, String> categoryMap;
  final ValueChanged<CommodityModel> onEdit;
  final ValueChanged<CommodityModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return AdminDataTableCard(
      minWidth: 960,
      columns: const ['Commodity', 'Category', 'Unit', 'SRP', 'Actions'],
      rows: [
        for (final item in commodities)
          DataRow(
            cells: [
              DataCell(
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundAltFor(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        AppIconMapper.fromKey(
                          (categoryMap[item.categoryId] ?? item.name)
                              .toLowerCase(),
                        ),
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text(categoryMap[item.categoryId] ?? 'Unknown')),
              DataCell(Text(item.unit)),
              DataCell(Text(item.srp.toStringAsFixed(2))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => onEdit(item),
                      tooltip: 'Edit commodity',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () => onDelete(item),
                      tooltip: 'Delete commodity',
                      color: AppColors.danger,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _CommodityRow extends StatelessWidget {
  const _CommodityRow({
    required this.item,
    required this.categoryName,
    required this.onEdit,
  });

  final CommodityModel item;
  final String categoryName;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.backgroundAlt,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            AppIconMapper.fromKey(categoryName.toLowerCase()),
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '$categoryName | ${item.unit}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'SRP ${item.srp.toStringAsFixed(2)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
      ],
    );
  }
}
