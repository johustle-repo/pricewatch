import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_icon_mapper.dart';
import '../../../../shared/models/category_model.dart';
import '../../../../shared/models/subcategory_model.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_page_frame.dart';
import '../widgets/admin_workspace_widgets.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  static const _iconOptions = ['rice', 'eggs', 'vegetables', 'fish', 'meat'];
  final _searchController = TextEditingController();

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
      await controller.loadSubcategories();
      await controller.loadCommodities();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();
    final webLayout = useAdminWebLayout(context);
    final query = _searchController.text.trim().toLowerCase();
    final visibleCategories = controller.categories
        .where(
          (item) => query.isEmpty || item.name.toLowerCase().contains(query),
        )
        .toList();
    final commodityCounts = <int, int>{};
    for (final commodity in controller.commodities) {
      final subcategoryId = commodity.subcategoryId;
      if (subcategoryId != null) {
        commodityCounts[subcategoryId] =
            (commodityCounts[subcategoryId] ?? 0) + 1;
      }
    }

    return Scaffold(
      appBar: webLayout ? null : AppBar(title: const Text('Manage Categories')),
      floatingActionButton: webLayout
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openCategoryDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            ),
      body: AppBackground(
        showTopGlow: false,
        child: controller.isLoading && controller.categories.isEmpty
            ? const ListLoadingView(cardCount: 5)
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
                      title: 'Categories',
                      subtitle:
                          'Manage the category list used across PriceWatch.',
                      icon: Icons.category_rounded,
                      webActionAtTop: true,
                      action: webLayout
                          ? SizedBox(
                              width: 220,
                              child: FilledButton.icon(
                                onPressed: () => _openCategoryDialog(),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add category'),
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
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText: 'Search categories',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    visibleCategories.isEmpty
                        ? const AppSurfaceCard(
                            radius: 28,
                            child: EmptyStateView(
                              title: 'No categories yet',
                              message:
                                  'Create the first category to organize commodities across the app.',
                              icon: Icons.category_outlined,
                            ),
                          )
                        : webLayout
                        ? _CategoriesTable(
                            categories: visibleCategories,
                            onEdit: (category) =>
                                _openCategoryDialog(category: category),
                            onDelete: _confirmDelete,
                          )
                        : AppSurfaceCard(
                            radius: 28,
                            child: Column(
                              children: [
                                for (
                                  var i = 0;
                                  i < visibleCategories.length;
                                  i++
                                ) ...[
                                  _CategoryRow(
                                    item: visibleCategories[i],
                                    onEdit: () => _openCategoryDialog(
                                      category: visibleCategories[i],
                                    ),
                                  ),
                                  if (i != visibleCategories.length - 1)
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
                    if (visibleCategories.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _SubcategoriesHeader(
                        onApplySuggested: controller.isLoading
                            ? null
                            : _applySuggestedSubcategories,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (final category in visibleCategories) ...[
                        _SubcategoryCard(
                          category: category,
                          subcategories: controller.subcategories
                              .where((item) => item.categoryId == category.id)
                              .toList(),
                          commodityCounts: commodityCounts,
                          onAdd: () => _openSubcategoryDialog(
                            controller.categories,
                            categoryId: category.id,
                          ),
                          onEdit: (subcategory) => _openSubcategoryDialog(
                            controller.categories,
                            subcategory: subcategory,
                          ),
                          onDelete: _confirmDeleteSubcategory,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _openCategoryDialog({CategoryModel? category}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.name ?? '');
    var selectedIcon = category?.icon ?? _iconOptions.first;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add category' : 'Edit category'),
        content: StatefulBuilder(
          builder: (context, setState) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Category name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Name is required.'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedIcon,
                  decoration: const InputDecoration(labelText: 'Icon key'),
                  items: _iconOptions
                      .map(
                        (icon) =>
                            DropdownMenuItem(value: icon, child: Text(icon)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedIcon = value);
                    }
                  },
                ),
              ],
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
              final saved = await context.read<AdminController>().saveCategory(
                id: category?.id,
                name: nameController.text,
                icon: selectedIcon,
              );
              if (saved && context.mounted) {
                Navigator.of(context).pop();
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.read<AdminController>().error ??
                          'Could not save the category.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(CategoryModel category) async {
    if (category.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category'),
        content: Text(
          'Delete ${category.name}? Categories with commodities are protected.',
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
    await context.read<AdminController>().deleteCategory(category.id!);
  }

  Future<void> _openSubcategoryDialog(
    List<CategoryModel> categories, {
    int? categoryId,
    SubcategoryModel? subcategory,
  }) async {
    final fallbackCategoryId = categoryId ?? categories.firstOrNull?.id;
    if (fallbackCategoryId == null) return;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: subcategory?.name ?? '');
    var selectedCategoryId = subcategory?.categoryId ?? fallbackCategoryId;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          subcategory == null ? 'Add sub-category' : 'Edit sub-category',
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  isExpanded: true,
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Sub-category name',
                    hintText: 'e.g. Bangus, Tilapia, Galunggong',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Name is required.'
                      : null,
                ),
              ],
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
              final saved = await context
                  .read<AdminController>()
                  .saveSubcategory(
                    id: subcategory?.id,
                    categoryId: selectedCategoryId,
                    name: nameController.text,
                  );
              if (saved && context.mounted) {
                Navigator.of(context).pop();
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.read<AdminController>().error ??
                          'Could not save the sub-category.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteSubcategory(SubcategoryModel subcategory) async {
    if (subcategory.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete sub-category'),
        content: Text(
          'Delete ${subcategory.name}? Sub-categories with commodities are protected.',
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
    await context.read<AdminController>().deleteSubcategory(subcategory.id!);
  }

  Future<void> _applySuggestedSubcategories() async {
    final controller = context.read<AdminController>();
    final result = await controller.applySuggestedSubcategories();
    if (!mounted || result == null) return;
    final (created, linked) = result;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added $created sub-categories and linked $linked commodities.',
        ),
      ),
    );
  }
}

class _SubcategoriesHeader extends StatelessWidget {
  const _SubcategoriesHeader({required this.onApplySuggested});

  final VoidCallback? onApplySuggested;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sub-categories',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Group commodities inside each category, such as Tilapia, Galunggong, and Bangus under Fish. Prices are recorded per commodity and summarized per sub-category.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
      ],
    );
    final button = OutlinedButton.icon(
      onPressed: onApplySuggested,
      icon: const Icon(Icons.auto_awesome_outlined),
      label: const Text('Add suggested sub-categories'),
      // The theme's full-width minimum size cannot be laid out inside a Row.
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text,
              const SizedBox(height: AppSpacing.sm),
              button,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: text),
            const SizedBox(width: AppSpacing.md),
            button,
          ],
        );
      },
    );
  }
}

