import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/commodity_model.dart';
import '../../../../shared/models/store_model.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_notification_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_shell_menu_button.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/responsive_page.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../commodities/data/commodity_repository.dart';
import '../../../stores/data/store_repository.dart';
import '../controllers/report_controller.dart';

class AddReportScreen extends StatefulWidget {
  const AddReportScreen({
    super.key,
    this.preselectedCommodityId,
    this.preselectedStoreId,
  });

  final int? preselectedCommodityId;
  final int? preselectedStoreId;

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observedPriceController = TextEditingController();
  final _reasonController = TextEditingController();
  final _photoPathController = TextEditingController();

  List<CommodityModel> _commodities = [];
  List<StoreModel> _stores = [];
  int? _commodityId;
  int? _storeId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOptions());
  }

  @override
  void dispose() {
    _observedPriceController.dispose();
    _reasonController.dispose();
    _photoPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final useWebShell = MediaQuery.sizeOf(context).width >= 1024;
    final reportController = context.watch<ReportController>();
    final theme = Theme.of(context);
    final selectedCommodity = _selectedCommodity;
    final selectedStore = _selectedStore;
    final observedPrice = double.tryParse(_observedPriceController.text.trim());

    return Scaffold(
      appBar: useWebShell
          ? null
          : AppBar(
              leading: const AppShellMenuButton(),
              title: const Text('Report Overpricing'),
              actions: const [AppNotificationButton(), SizedBox(width: 8)],
            ),
      body: AppBackground(
        showTopGlow: false,
        child: _isLoading
            ? const ListLoadingView(cardCount: 4)
            : _commodities.isEmpty || _stores.isEmpty
            ? ResponsivePage(
                maxWidth: 980,
                horizontalPadding: 0,
                topPadding: AppSpacing.sm,
                bottomPadding: 0,
                edgeToEdgeDesktopOnly: true,
                child: AppSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cannot create report yet',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'At least one commodity and one store are required before a report can be submitted.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            : ResponsivePage(
                maxWidth: 1120,
                horizontalPadding: 0,
                topPadding: AppSpacing.sm,
                bottomPadding: AppSpacing.xxl,
                edgeToEdgeDesktopOnly: true,
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceFor(context),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.borderFor(context),
                            ),
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
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(
                                    alpha: AppColors.isDark(context)
                                        ? 0.18
                                        : 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.flag_rounded,
                                  color: AppColors.warning,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Report an overpriced item',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            color: AppColors.textPrimaryFor(
                                              context,
                                            ),
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Tell us the product, store, observed price, and details. Reports are saved as pending for review.',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondaryFor(
                                              context,
                                            ),
                                            height: 1.45,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _ReportPreviewCard(
                          commodity: selectedCommodity,
                          store: selectedStore,
                          observedPrice: observedPrice,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _StepCard(
                          icon: Icons.inventory_2_outlined,
                          step: 'Required',
                          title: 'What item and store are you reporting?',
                          subtitle:
                              'Pick the exact product and the store where you saw the price.',
                          child: Column(
                            children: [
                              if (widget.preselectedStoreId != null) ...[
                                AppSurfaceCard(
                                  padding: const EdgeInsets.all(16),
                                  radius: 20,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.08),
                                      AppColors.surfaceFor(context),
                                    ],
                                  ),
                                  borderColor: AppColors.primary.withValues(
                                    alpha: 0.16,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.qr_code_scanner_rounded,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Store selected from QR scan',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'You can still change the store below before saving the report.',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        AppColors.textSecondaryFor(
                                                          context,
                                                        ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              DropdownButtonFormField<int>(
                                initialValue: _commodityId,
                                decoration: const InputDecoration(
                                  labelText: 'Commodity',
                                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                                ),
                                items: _commodities
                                    .map(
                                      (item) => DropdownMenuItem<int>(
                                        value: item.id,
                                        child: Text(item.name),
                                      ),
                                    )
                                    .toList(),
                                validator: (value) => value == null
                                    ? 'Commodity is required.'
                                    : null,
                                onChanged: (value) => setState(() {
                                  _commodityId = value;
                                }),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              DropdownButtonFormField<int>(
                                initialValue: _storeId,
                                decoration: const InputDecoration(
                                  labelText: 'Store',
                                  prefixIcon: Icon(Icons.storefront_outlined),
                                ),
                                items: _stores
                                    .map(
                                      (item) => DropdownMenuItem<int>(
                                        value: item.id,
                                        child: Text(item.name),
                                      ),
                                    )
                                    .toList(),
                                validator: (value) =>
                                    value == null ? 'Store is required.' : null,
                                onChanged: (value) => setState(() {
                                  _storeId = value;
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _StepCard(
                          icon: Icons.price_change_outlined,
                          step: 'Required',
                          title: 'Price and details',
                          subtitle:
                              'Enter the selling price you saw and describe why it needs review.',
                          child: Column(
                            children: [
                              AppTextField(
                                controller: _observedPriceController,
                                label: 'Observed price',
                                hint: 'Enter the actual selling price',
                                prefixText: '₱',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (value) => Validators.price(
                                  value,
                                  label: 'Observed price',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppSurfaceCard(
                                padding: const EdgeInsets.all(16),
                                radius: 20,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.warning.withValues(alpha: 0.10),
                                    AppColors.surfaceFor(context),
                                  ],
                                ),
                                borderColor: AppColors.warning.withValues(
                                  alpha: 0.16,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withValues(
                                          alpha: 0.14,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.tips_and_updates_outlined,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Include the pack size, brand, quantity, or anything that explains why the observed price should be reviewed.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondaryFor(
                                                context,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(
                                controller: _reasonController,
                                label: 'Report details',
                                hint:
                                    'Describe the incident, packaging, quantity, or pricing concern',
                                prefixIcon: Icons.edit_note_rounded,
                                maxLines: 5,
                                validator: (value) => Validators.requiredField(
                                  value,
                                  label: 'Reason',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _StepCard(
                          icon: Icons.photo_camera_back_outlined,
                          step: 'Optional',
                          title: 'Proof or photo reference',
                          subtitle:
                              'Add a photo path when you have one. You can submit without it.',
                          child: Column(
                            children: [
                              AppTextField(
                                controller: _photoPathController,
                                label: 'Optional photo path',
                                hint: 'storage/reports/sample.jpg',
                                prefixIcon: Icons.photo_camera_back_outlined,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppSurfaceCard(
                                padding: const EdgeInsets.all(16),
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.surfaceMutedFor(context),
                                    AppColors.surfaceFor(context),
                                  ],
                                ),
                                borderColor: AppColors.warning.withValues(
                                  alpha: 0.18,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.upload_file_rounded,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Camera integration is optional in this build, but you can still store a local image path for demo reporting.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondaryFor(
                                                context,
                                              ),
                                              height: 1.4,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (reportController.error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            reportController.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        AppSurfaceCard(
                          radius: 20,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxWidth < 430;
                              final note = Text(
                                'Review your details before submitting. Reports cannot be edited after save.',
                                textAlign: compact
                                    ? TextAlign.center
                                    : TextAlign.start,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondaryFor(context),
                                  height: 1.35,
                                ),
                              );
                              final button = SizedBox(
                                width: compact ? double.infinity : 220,
                                child: AppPrimaryButton(
                                  label: 'Submit report',
                                  icon: Icons.flag_rounded,
                                  isLoading: reportController.isLoading,
                                  onPressed: reportController.isLoading
                                      ? null
                                      : _submit,
                                ),
                              );

                              if (compact) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    note,
                                    const SizedBox(height: AppSpacing.md),
                                    button,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: note),
                                  const SizedBox(width: AppSpacing.md),
                                  button,
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _loadOptions() async {
    final commodityRepository = context.read<CommodityRepository>();
    final storeRepository = context.read<StoreRepository>();
    final commodities = await commodityRepository.getAllCommodities();
    final stores = await storeRepository.getAllStores();
    if (!mounted) {
      return;
    }
    setState(() {
      _commodities = commodities;
      _stores = stores;
      _commodityId =
          widget.preselectedCommodityId ??
          (commodities.isNotEmpty ? commodities.first.id : null);
      _storeId =
          widget.preselectedStoreId ??
          (stores.isNotEmpty ? stores.first.id : null);
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId = context.read<AuthController>().currentUser?.id;
    final commodityId = _commodityId;
    final storeId = _storeId;
    if (userId == null || commodityId == null || storeId == null) {
      return;
    }
    final commodity = _commodities.cast<CommodityModel?>().firstWhere(
      (item) => item?.id == commodityId,
      orElse: () => null,
    );
    if (commodity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected commodity is no longer available.'),
        ),
      );
      return;
    }

    final success = await context.read<ReportController>().submitReport(
      userId: userId,
      commodityId: commodityId,
      storeId: storeId,
      observedPrice: double.parse(_observedPriceController.text.trim()),
      srpSnapshot: commodity.srp,
      reason: _reasonController.text,
      photoPath: _photoPathController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully.')),
      );
      context.go('/reports');
    }
  }

  CommodityModel? get _selectedCommodity {
    final commodityId = _commodityId;
    if (commodityId == null) {
      return null;
    }
    return _commodities.cast<CommodityModel?>().firstWhere(
      (item) => item?.id == commodityId,
      orElse: () => null,
    );
  }

  StoreModel? get _selectedStore {
    final storeId = _storeId;
    if (storeId == null) {
      return null;
    }
    return _stores.cast<StoreModel?>().firstWhere(
      (item) => item?.id == storeId,
      orElse: () => null,
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String step;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      (AppColors.isDark(context)
                              ? AppColors.darkPrimarySoft
                              : AppColors.primary)
                          .withValues(
                            alpha: AppColors.isDark(context) ? 0.18 : 0.10,
                          ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.isDark(context)
                      ? AppColors.darkPrimarySoft
                      : AppColors.primaryDark,
                  size: 21,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.isDark(context)
                            ? AppColors.darkPrimarySoft
                            : AppColors.primaryDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimaryFor(context),
                        fontWeight: FontWeight.w900,
                      ),
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
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _ReportPreviewCard extends StatelessWidget {
  const _ReportPreviewCard({
    required this.commodity,
    required this.store,
    required this.observedPrice,
  });

  final CommodityModel? commodity;
  final StoreModel? store;
  final double? observedPrice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final srp = commodity?.srp;
    final srpValue = srp;
    final difference = srpValue == null || observedPrice == null
        ? null
        : observedPrice! - srpValue;
    final percentage = difference == null || srpValue == null || srpValue == 0
        ? null
        : (difference / srpValue) * 100;
    final isAbove = (difference ?? 0) > 0;
    final accent = isAbove
        ? AppColors.warning
        : (AppColors.isDark(context)
              ? AppColors.darkPrimarySoft
              : AppColors.primaryDark);

    return AppSurfaceCard(
      radius: 20,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final details = [
            _PreviewTile(
              label: 'Commodity',
              value: commodity?.name ?? 'Select product',
              icon: Icons.inventory_2_outlined,
            ),
            _PreviewTile(
              label: 'Store',
              value: store?.name ?? 'Select store',
              icon: Icons.storefront_outlined,
            ),
            _PreviewTile(
              label: 'SRP',
              value: srp == null ? 'Waiting' : AppFormatters.currency(srp),
              icon: Icons.sell_outlined,
            ),
          ];

          final variance = Container(
            width: compact ? double.infinity : 240,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: accent.withValues(
                alpha: AppColors.isDark(context) ? 0.18 : 0.08,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price check',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textPrimaryFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  observedPrice == null
                      ? 'Enter observed price'
                      : AppFormatters.currency(observedPrice!),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimaryFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  percentage == null
                      ? 'SRP check appears here'
                      : '${percentage.abs().toStringAsFixed(1)}% ${isAbove ? 'above' : 'below'} SRP',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: details,
                ),
                const SizedBox(height: AppSpacing.md),
                variance,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: details,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              variance,
            ],
          );
        },
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.isDark(context)
                ? AppColors.darkPrimarySoft
                : AppColors.primaryDark,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimaryFor(context),
                    fontWeight: FontWeight.w800,
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
