import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/store_qr_codec.dart';
import '../../../../features/admin/presentation/widgets/admin_page_frame.dart';
import '../../../../features/admin/presentation/widgets/admin_workspace_widgets.dart';
import '../../../../features/reports/data/report_repository.dart';
import '../../../../features/stores/data/store_repository.dart';
import '../../../../shared/models/commodity_model.dart';
import '../../../../shared/models/category_model.dart';
import '../../../../shared/models/price_entry_model.dart';
import '../../../../shared/models/store_model.dart';
import '../../../../shared/models/ui_models.dart';
import '../../../../shared/widgets/adaptive_stat_grid.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_seal_badge.dart';
import '../../../../shared/widgets/app_shell_menu_button.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/responsive_page.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'vendor_dashboard_screen.dart';
import 'vendor_store_qr_screen.dart';

class VendorWorkspaceScreen extends StatefulWidget {
  const VendorWorkspaceScreen({
    super.key,
    this.autoOpenAddProduct = false,
    this.section = 'dashboard',
  });

  final bool autoOpenAddProduct;
  final String section;

  @override
  State<VendorWorkspaceScreen> createState() => _VendorWorkspaceScreenState();
}

class _VendorWorkspaceScreenState extends State<VendorWorkspaceScreen> {
  Future<_VendorWorkspaceData>? _future;
  int? _loadedStoreId;
  bool _handledAutoOpen = false;

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<AuthController>().currentUser;
    final storeId = vendor?.storeId;
    final webLayout = useAdminWebLayout(context);
    if (storeId != null && storeId != _loadedStoreId) {
      _loadedStoreId = storeId;
      _future = _load(context, storeId);
    }

    return Scaffold(
      appBar: webLayout
          ? null
          : AppBar(
              leading: const AppShellMenuButton(),
              title: const Text('Vendor Workspace'),
              actions: [
                IconButton(
                  tooltip: 'Public view',
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.monitor_rounded),
                ),
              ],
            ),
      body: AppBackground(
        showTopGlow: !webLayout,
        child: storeId == null
            ? const _UnassignedVendorView()
            : FutureBuilder<_VendorWorkspaceData>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const ResponsivePage(
                      maxWidth: 1360,
                      child: ListLoadingView(cardCount: 6),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return EmptyStateView(
                      title: 'Shop unavailable',
                      message:
                          snapshot.error?.toString().replaceFirst(
                            'Exception: ',
                            '',
                          ) ??
                          'We could not load your assigned shop.',
                      icon: Icons.storefront_outlined,
                      action: FilledButton.icon(
                        onPressed: () =>
                            setState(() => _future = _load(context, storeId)),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try again'),
                      ),
                    );
                  }

                  final data = snapshot.data!;
                  if (widget.autoOpenAddProduct && !_handledAutoOpen) {
                    _handledAutoOpen = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _openAddProductDialog(data);
                      }
                    });
                  }
                  if (webLayout) {
                    // The workspace already owns its viewport. Wrapping that
                    // viewport in AdminPageFrame introduced an Align /
                    // ConstrainedBox chain that could not resolve the child's
                    // height during web breakpoint changes.
                    return _VendorWebWorkspace(
                      data: data,
                      section: widget.section,
                      onAddProduct: () => _openAddProductDialog(data),
                      onRefresh: () =>
                          setState(() => _future = _load(context, storeId)),
                      onUpdateProduct: (product) =>
                          _openAddProductDialog(data, existing: product),
                      onRemoveProduct: (product) =>
                          _removeProduct(data, product),
                    );
                  }
                  return ResponsivePage(
                    maxWidth: 1220,
                    horizontalPadding: 0,
                    topPadding: 0,
                    bottomPadding: AppSpacing.xxl,
                    edgeToEdgeDesktopOnly: true,
                    child: _VendorWorkspaceContent(
                      data: data,
                      webLayout: false,
                      onAddProduct: () => _openAddProductDialog(data),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<_VendorWorkspaceData> _load(BuildContext context, int storeId) async {
    final storeRepository = context.read<StoreRepository>();
    final reportRepository = context.read<ReportRepository>();
    final store = await storeRepository.getStoreDetail(storeId);
    final reports = await reportRepository.getStoreReports(storeId);
    final catalog = await storeRepository.getProductCatalog();
    final categories = await storeRepository.getProductCategories();
    final priceHistory = await storeRepository.getStorePriceHistory(storeId);
    return _VendorWorkspaceData(
      store: store,
      reports: reports,
      catalog: catalog,
      categories: categories,
      priceHistory: priceHistory,
    );
  }

  Future<void> _openAddProductDialog(
    _VendorWorkspaceData data, {
    StoreCommodityPrice? existing,
  }) async {
    final formKey = GlobalKey<FormState>();
    final priceController = TextEditingController(
      text: existing?.latestPrice.toStringAsFixed(2) ?? '',
    );
    final listedIds = data.store.prices
        .map((price) => price.commodityId)
        .toSet();
    final availableCatalog = existing == null
        ? data.catalog
              .where((commodity) => !listedIds.contains(commodity.id))
              .toList()
        : data.catalog;
    if (existing == null && availableCatalog.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Every available commodity is already listed.'),
        ),
      );
      return;
    }
    var selectedCommodityId =
        existing?.commodityId ?? availableCatalog.first.id;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add product' : 'Update selling price'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedCommodityId,
                  disabledHint: existing == null
                      ? null
                      : Text(existing.commodityName),
                  decoration: const InputDecoration(labelText: 'Product'),
                  items: availableCatalog
                      .map(
                        (commodity) => DropdownMenuItem<int>(
                          value: commodity.id,
                          child: Text(commodity.name),
                        ),
                      )
                      .toList(),
                  validator: (value) =>
                      value == null ? 'Select a product.' : null,
                  onChanged: existing == null
                      ? (value) => selectedCommodityId = value
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Selling price',
                    prefixText: 'PHP ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final price = double.tryParse((value ?? '').trim());
                    if (price == null || price <= 0) {
                      return 'Enter a valid price.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }
              Navigator.of(context).pop(true);
            },
            icon: Icon(
              existing == null ? Icons.add_rounded : Icons.save_rounded,
            ),
            label: Text(existing == null ? 'Add' : 'Save price'),
          ),
        ],
      ),
    );

    final assignedStoreId = data.store.store.id;
    final commodityId = selectedCommodityId;
    if (submitted != true ||
        !mounted ||
        commodityId == null ||
        assignedStoreId == null) {
      return;
    }

    try {
      await context.read<StoreRepository>().addVendorProductPrice(
        storeId: assignedStoreId,
        commodityId: commodityId,
        price: double.parse(priceController.text.trim()),
      );
      if (mounted) {
        setState(() => _future = _load(context, assignedStoreId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing == null
                  ? 'Product price added successfully.'
                  : '${existing.commodityName} price updated successfully.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save price: $error')));
      }
    } finally {
      priceController.dispose();
    }
  }

  Future<void> _removeProduct(
    _VendorWorkspaceData data,
    StoreCommodityPrice product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove product?'),
        content: Text(
          'Remove ${product.commodityName} and its price history from this store?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    final storeId = data.store.store.id;
    if (confirmed != true || storeId == null || !mounted) return;
    try {
      await context.read<StoreRepository>().removeVendorProduct(
        storeId: storeId,
        commodityId: product.commodityId,
      );
      if (mounted) {
        setState(() => _future = _load(context, storeId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.commodityName} removed.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove product: $error')),
        );
      }
    }
  }
}

