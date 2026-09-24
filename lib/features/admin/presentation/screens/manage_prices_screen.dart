import 'package:flutter/material.dart';
import '../../../../shared/widgets/pricewatch_help.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/models/ui_models.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../controllers/admin_controller.dart';
import '../../data/csv_file_picker.dart';
import '../../data/csv_import_service.dart';
import '../../data/admin_export_service.dart';
import '../widgets/admin_page_frame.dart';
import '../widgets/admin_workspace_widgets.dart';
import '../widgets/csv_import_preview_dialog.dart';

class ManagePricesScreen extends StatefulWidget {
  const ManagePricesScreen({super.key});

  @override
  State<ManagePricesScreen> createState() => _ManagePricesScreenState();
}

class _ManagePricesScreenState extends State<ManagePricesScreen> {
  final _searchController = TextEditingController();
  String _complianceFilter = 'all';

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
      await controller.loadCommodities();
      await controller.loadStores();
      await controller.loadPriceEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();
    final webLayout = useAdminWebLayout(context);
    final query = _searchController.text.trim().toLowerCase();
    final visibleEntries = controller.priceEntries.where((entry) {
      final matchesQuery =
          query.isEmpty ||
          entry.commodityName.toLowerCase().contains(query) ||
          entry.storeName.toLowerCase().contains(query) ||
          entry.source.toLowerCase().contains(query);
      final matchesCompliance =
          _complianceFilter == 'all' ||
          (_complianceFilter == 'above' && entry.variance > 0) ||
          (_complianceFilter == 'within' && entry.variance <= 0);
      return matchesQuery && matchesCompliance;
    }).toList();

