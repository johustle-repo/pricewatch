import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_icon_mapper.dart';
import '../../../../shared/models/category_model.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().loadCategories();
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
                      action: webLayout
                          ? FilledButton.icon(
                              onPressed: () => _openCategoryDialog(),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add category'),
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
                                  i < controller.categories.length;
                                  i++
                                ) ...[
                                  _CategoryRow(
                                    item: controller.categories[i],
                                    onEdit: () => _openCategoryDialog(
                                      category: controller.categories[i],
                                    ),
                                  ),
                                  if (i != controller.categories.length - 1)
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
              await context.read<AdminController>().saveCategory(
                id: category?.id,
                name: nameController.text,
                icon: selectedIcon,
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
                        color: AppColors.primaryDark,
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