class _VendorWorkspaceContent extends StatelessWidget {
  const _VendorWorkspaceContent({
    required this.data,
    required this.webLayout,
    required this.onAddProduct,
  });

  final _VendorWorkspaceData data;
  final bool webLayout;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: webLayout
          ? const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            )
          : EdgeInsets.zero,
      children: [
        if (webLayout)
          AdminPageHeader(
            eyebrow: 'Vendor workspace',
            title: data.store.store.name,
            subtitle:
                '${data.store.store.marketName ?? 'Verified shop'} - ${data.store.store.address}',
            icon: Icons.storefront_rounded,
            action: FilledButton.icon(
              onPressed: onAddProduct,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add product'),
            ),
            metrics: [
              AdminHeaderMetric(
                label: 'Products',
                value: '${data.store.prices.length}',
                icon: Icons.inventory_2_outlined,
              ),
              AdminHeaderMetric(
                label: 'Pending reports',
                value: '${data.pendingReports.length}',
                icon: Icons.pending_actions_outlined,
                accent: AppColors.warning,
              ),
              const AdminHeaderMetric(
                label: 'Assignment',
                value: 'Verified',
                icon: Icons.verified_user_outlined,
                accent: AppColors.sky,
              ),
            ],
          )
        else
          _VendorHero(data: data),
        const SizedBox(height: AppSpacing.lg),
        _VendorToolsSection(data: data, onAddProduct: onAddProduct),
        const SizedBox(height: AppSpacing.lg),
        if (!webLayout) ...[
          _VendorSummaryBand(data: data),
          const SizedBox(height: AppSpacing.xl),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 920;
            if (!wide) {
              return Column(
                children: [
                  _VendorQrCard(data: data),
                  const SizedBox(height: AppSpacing.md),
                  _VendorReportsCard(data: data),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _VendorQrCard(data: data)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _VendorReportsCard(data: data)),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        _VendorProductsCard(
          data: data,
          webLayout: webLayout,
          onAddProduct: onAddProduct,
        ),
      ],
    );
  }
}

class _VendorWebWorkspace extends StatelessWidget {
  const _VendorWebWorkspace({
    required this.data,
    required this.section,
    required this.onAddProduct,
    required this.onRefresh,
    required this.onUpdateProduct,
    required this.onRemoveProduct,
  });

  final _VendorWorkspaceData data;
  final String section;
  final VoidCallback onAddProduct;
  final VoidCallback onRefresh;
  final ValueChanged<StoreCommodityPrice> onUpdateProduct;
  final ValueChanged<StoreCommodityPrice> onRemoveProduct;

  @override
  Widget build(BuildContext context) {
    final store = data.store.store;
    final addressLine = [
      store.marketName ?? 'Verified shop',
      store.address,
      store.city,
    ].where((item) => (item ?? '').trim().isNotEmpty).join(' - ');

    if (section == 'products') {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xxxl,
        ),
        children: [
          _VendorSectionHeader(
            eyebrow: 'Products & prices',
            title: store.name,
            subtitle:
                'Maintain your shop inventory and current selling prices.',
            icon: Icons.inventory_2_rounded,
            onRefresh: onRefresh,
          ),
          const SizedBox(height: AppSpacing.xl),
          _VendorProductsTable(
            data: data,
            onAddProduct: onAddProduct,
            onUpdateProduct: onUpdateProduct,
            onRemoveProduct: onRemoveProduct,
          ),
        ],
      );
    }
    if (section == 'qr') {
      return VendorStoreQrScreen(store: store, onRefresh: onRefresh);
    }
    return VendorDashboardScreen(
      data: VendorDashboardData(
        storeName: store.name,
        location: addressLine,
        products: data.store.prices,
        staleCount: data.stalePrices.length,
        aboveSrpCount: data.aboveSrpPrices.length,
        pendingReportCount: data.pendingReports.length,
      ),
      onAddProduct: onAddProduct,
      onRefresh: onRefresh,
    );
    /* old dashboard removed
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      children: [
        _VendorDashboardHeader(
          eyebrow: 'Today’s store status',
          title: store.name,
          subtitle: addressLine,
          icon: Icons.storefront_rounded,
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.outlined(
                tooltip: 'Refresh workspace',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: onAddProduct,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add product'),
              ),
            ],
          ),
          metrics: [
            AdminHeaderMetric(
              label: 'Need price update',
              value: '${data.stalePrices.length}',
              icon: Icons.update_rounded,
              accent: AppColors.warning,
            ),
            AdminHeaderMetric(
              label: 'Pending reports',
              value: '${data.pendingReports.length}',
              icon: Icons.pending_actions_outlined,
              accent: AppColors.warning,
            ),
            AdminHeaderMetric(
              label: 'Above SRP',
              value: '${data.aboveSrpPrices.length}',
              icon: Icons.trending_up_rounded,
              accent: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _VendorNewDashboard(data: data, onAddProduct: onAddProduct),
      ],
    ); */
  }
}

// ignore: unused_element
class _VendorNewDashboard extends StatelessWidget {
  const _VendorNewDashboard({required this.data, required this.onAddProduct});

