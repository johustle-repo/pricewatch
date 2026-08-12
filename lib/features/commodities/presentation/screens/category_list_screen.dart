import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_icon_mapper.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_notification_button.dart';
import '../../../../shared/widgets/app_shell_menu_button.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/responsive_page.dart';
import '../controllers/commodity_controller.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommodityController>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final useWebShell = MediaQuery.sizeOf(context).width >= 1024;
    final controller = context.watch<CommodityController>();
    final categories = controller.categories;

    return Scaffold(
      appBar: useWebShell
          ? null
          : AppBar(
              leading: const AppShellMenuButton(),
              title: const Text('Categories'),
              actions: const [AppNotificationButton(), SizedBox(width: 8)],
            ),
      body: AppBackground(
        child: categories.isEmpty
            ? const EmptyStateView(
                title: 'No categories available',
                message: 'Try refreshing the local database state.',
                icon: Icons.category_outlined,
              )
            : ResponsivePage(
                maxWidth: 1160,
                expandHeight: true,
                horizontalPadding: 0,
                topPadding: 0,
                bottomPadding: 0,
                edgeToEdgeDesktopOnly: true,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Container(
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
                              Text(
                                'Browse by category',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Start with your most-tracked essentials and jump straight into local price intelligence.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.86,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.crossAxisExtent;
                        final crossAxisCount = width >= 1040
                            ? 4
                            : width >= 760
                            ? 3
                            : 2;

                        return SliverGrid(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final category = categories[index];
                            return AppSurfaceCard(
                              onTap: () => context.push(
                                '/commodities?categoryId=${category.id}',
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundAlt,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(
                                      AppIconMapper.fromKey(category.icon),
                                      color: AppColors.primaryDark,
                                      size: 26,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    category.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tap to view commodities',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            );
                          }, childCount: categories.length),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: width >= 760 ? 1.02 : 0.94,
                              ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