class _SubcategoryCard extends StatelessWidget {
  const _SubcategoryCard({
    required this.category,
    required this.subcategories,
    required this.commodityCounts,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryModel category;
  final List<SubcategoryModel> subcategories;
  final Map<int, int> commodityCounts;
  final VoidCallback onAdd;
  final ValueChanged<SubcategoryModel> onEdit;
  final ValueChanged<SubcategoryModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppIconMapper.fromKey(category.icon),
                color: AppColors.accentFor(context),
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (subcategories.isEmpty)
            Text(
              'No sub-categories yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final subcategory in subcategories)
                  InputChip(
                    label: Text(
                      '${subcategory.name} (${commodityCounts[subcategory.id] ?? 0})',
                    ),
                    tooltip: 'Edit ${subcategory.name}',
                    onPressed: () => onEdit(subcategory),
                    deleteButtonTooltipMessage: 'Delete ${subcategory.name}',
                    onDeleted: () => onDelete(subcategory),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoriesTable extends StatelessWidget {
  const _CategoriesTable({
    required this.categories,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel> onEdit;
  final ValueChanged<CategoryModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return AdminDataTableCard(
      minWidth: 820,
      columns: const ['Category', 'Icon key', 'Created', 'Actions'],
      rows: [
        for (final category in categories)
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
                        AppIconMapper.fromKey(category.icon),
                        color: AppColors.accentFor(context),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text(category.icon ?? 'none')),
              DataCell(Text(category.createdAt.substring(0, 10))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => onEdit(category),
                      tooltip: 'Edit category',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () => onDelete(category),
                      tooltip: 'Delete category',
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

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.item, required this.onEdit});

  final CategoryModel item;
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
            AppIconMapper.fromKey(item.icon),
            color: AppColors.accentFor(context),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Icon key: ${item.icon ?? 'none'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