  final _VendorWorkspaceData data;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    final products = data.store.prices.take(6).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Store overview',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _VendorNewStat(
              icon: Icons.inventory_2_rounded,
              label: 'Listed products',
              value: '${data.store.prices.length}',
            ),
            _VendorNewStat(
              icon: Icons.update_rounded,
              label: 'Need update',
              value: '${data.stalePrices.length}',
            ),
            _VendorNewStat(
              icon: Icons.trending_up_rounded,
              label: 'Above SRP',
              value: '${data.aboveSrpPrices.length}',
            ),
            _VendorNewStat(
              icon: Icons.assignment_outlined,
              label: 'Pending reports',
              value: '${data.pendingReports.length}',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            FilledButton.icon(
              onPressed: onAddProduct,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add product'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/vendor/products'),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Manage products'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/reports'),
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('View reports'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/vendor/qr'),
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text('Store QR'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderFor(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent commodity prices',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              if (products.isEmpty)
                const Text('No products have been added to this store yet.')
              else
                for (final product in products)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Wrap(
                      spacing: AppSpacing.lg,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 240,
                          child: Text(
                            product.commodityName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        SizedBox(
                          width: 130,
                          child: Text(
                            AppFormatters.currency(product.latestPrice),
                          ),
                        ),
                        SizedBox(
                          width: 130,
                          child: Text(
                            'SRP ${AppFormatters.currency(product.srp)}',
                          ),
                        ),
                        Text(AppFormatters.date(product.recordedAt)),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VendorNewStat extends StatelessWidget {
  const _VendorNewStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: 230,
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.borderFor(context)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

/// Vendor-only dashboard header. It deliberately avoids the shared admin
/// header's responsive flex branches so this page has a stable render tree on
/// Flutter web while the browser is resized or hot restarted.
// ignore: unused_element
class _VendorDashboardHeader extends StatelessWidget {
  // ignore: unused_element_parameter
  const _VendorDashboardHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    // ignore: unused_element_parameter
    this.eyebrow,
    // ignore: unused_element_parameter
    this.action,
    // ignore: unused_element_parameter
    this.metrics = const [],
  });

  final String title;
  final String subtitle;
  final String? eyebrow;
  final IconData icon;
  final Widget? action;
  final List<Widget> metrics;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF111C35), Color(0xFF182845), Color(0xFF223557)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFF2C4164)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: AppSpacing.sm),
        if (eyebrow != null)
          Text(
            eyebrow!,
            style: const TextStyle(
              color: Color(0xFFA8B5CB),
              fontWeight: FontWeight.w800,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFC6D0E0)),
        ),
        if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
        if (metrics.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: metrics,
          ),
        ],
      ],
    ),
  );
}

class _VendorSectionHeader extends StatelessWidget {
  const _VendorSectionHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onRefresh,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => AdminPageHeader(
    eyebrow: eyebrow,
    title: title,
    subtitle: subtitle,
    icon: icon,
    action: IconButton.outlined(
      tooltip: 'Refresh workspace',
      onPressed: onRefresh,
      icon: const Icon(Icons.refresh_rounded),
    ),
  );
}

// Retained for the mobile workspace while the new web dashboard stays isolated.
// ignore: unused_element
class _VendorPriceHealthPanel extends StatelessWidget {
  const _VendorPriceHealthPanel({
    required this.data,
    required this.onUpdateProduct,
    required this.onAddProduct,
  });
  final _VendorWorkspaceData data;
  final ValueChanged<StoreCommodityPrice> onUpdateProduct;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    final prices = data.store.prices;
    final above = prices.where((item) => item.latestPrice > item.srp).toList()
      ..sort((a, b) => _variancePercent(b).compareTo(_variancePercent(a)));
    final atSrp = prices.where((item) => item.latestPrice == item.srp).length;
    final below = prices.where((item) => item.latestPrice < item.srp).length;
    final missing = data.unlistedCatalog.length;
    final latestUpdate = prices.isEmpty
        ? null
        : prices
              .map((price) => DateTime.tryParse(price.recordedAt))
              .whereType<DateTime>()
              .fold<DateTime?>(
                null,
                (latest, value) =>
                    latest == null || value.isAfter(latest) ? value : latest,
              );
    return AdminSectionCard(
      title: 'Commodity monitoring',
      subtitle:
          'Current, previous, and published prices with category-level health.',
      action: AppStatusBadge(
        label: above.isEmpty ? 'Prices healthy' : '${above.length} need review',
        color: above.isEmpty ? AppColors.primaryDark : AppColors.warning,
        icon: above.isEmpty
            ? Icons.verified_rounded
            : Icons.warning_amber_rounded,
      ),
      child: prices.isEmpty
          ? const EmptyStateView(
              title: 'No prices to monitor',
              message: 'Add your first commodity price to begin monitoring.',
              icon: Icons.monitor_heart_outlined,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _VendorHealthMetric(
                      label: 'At SRP',
                      value: '$atSrp',
                      color: AppColors.sky,
                      icon: Icons.balance_rounded,
                    ),
                    _VendorHealthMetric(
                      label: 'Below SRP',
                      value: '$below',
                      color: AppColors.primaryDark,
                      icon: Icons.trending_down_rounded,
                    ),
                    _VendorHealthMetric(
                      label: 'Above SRP',
                      value: '${above.length}',
                      color: AppColors.warning,
                      icon: Icons.trending_up_rounded,
                    ),
                    _VendorHealthMetric(
                      label: 'Stale prices',
                      value: '${data.stalePrices.length}',
                      color: Colors.deepOrange,
                      icon: Icons.schedule_rounded,
                    ),
                    _VendorHealthMetric(
                      label: 'Missing prices',
                      value: '$missing',
                      color: AppColors.textSecondaryFor(context),
                      icon: Icons.remove_circle_outline_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  latestUpdate == null
                      ? 'No successful price update yet'
                      : 'Last price update: ${AppFormatters.date(latestUpdate.toIso8601String())}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  above.isEmpty
                      ? 'No SRP exceptions'
                      : 'Review these prices first',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                if (above.isEmpty)
                  const Text(
                    'All listed commodities are currently at or below SRP.',
                  )
                else
                  for (final item in above.take(5))
                    _VendorAttentionPrice(
                      item: item,
                      history: data.priceHistory[item.commodityId] ?? const [],
                      onTap: () => onUpdateProduct(item),
                    ),
                if (data.unlistedCatalog.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: onAddProduct,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      'Add prices for ${data.unlistedCatalog.length} unlisted commodities',
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _VendorCategorySummary(data: data),
              ],
            ),
    );
  }