    return Scaffold(
      appBar: webLayout
          ? null
          : AppBar(
              title: const Text('Manage Prices'),
              actions: [
                IconButton(
                  tooltip: 'Upload price CSV',
                  onPressed: controller.isLoading ? null : _uploadPriceCsv,
                  icon: const Icon(Icons.upload_file_rounded),
                ),
              ],
            ),
      body: AppBackground(
        showTopGlow: false,
        child: controller.commodities.isEmpty || controller.stores.isEmpty
            ? const AdminPageFrame(
                maxWidth: 1320,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  child: EmptyStateView(
                    title: 'Setup required',
                    message:
                        'Add at least one commodity and one store before creating price entries.',
                    icon: Icons.price_change_outlined,
                  ),
                ),
              )
            : AdminPageFrame(
                maxWidth: 1320,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PriceWatchHelp(),

                      AdminPageHeader(
                        eyebrow: 'Price operations',
                        title: 'Price list management',
                        subtitle:
                            'Import, review, and export synchronized commodity price records.',
                        icon: Icons.price_change_rounded,
                        webActionAtTop: true,
                        action: Align(
                          alignment: webLayout
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: SizedBox(
                            width: webLayout ? 230 : double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: controller.isLoading
                                      ? null
                                      : _uploadPriceCsv,
                                  icon: const Icon(Icons.upload_file_rounded),
                                  label: const Text('Upload price CSV'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.white60,
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.72,
                                      ),
                                    ),
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.06,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                PopupMenuButton<String>(
                                  tooltip: 'Export price register',
                                  onSelected: _exportPrices,
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'pdf',
                                      child: Text('Export PDF'),
                                    ),
                                    PopupMenuItem(
                                      value: 'xlsx',
                                      child: Text('Export Excel'),
                                    ),
                                  ],
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryDark,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.download_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 7),
                                        Text(
                                          'Export',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        metrics: [
                          AdminHeaderMetric(
                            label: 'Commodities',
                            value: '${controller.commodities.length}',
                            icon: Icons.inventory_2_outlined,
                            accent: AppColors.primaryDark,
                          ),
                          AdminHeaderMetric(
                            label: 'Stores',
                            value: '${controller.stores.length}',
                            icon: Icons.storefront_outlined,
                            accent: AppColors.sky,
                          ),
                          AdminHeaderMetric(
                            label: 'Price records',
                            value: '${controller.priceEntries.length}',
                            icon: Icons.receipt_long_outlined,
                            accent: AppColors.warning,
                          ),
                        ],
                      ),
                      if (controller.error != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        AdminErrorBanner(message: controller.error!),
                      ],
                      if (controller.importProgress != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _ImportProgressCard(
                          progress: controller.importProgress!,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      AdminSectionCard(
                        title: 'Price list register',
                        subtitle:
                            'Complete product price history with store, SRP compliance, source, and date-added details.',
                        action: OutlinedButton.icon(
                          onPressed: () => context
                              .read<AdminController>()
                              .loadPriceEntries(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Refresh'),
                        ),
                        child: Column(
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final search = TextField(
                                  controller: _searchController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.search_rounded),
                                    hintText:
                                        'Search product, store, or source',
                                  ),
                                );
                                final filter = DropdownButtonFormField<String>(
                                  initialValue: _complianceFilter,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.filter_alt_outlined),
                                    labelText: 'Compliance',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'all',
                                      child: Text('All records'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'above',
                                      child: Text('Above SRP'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'within',
                                      child: Text('Within SRP'),
                                    ),
                                  ],
                                  onChanged: (value) => setState(
                                    () => _complianceFilter = value ?? 'all',
                                  ),
                                );
                                if (constraints.maxWidth < 720) {
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
                            if (visibleEntries.isEmpty)
                              const EmptyStateView(
                                title: 'No matching price records',
                                message:
                                    'Adjust the search or compliance filter.',
                                icon: Icons.search_off_rounded,
                              )
                            else
                              _RecentPricesTable(
                                entries: visibleEntries,
                                onDelete: _confirmDeletePrice,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AdminSectionCard(
                        title: 'What happens after save',
                        subtitle:
                            'Each entry updates downstream parts of the app automatically.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _WorkflowStep(
                              icon: Icons.notifications_active_outlined,
                              title: 'Watchlists get checked',
                              body:
                                  'Users tracking the commodity can receive local alert records when thresholds are exceeded.',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const _WorkflowStep(
                              icon: Icons.inventory_2_rounded,
                              title: 'Commodity details update',
                              body:
                                  'The latest price becomes available in commodity detail views and market records.',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const _WorkflowStep(
                              icon: Icons.query_stats_rounded,
                              title: 'Analytics stay current',
                              body:
                                  'Category averages and operational summaries are recalculated from the latest data.',
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppSurfaceCard(
                              radius: 30,
                              gradient: AppColors.isDark(context)
                                  ? AppColors.surfaceGradientFor(context)
                                  : const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFFF1F7),
                                        Color(0xFFFFFFFF),
                                      ],
                                    ),
                              borderColor: AppColors.primary.withValues(
                                alpha: 0.20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Coverage snapshot',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  const _CoverageRow(
                                    label: 'Mode',
                                    value: 'Offline-first',
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  _CoverageRow(
                                    label: 'Available commodities',
                                    value: '${controller.commodities.length}',
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  _CoverageRow(
                                    label: 'Available stores',
                                    value: '${controller.stores.length}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _confirmDeletePrice(AdminPriceEntryView entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete price record'),
        content: Text(
          'Delete ${entry.commodityName} at ${entry.storeName} from ${AppFormatters.dateTime(entry.recordedAt)}?',
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
    await context.read<AdminController>().deletePriceEntry(entry.id);
  }

  Future<void> _uploadPriceCsv() async {
    try {
      final bytes = await CsvFilePicker.pickBytes();
      if (!mounted) return;
      if (bytes == null) return;
      if (bytes.isEmpty) {
        throw const FormatException('The selected CSV file is empty.');
      }
      final rows = CsvImportService.parse(bytes);
      final decision = await showCsvImportPreview(
        context: context,
        title: 'Preview price CSV',
        rows: rows,
      );
      if (decision == null || !mounted) return;
      final result = await context.read<AdminController>().importPriceRows(
        rows,
        strategy: decision.strategy,
      );
      if (!mounted) return;
      await _showImportResult(
        title: 'Price import complete',
        result: result,
        format: 'Commodity, PriceList, StoreName',
      );
    } catch (error) {
      if (mounted) {
        _showImportMessage(
          error.toString().replaceFirst('FormatException: ', ''),
        );
      }
    }
  }

  Future<void> _exportPrices(String format) async {
    final entries = context.read<AdminController>().priceEntries;
    const headers = [
      'Price ID',
      'Product',
      'Unit',
      'Store',
      'Market Price',
      'SRP',
      'Variance',
      'Compliance',
      'Source',
      'Date Added',
    ];
    final rows = entries
        .map(
          (entry) => <Object?>[
            entry.id,
            entry.commodityName,
            entry.unit,
            entry.storeName,
            entry.price,
            entry.srp,
            entry.variance,
            entry.variance > 0 ? 'Above SRP' : 'Within SRP',
            entry.source,
            entry.recordedAt,
          ],
        )
        .toList();
    if (format == 'pdf') {
      await AdminExportService.savePdf(
        title: 'PriceWatch Price List Register',
        filePrefix: 'pricewatch_prices',
        headers: headers,
        rows: rows,
      );
    } else {
      await AdminExportService.saveXlsx(
        sheetName: 'Prices',
        filePrefix: 'pricewatch_prices',
        headers: headers,
        rows: rows,
      );
    }
  }

  void _showImportMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showImportResult({
    required String title,
    required CsvImportResult result,
    required String format,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.summary),
                const SizedBox(height: 8),
                Text('Expected columns: $format'),
                if (result.errors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Skipped rows',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...result.errors.take(20).map(Text.new),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (result.errors.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => CsvImportService.saveErrorReport(
                result.errors,
                filePrefix: 'price_import',
              ),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download errors'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _ImportProgressCard extends StatelessWidget {
  const _ImportProgressCard({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'Importing price records',
      subtitle: '${(progress * 100).round()}% complete',
      child: LinearProgressIndicator(value: progress),
    );
  }
}

class _RecentPricesTable extends StatelessWidget {
  const _RecentPricesTable({required this.entries, required this.onDelete});
  final List<AdminPriceEntryView> entries;
  final ValueChanged<AdminPriceEntryView> onDelete;

  @override
  Widget build(BuildContext context) => AdminDataTableCard(
    minWidth: 1440,
    fontScale: 0.9,
    columns: const [
      'Price ID',
      'Product',
      'Store',
      'Market price',
      'SRP',
      'Variance',
      'Compliance',
      'Source',
      'Date added',
      'Actions',
    ],
    rows: entries.map((entry) {
      final color = entry.variance > 0
          ? AppColors.warning
          : AppColors.primaryDark;
      final isAboveSrp = entry.variance > 0;
      return DataRow(
        cells: [
          DataCell(
            Text(
              'PW-${entry.id}',
              style: TextStyle(
                color: AppColors.textSecondaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          DataCell(
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.commodityName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  entry.unit,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ],
            ),
          ),
          DataCell(
            Text(entry.storeName, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          DataCell(
            Text(
              AppFormatters.currency(entry.price),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          DataCell(Text(AppFormatters.currency(entry.srp))),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                AppFormatters.signedCurrency(entry.variance),
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: (isAboveSrp ? AppColors.warning : AppColors.success)
                    .withValues(alpha: .10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAboveSrp
                        ? Icons.arrow_upward_rounded
                        : Icons.verified_outlined,
                    size: 14,
                    color: isAboveSrp
                        ? AppColors.warningText
                        : AppColors.success,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isAboveSrp ? 'Above SRP' : 'Within SRP',
                    style: TextStyle(
                      color: isAboveSrp
                          ? AppColors.warningText
                          : AppColors.success,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          DataCell(
            Text(
              entry.source.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          DataCell(Text(AppFormatters.dateTime(entry.recordedAt), maxLines: 1)),
          DataCell(
            IconButton(
              onPressed: () => onDelete(entry),
              tooltip: 'Delete price record',
              color: AppColors.danger,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ),
        ],
      );
    }).toList(),
  );
}

class _WorkflowStep extends StatelessWidget {
  const _WorkflowStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundAltFor(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppColors.isDark(context)
                  ? AppColors.darkPrimarySoft
                  : AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                    height: 1.45,
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

class _CoverageRow extends StatelessWidget {
  const _CoverageRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