  static double _variancePercent(StoreCommodityPrice item) =>
      item.srp == 0 ? 0 : ((item.latestPrice - item.srp) / item.srp) * 100;
}

class _VendorHealthMetric extends StatelessWidget {
  const _VendorHealthMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

class _VendorAttentionPrice extends StatelessWidget {
  const _VendorAttentionPrice({
    required this.item,
    required this.history,
    required this.onTap,
  });

  final StoreCommodityPrice item;
  final List<PriceEntryModel> history;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final difference = item.latestPrice - item.srp;
    final percentage = item.srp == 0 ? 0.0 : (difference / item.srp) * 100;
    final previous = history.length > 1 ? history[1].price : item.latestPrice;
    final severe = percentage >= 10;
    final color = severe ? Colors.redAccent : AppColors.warning;
    final recent = history
        .where((entry) {
          final date = DateTime.tryParse(entry.recordedAt);
          return date != null &&
              date.isAfter(DateTime.now().subtract(const Duration(days: 30)));
        })
        .map((entry) => entry.price)
        .toList()
        .reversed
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: .22)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    severe
                        ? Icons.error_outline_rounded
                        : Icons.warning_amber_rounded,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.commodityName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Current ${AppFormatters.currency(item.latestPrice)}  |  Previous ${AppFormatters.currency(previous)}  |  SRP ${AppFormatters.currency(item.srp)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (recent.length > 1) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    height: 34,
                    child: CustomPaint(
                      painter: _VendorMiniTrendPainter(
                        values: recent,
                        color: color,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${AppFormatters.currency(difference)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '+${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VendorMiniTrendPainter extends CustomPainter {
  const _VendorMiniTrendPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(maxValue - minValue, 1.0);
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final y =
          size.height - ((values[index] - minValue) / range * size.height);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _VendorMiniTrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class _VendorCategorySummary extends StatelessWidget {
  const _VendorCategorySummary({required this.data});

  final _VendorWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<StoreCommodityPrice>>{};
    for (final price in data.store.prices) {
      groups
          .putIfAbsent(data.categoryNameFor(price.commodityId), () => [])
          .add(price);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category health',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final entry in groups.entries)
              SizedBox(
                width: 240,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMutedFor(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderFor(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.value.where((price) => price.latestPrice > price.srp).length}/${entry.value.length} above',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _VendorProductsTable extends StatefulWidget {
  const _VendorProductsTable({
    required this.data,
    required this.onAddProduct,
    required this.onUpdateProduct,
    required this.onRemoveProduct,
  });

  final _VendorWorkspaceData data;
  final VoidCallback onAddProduct;
  final ValueChanged<StoreCommodityPrice> onUpdateProduct;
  final ValueChanged<StoreCommodityPrice> onRemoveProduct;

  @override
  State<_VendorProductsTable> createState() => _VendorProductsTableState();
}

class _VendorProductsTableState extends State<_VendorProductsTable> {
  String _query = '';
  String _status = 'all';
  String _sort = 'name';

  @override
  Widget build(BuildContext context) {
    final products = widget.data.store.prices.where((product) {
      final matchesQuery = product.commodityName.toLowerCase().contains(
        _query.trim().toLowerCase(),
      );
      final above = product.latestPrice > product.srp;
      final matchesStatus =
          _status == 'all' ||
          (_status == 'above' && above) ||
          (_status == 'within' && !above);
      return matchesQuery && matchesStatus;
    }).toList();
    switch (_sort) {
      case 'price':
        products.sort((a, b) => b.latestPrice.compareTo(a.latestPrice));
      case 'variance':
        products.sort(
          (a, b) => (b.latestPrice - b.srp).compareTo(a.latestPrice - a.srp),
        );
      case 'updated':
        products.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      default:
        products.sort((a, b) => a.commodityName.compareTo(b.commodityName));
    }
    return AdminSectionCard(
      title: 'Product prices',
      subtitle:
          'Search, review, and maintain current selling prices for this shop.',
      action: FilledButton.icon(
        onPressed: widget.onAddProduct,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add product'),
      ),
      child: widget.data.store.prices.isEmpty
          ? EmptyStateView(
              title: 'No products listed',
              message: 'Record your first selling price to begin monitoring.',
              icon: Icons.inventory_2_outlined,
              action: FilledButton.icon(
                onPressed: widget.onAddProduct,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add first product'),
              ),
            )
          : Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final search = TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search products',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    );
                    final filters = Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _status,
                            decoration: const InputDecoration(
                              labelText: 'SRP status',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All'),
                              ),
                              DropdownMenuItem(
                                value: 'within',
                                child: Text('Within SRP'),
                              ),
                              DropdownMenuItem(
                                value: 'above',
                                child: Text('Above SRP'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _status = value ?? 'all'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _sort,
                            decoration: const InputDecoration(
                              labelText: 'Sort',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'name',
                                child: Text('Product name'),
                              ),
                              DropdownMenuItem(
                                value: 'price',
                                child: Text('Highest price'),
                              ),
                              DropdownMenuItem(
                                value: 'variance',
                                child: Text('Highest variance'),
                              ),
                              DropdownMenuItem(
                                value: 'updated',
                                child: Text('Recently updated'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _sort = value ?? 'name'),
                          ),
                        ),
                      ],
                    );
                    return constraints.maxWidth < 720
                        ? Column(
                            children: [
                              search,
                              const SizedBox(height: 10),
                              filters,
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(flex: 3, child: search),
                              const SizedBox(width: 12),
                              Expanded(flex: 2, child: filters),
                            ],
                          );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                if (products.isEmpty)
                  const EmptyStateView(
                    title: 'No matching products',
                    message: 'Change the search or SRP filter and try again.',
                    icon: Icons.search_off_rounded,
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) =>
                        constraints.maxWidth < 760
                        ? _VendorProductCards(
                            products: products,
                            data: widget.data,
                            onUpdate: widget.onUpdateProduct,
                            onHistory: _showHistory,
                            onRemove: widget.onRemoveProduct,
                          )
                        : AdminDataTableCard(
                            minWidth: 1280,
                            columns: const [
                              'Product',
                              'Category',
                              'Unit',
                              'Previous',
                              'Current',
                              'SRP',
                              'Difference',
                              'Status',
                              'Last updated',
                              'Actions',
                            ],
                            rows: [
                              for (final price in products)
                                _productRow(context, price),
                            ],
                          ),
                  ),
              ],
            ),
    );
  }

  DataRow _productRow(BuildContext context, StoreCommodityPrice price) {
    final history = widget.data.priceHistory[price.commodityId] ?? const [];
    final previous = history.length > 1 ? history[1].price : price.latestPrice;
    return DataRow(
      cells: [
        DataCell(
          _VendorTableNameCell(
            icon: Icons.shopping_basket_rounded,
            title: price.commodityName,
            subtitle: 'Store-listed commodity',
          ),
        ),
        DataCell(Text(widget.data.categoryNameFor(price.commodityId))),
        DataCell(Text(price.unit)),
        _numericCell(AppFormatters.currency(previous)),
        _numericCell(
          AppFormatters.currency(price.latestPrice),
          emphasized: true,
        ),
        _numericCell(AppFormatters.currency(price.srp)),
        DataCell(_VariancePill(value: price.latestPrice - price.srp)),
        DataCell(_VendorPriceStatus(price: price, data: widget.data)),
        DataCell(Text(AppFormatters.date(price.recordedAt))),
        DataCell(
          _VendorProductActions(
            product: price,
            onUpdate: widget.onUpdateProduct,
            onHistory: _showHistory,
            onRemove: widget.onRemoveProduct,
          ),
        ),
      ],
    );
  }

  DataCell _numericCell(String value, {bool emphasized = false}) => DataCell(
    Align(
      alignment: Alignment.centerRight,
      child: Text(
        value,
        textAlign: TextAlign.right,
        style: emphasized ? const TextStyle(fontWeight: FontWeight.w900) : null,
      ),
    ),
  );

  void _showHistory(StoreCommodityPrice product) {
    final history = widget.data.priceHistory[product.commodityId] ?? const [];
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${product.commodityName} price history'),
        content: SizedBox(
          width: 460,
          child: history.isEmpty
              ? const Text('No price history is available.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        AppFormatters.currency(entry.price),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(AppFormatters.date(entry.recordedAt)),
                      trailing: Text(entry.source.toUpperCase()),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _VendorProductCards extends StatelessWidget {
  const _VendorProductCards({
    required this.products,
    required this.data,
    required this.onUpdate,
    required this.onHistory,
    required this.onRemove,
  });

  final List<StoreCommodityPrice> products;
  final _VendorWorkspaceData data;
  final ValueChanged<StoreCommodityPrice> onUpdate;
  final ValueChanged<StoreCommodityPrice> onHistory;
  final ValueChanged<StoreCommodityPrice> onRemove;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < products.length; index++) ...[
        _VendorProductMobileCard(
          product: products[index],
          data: data,
          onUpdate: onUpdate,
          onHistory: onHistory,
          onRemove: onRemove,
        ),
        if (index < products.length - 1) const SizedBox(height: 12),
      ],
    ],
  );
}

class _VendorProductMobileCard extends StatelessWidget {
  const _VendorProductMobileCard({
    required this.product,
    required this.data,
    required this.onUpdate,
    required this.onHistory,
    required this.onRemove,
  });

  final StoreCommodityPrice product;
  final _VendorWorkspaceData data;
  final ValueChanged<StoreCommodityPrice> onUpdate;
  final ValueChanged<StoreCommodityPrice> onHistory;
  final ValueChanged<StoreCommodityPrice> onRemove;

  @override
  Widget build(BuildContext context) {
    final history = data.priceHistory[product.commodityId] ?? const [];
    final previous = history.length > 1
        ? history[1].price
        : product.latestPrice;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.commodityName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${data.categoryNameFor(product.commodityId)} | ${product.unit}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _VendorPriceStatus(price: product, data: data),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _VendorPriceDatum(label: 'Previous', value: previous),
              _VendorPriceDatum(label: 'Current', value: product.latestPrice),
              _VendorPriceDatum(label: 'SRP', value: product.srp),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _VariancePill(value: product.latestPrice - product.srp),
              const Spacer(),
              Text(
                AppFormatters.date(product.recordedAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const Divider(height: 24),
          _VendorProductActions(
            product: product,
            onUpdate: onUpdate,
            onHistory: onHistory,
            onRemove: onRemove,
            showLabels: true,
          ),
        ],
      ),
    );
  }
}

class _VendorPriceDatum extends StatelessWidget {
  const _VendorPriceDatum({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 3),
      Text(
        AppFormatters.currency(value),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _VendorPriceStatus extends StatelessWidget {
  const _VendorPriceStatus({required this.price, required this.data});
  final StoreCommodityPrice price;
  final _VendorWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final stale = data.stalePrices.any(
      (item) => item.commodityId == price.commodityId,
    );
    final above = price.latestPrice > price.srp;
    final below = price.latestPrice < price.srp;
    final label = stale
        ? 'Stale'
        : above
        ? 'Above SRP'
        : below
        ? 'Below SRP'
        : 'At SRP';
    final color = stale
        ? Colors.deepOrange
        : above
        ? AppColors.warning
        : below
        ? AppColors.primaryDark
        : AppColors.sky;
    return AppStatusBadge(
      label: label,
      color: color,
      icon: stale
          ? Icons.schedule_rounded
          : above
          ? Icons.trending_up_rounded
          : below
          ? Icons.trending_down_rounded
          : Icons.balance_rounded,
    );
  }
}

class _VendorProductActions extends StatelessWidget {
  const _VendorProductActions({
    required this.product,
    required this.onUpdate,
    required this.onHistory,
    required this.onRemove,
    this.showLabels = false,
  });

  final StoreCommodityPrice product;
  final ValueChanged<StoreCommodityPrice> onUpdate;
  final ValueChanged<StoreCommodityPrice> onHistory;
  final ValueChanged<StoreCommodityPrice> onRemove;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    if (showLabels) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.tonalIcon(
            onPressed: () => onUpdate(product),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Update'),
          ),
          OutlinedButton.icon(
            onPressed: () => onHistory(product),
            icon: const Icon(Icons.history_rounded),
            label: const Text('History'),
          ),
          IconButton.outlined(
            tooltip: 'Remove product',
            onPressed: () => onRemove(product),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
            ),
          ),
        ],
      );
    }
    return Wrap(
      spacing: 2,
      children: [
        IconButton(
          tooltip: 'Update price',
          onPressed: () => onUpdate(product),
          icon: const Icon(Icons.edit_rounded),
        ),
        IconButton(
          tooltip: 'View price history',
          onPressed: () => onHistory(product),
          icon: const Icon(Icons.history_rounded),
        ),
        IconButton(
          tooltip: 'Remove product',
          onPressed: () => onRemove(product),
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.redAccent,
          ),
        ),
      ],
    );
  }
}

class _VendorToolsSection extends StatelessWidget {
  const _VendorToolsSection({required this.data, required this.onAddProduct});

  final _VendorWorkspaceData data;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    final storeId = data.store.store.id;
    final tools = [
      _VendorTool(
        title: 'Add Product',
        description: 'Record a fresh selling price for this shop.',
        icon: Icons.add_business_rounded,
        color: AppColors.primary,
        onTap: onAddProduct,
      ),
      _VendorTool(
        title: 'My Products',
        description: '${data.store.prices.length} listed item(s) connected.',
        icon: Icons.inventory_2_rounded,
        color: AppColors.primaryDark,
        onTap: () => context.go('/vendor/products'),
      ),
      _VendorTool(
        title: 'Shop Reports',
        description: '${data.pendingReports.length} pending buyer concern(s).',
        icon: Icons.assignment_rounded,
        color: AppColors.warning,
        onTap: () => context.go('/reports'),
      ),
      _VendorTool(
        title: 'Store QR',
        description: 'Display and download the verified store QR.',
        icon: Icons.qr_code_2_rounded,
        color: AppColors.sky,
        onTap: storeId == null ? null : () => context.go('/vendor/qr'),
      ),
      _VendorTool(
        title: 'Account',
        description: 'Manage vendor profile and password.',
        icon: Icons.person_rounded,
        color: AppColors.primarySoft,
        onTap: () => context.go('/profile'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Vendor tools',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimaryFor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${tools.length} available',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1100
                ? 5
                : constraints.maxWidth >= 820
                ? 3
                : constraints.maxWidth >= 560
                ? 2
                : 1;
            final gap = AppSpacing.md;
            final cardWidth =
                (constraints.maxWidth - (gap * (columns - 1))) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final tool in tools)
                  SizedBox(
                    width: cardWidth,
                    child: _VendorToolCard(tool: tool),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _VendorToolCard extends StatelessWidget {
  const _VendorToolCard({required this.tool});

  final _VendorTool tool;

  @override
  Widget build(BuildContext context) {
    final useDark = AppColors.isDark(context);
    final disabled = tool.onTap == null;
    final color = useDark && tool.color == AppColors.sky
        ? AppColors.darkPrimarySoft
        : tool.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tool.onTap,
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 132),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(
                context,
              ).withValues(alpha: disabled ? 0.68 : 1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.borderFor(
                  context,
                ).withValues(alpha: useDark ? 0.72 : 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: useDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(tool.icon, color: color, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tool.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimaryFor(context),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tool.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryFor(context),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: disabled
                      ? AppColors.textSecondaryFor(
                          context,
                        ).withValues(alpha: 0.45)
                      : AppColors.textSecondaryFor(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VendorTool {
  const _VendorTool({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}

// Retained for the standalone report workspace implementation.
// ignore: unused_element
class _VendorReportsTable extends StatelessWidget {
  const _VendorReportsTable({required this.data});

  final _VendorWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final reports = data.reports;
    return AdminSectionCard(
      title: 'Shop Reports',
      subtitle: 'Buyer reports linked to this shop QR and reviewed by admins.',
      child: reports.isEmpty
          ? const EmptyStateView(
              title: 'No reports',
              message: 'Reports from buyers will appear here.',
              icon: Icons.assignment_outlined,
            )
          : AdminDataTableCard(
              minWidth: 760,
              columns: const [
                'Commodity',
                'Reported by',
                'Observed price',
                'Status',
                'Actions',
              ],
              rows: [
                for (final report in reports)
                  DataRow(
                    cells: [
                      DataCell(
                        _VendorTableNameCell(
                          icon: Icons.flag_rounded,
                          title: report.commodityName,
                          subtitle: report.reason,
                        ),
                      ),
                      DataCell(Text(report.userName)),
                      DataCell(
                        Text(AppFormatters.currency(report.observedPrice)),
                      ),
                      DataCell(_ReportStatusChip(status: report.status)),
                      DataCell(
                        IconButton(
                          tooltip: 'Open report',
                          onPressed: () =>
                              context.push('/report/${report.reportId}'),
                          icon: const Icon(Icons.open_in_new_rounded),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}

// Kept for the compact legacy presentation while the web route uses the
// dedicated A4 workspace.
// ignore: unused_element
class _VendorQrPanel extends StatelessWidget {
  const _VendorQrPanel({required this.data});

  final _VendorWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final qrData = _qrDataForStore();
    final store = data.store.store;
    return AdminSectionCard(
      title: 'Verified QR',
      subtitle: 'Same shop QR format used in the admin store module.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surfaceMutedFor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderFor(context)),
            ),
            child: Column(
              children: [
                if (qrData == null)
                  const SizedBox(
                    height: 220,
                    child: Center(child: Text('QR unavailable')),
                  )
                else
                  _VendorQrPreview(qrData: qrData, size: 220),
                const SizedBox(height: AppSpacing.md),
                Text(
                  store.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  store.marketName ?? 'Verified shop',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppStatusBadge(
                      label: 'Verified store',
                      color: AppColors.primaryDark,
                      icon: Icons.verified_rounded,
                    ),
                    if ((store.ownerName ?? '').trim().isNotEmpty)
                      AppStatusBadge(
                        label: store.ownerName!.trim(),
                        color: AppColors.sky,
                        icon: Icons.person_outline_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  [store.address, store.city]
                      .where((value) => (value ?? '').trim().isNotEmpty)
                      .join(', '),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: qrData == null
                ? null
                : () => _showShopQrDialog(context, qrData),
            icon: const Icon(Icons.qr_code_2_rounded),
            label: const Text('Show QR'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: qrData == null
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: qrData));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Store reference copied.'),
                        ),
                      );
                    }
                  },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy store reference'),
          ),
        ],
      ),
    );
  }

  String? _qrDataForStore() {
    if (data.store.store.id != null) {
      return StoreQrCodec.encode(data.store.store);
    }
    final stored = data.store.store.qrCode?.trim();
    return stored == null || stored.isEmpty ? null : stored;
  }

  void _showShopQrDialog(BuildContext context, String qrData) {
    final exportKey = GlobalKey();
    final store = data.store.store;
    showDialog<void>(
      context: context,
      builder: (context) {
        final screenSize = MediaQuery.sizeOf(context);
        final dialogWidth = math.min(screenSize.width - 32, 420.0);
        final maxDialogHeight = math.min(screenSize.height * 0.88, 720.0);

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: SizedBox(
            width: dialogWidth,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: dialogWidth,
                maxWidth: dialogWidth,
                maxHeight: maxDialogHeight,
              ),
              child: Material(
                color: AppColors.surfaceFor(context),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(color: AppColors.borderFor(context)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${store.name} QR',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: SizedBox(
                          width: 292,
                          child: RepaintBoundary(
                            key: exportKey,
                            child: _VendorStoreQrExportCard(
                              store: store,
                              qrData: qrData,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Buyers can scan this code while reporting so the store details are filled automatically.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () =>
                                  _downloadQrCard(context, exportKey, store),
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Download'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadQrCard(
    BuildContext context,
    GlobalKey key,
    StoreModel store,
  ) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return;
    }

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List();
    if (bytes == null) {
      return;
    }

    final safeName = store.name.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    await FileSaver.instance.saveFile(
      name: '${safeName}_qr_card',
      bytes: bytes,
      fileExtension: 'png',
      mimeType: MimeType.png,
    );

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Store QR card downloaded.')));
  }
}

class _VendorStoreQrExportCard extends StatelessWidget {
  const _VendorStoreQrExportCard({required this.store, required this.qrData});

  final StoreModel store;
  final String qrData;

  @override
  Widget build(BuildContext context) {
    final marketValue = (store.marketName ?? '').trim();
    final market = marketValue.isEmpty ? 'Local market' : marketValue;
    final registered = _safeRegisteredDate(store.createdAt);

    return Container(
      width: 292,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDF4F8), Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9C5D6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9D7E4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE9C5D6)),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/icons/lingayen_project_logo.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/branding/lingayen_seal.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.location_city_rounded,
                              color: AppColors.primaryDark,
                              size: 24,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PriceWatch Store QR',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Municipality of Lingayen',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            store.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            market,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _VendorQrPreview(qrData: qrData, size: 180),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8EAF1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date of registration',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  registered,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _safeRegisteredDate(String iso) {
    try {
      return AppFormatters.date(iso);
    } catch (_) {
      return iso;
    }
  }
}

class _VendorTableNameCell extends StatelessWidget {
  const _VendorTableNameCell({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VariancePill extends StatelessWidget {
  const _VariancePill({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final isOver = value > 0;
    final isEqual = value == 0;
    final color = isEqual
        ? AppColors.textSecondaryFor(context)
        : isOver
        ? AppColors.warning
        : AppColors.sky;
    final label = isEqual
        ? 'At SRP'
        : '${isOver ? '+' : '-'}${AppFormatters.currency(value.abs())}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReportStatusChip extends StatelessWidget {
  const _ReportStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'resolved' => AppColors.sky,
      'reviewed' => AppColors.primaryDark,
      _ => AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VendorQrPreview extends StatelessWidget {
  const _VendorQrPreview({required this.qrData, required this.size});

  final String qrData;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 28,
      height: size + 28,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SizedBox.square(
        dimension: size,
        child: QrImageView(
          data: qrData,
          version: QrVersions.auto,
          size: size,
          backgroundColor: Colors.white,
          gapless: false,
          errorStateBuilder: (context, error) {
            return Center(
              child: Text(
                'QR unavailable',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VendorHero extends StatelessWidget {
  const _VendorHero({required this.data});

  final _VendorWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradientFor(context),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: AppColors.isDark(context) ? 0.28 : 0.16,
            ),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppStatusBadge(
                label: '1 account = 1 shop',
                color: Colors.white,
                icon: Icons.verified_user_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                data.store.store.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${data.store.store.marketName ?? 'Lingayen Municipal Market'}\n${data.store.store.address}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Sell and manage your shop products here. Reports shown in this workspace are only reports attached to this shop.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                  height: 1.45,
                ),
              ),
            ],
          );

          if (compact) {
            return content;
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSealBadge(size: 64, padding: 4, showFrame: false),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

class _VendorQrCard extends StatelessWidget {
  const _VendorQrCard({required this.data});

  final _VendorWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final qrData = _qrDataForStore();
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Shop QR',
            subtitle:
                'Use the same verified store QR format admins assign to shops.',
            icon: Icons.qr_code_2_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceMutedFor(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderFor(context)),
            ),
            child: Column(
              children: [
                if (qrData == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceFor(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderFor(context)),
                    ),
                    child: Text(
                      'This shop does not have enough information to generate a QR code yet. Please contact the administrator.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryFor(context),
                        height: 1.4,
                      ),
                    ),
                  )
                else
                  _VendorQrPreview(qrData: qrData, size: 168),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  qrData == null
                      ? 'QR unavailable'
                      : 'Verified shop QR is ready.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: qrData == null
                      ? null
                      : () => _showShopQrDialog(context, qrData),
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: const Text('Show QR'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'This QR belongs to your verified shop record. Do not share it as another vendor or shop.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryFor(context),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String? _qrDataForStore() {
    if (data.store.store.id != null) {
      return StoreQrCodec.encode(data.store.store);
    }
    final stored = data.store.store.qrCode?.trim();
    return stored == null || stored.isEmpty ? null : stored;
  }

  void _showShopQrDialog(BuildContext context, String qrData) {
    final store = data.store.store;
    showDialog<void>(
      context: context,
      builder: (context) {
        final screenSize = MediaQuery.sizeOf(context);
        final dialogWidth = math.min(screenSize.width - 32, 380.0);
        final qrSize = math.min(dialogWidth - 96, 220.0);

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: screenSize.height * 0.86,
            ),
            child: Material(
              color: AppColors.surfaceFor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
                side: BorderSide(color: AppColors.borderFor(context)),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Verified shop QR',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimaryFor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMutedFor(context),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.borderFor(context)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: _VendorQrPreview(
                              qrData: qrData,
                              size: qrSize,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            store.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.textPrimaryFor(context),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            store.marketName ?? 'Verified shop',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondaryFor(context),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Buyers can scan this QR while reporting so the store details are filled automatically.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryFor(context),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VendorReportsCard extends StatelessWidget {
  const _VendorReportsCard({required this.data});

  final _VendorWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    final reports = data.pendingReports.take(3).toList();
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Reports to My Shop',
            subtitle:
                'These are buyer concerns about this shop. Admin reviews them for action.',
            icon: Icons.assignment_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (reports.isEmpty)
            Text(
              'No pending reports for this shop.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
            )
          else
            ...reports.map(
              (report) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _MiniReportRow(report: report),
              ),
            ),
          if (data.resolvedReports.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _MutedNotice(
              icon: Icons.verified_rounded,
              message:
                  '${data.resolvedReports.length} report(s) already resolved for this shop.',
            ),
          ],
        ],
      ),
    );
  }
}

class _VendorProductsCard extends StatelessWidget {
  const _VendorProductsCard({
    required this.data,
    required this.webLayout,
    required this.onAddProduct,
  });

  final _VendorWorkspaceData data;
  final bool webLayout;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    if (webLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionCard(
            title: 'My Products',
            subtitle:
                'Products are shown as current price entries for this verified shop.',
            action: FilledButton.icon(
              onPressed: onAddProduct,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add product'),
            ),
            child: data.store.prices.isEmpty
                ? const EmptyStateView(
                    title: 'No products listed',
                    message:
                        'Record a product price to make it available in the vendor workspace.',
                    icon: Icons.inventory_2_outlined,
                  )
                : AdminDataTableCard(
                    minWidth: 960,
                    columns: const [
                      'Product',
                      'Unit',
                      'SRP',
                      'Current price',
                      'Updated',
                    ],
                    rows: [
                      for (final price in data.store.prices)
                        DataRow(
                          cells: [
                            DataCell(
                              Text(
                                price.commodityName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            DataCell(Text(price.unit)),
                            DataCell(Text(AppFormatters.currency(price.srp))),
                            DataCell(
                              Text(
                                AppFormatters.currency(price.latestPrice),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            DataCell(
                              Text(AppFormatters.date(price.recordedAt)),
                            ),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      );
    }

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'My Products',
            subtitle:
                'Add products by recording your current selling price for this shop.',
            icon: Icons.inventory_2_rounded,
            action: FilledButton.icon(
              onPressed: onAddProduct,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add product'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (data.store.prices.isEmpty)
            const EmptyStateView(
              title: 'No products listed',
              message:
                  'Ask the admin to add price entries for this verified shop.',
              icon: Icons.inventory_2_outlined,
            )
          else
            ...data.store.prices
                .take(8)
                .map(
                  (price) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: const Icon(
                        Icons.shopping_basket_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(price.commodityName),
                    subtitle: Text(
                      '${price.unit} | SRP ${AppFormatters.currency(price.srp)}',
                    ),
                    trailing: Text(
                      AppFormatters.currency(price.latestPrice),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _VendorSummaryBand extends StatelessWidget {
  const _VendorSummaryBand({required this.data});

  final _VendorWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    return AdaptiveStatGrid(
      minTileWidth: 220,
      children: [
        StatCard(
          title: 'Products',
          value: '${data.store.prices.length}',
          icon: Icons.inventory_2_rounded,
          caption: 'Items currently connected to this shop',
          highlight: true,
        ),
        StatCard(
          title: 'Pending reports',
          value: '${data.pendingReports.length}',
          icon: Icons.pending_actions_rounded,
          caption: data.pendingReports.isEmpty
              ? 'No buyer concerns right now'
              : 'Needs attention from vendor/admin',
        ),
        StatCard(
          title: 'Verification',
          value: 'Assigned',
          icon: Icons.verified_user_rounded,
          caption: 'One vendor account for this shop',
        ),
      ],
    );
  }
}

class _MiniReportRow extends StatelessWidget {
  const _MiniReportRow({required this.report});

  final ReportViewData report;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/report/${report.reportId}'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMutedFor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderFor(context)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.commodityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppFormatters.currency(report.observedPrice)} reported by ${report.userName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryFor(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MutedNotice extends StatelessWidget {
  const _MutedNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondaryFor(context), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryFor(context),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.action,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Align(
              alignment: Alignment.topRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: action!,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _UnassignedVendorView extends StatelessWidget {
  const _UnassignedVendorView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: EmptyStateView(
          title: 'No shop assigned',
          message:
              'A vendor account must be assigned to exactly one verified shop by the admin before it can manage products, QR code, and shop reports.',
          icon: Icons.storefront_outlined,
        ),
      ),
    );
  }
}

class _VendorWorkspaceData {
  const _VendorWorkspaceData({
    required this.store,
    required this.reports,
    required this.catalog,
    required this.categories,
    required this.priceHistory,
  });

  final StoreDetailData store;
  final List<ReportViewData> reports;
  final List<CommodityModel> catalog;
  final List<CategoryModel> categories;
  final Map<int, List<PriceEntryModel>> priceHistory;

  List<ReportViewData> get pendingReports =>
      reports.where((report) => report.status == 'pending').toList();

  List<ReportViewData> get resolvedReports =>
      reports.where((report) => report.status == 'resolved').toList();

  List<StoreCommodityPrice> get aboveSrpPrices =>
      store.prices.where((price) => price.latestPrice > price.srp).toList();

  List<StoreCommodityPrice> get stalePrices {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return store.prices.where((price) {
      final updated = DateTime.tryParse(price.recordedAt);
      return updated == null || updated.isBefore(cutoff);
    }).toList();
  }

  List<CommodityModel> get unlistedCatalog {
    final listedIds = store.prices.map((price) => price.commodityId).toSet();
    return catalog
        .where((commodity) => !listedIds.contains(commodity.id))
        .toList();
  }

  String categoryNameFor(int commodityId) {
    final commodity = catalog
        .where((item) => item.id == commodityId)
        .firstOrNull;
    if (commodity == null) return 'Uncategorized';
    return categories
            .where((category) => category.id == commodity.categoryId)
            .firstOrNull
            ?.name ??
        'Uncategorized';
  }
}
