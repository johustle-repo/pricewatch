import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/utils/store_qr_codec.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/store_model.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../../../vendor/presentation/screens/vendor_store_qr_screen.dart';
import '../controllers/admin_controller.dart';
import '../../data/csv_file_picker.dart';
import '../../data/csv_import_service.dart';
import '../../data/admin_export_service.dart';
import '../widgets/admin_page_frame.dart';
import '../widgets/admin_workspace_widgets.dart';
import '../widgets/csv_import_preview_dialog.dart';

class ManageStoresScreen extends StatefulWidget {
  const ManageStoresScreen({super.key});

  @override
  State<ManageStoresScreen> createState() => _ManageStoresScreenState();
}

class _ManageStoresScreenState extends State<ManageStoresScreen> {
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
      await controller.loadStores();
      await controller.loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();
    final webLayout = useAdminWebLayout(context);
    final query = _searchController.text.trim().toLowerCase();
    final visibleStores = controller.stores.where((store) {
      return query.isEmpty ||
          store.name.toLowerCase().contains(query) ||
          (store.ownerName ?? '').toLowerCase().contains(query) ||
          (store.marketName ?? '').toLowerCase().contains(query) ||
          store.address.toLowerCase().contains(query) ||
          (store.city ?? '').toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: webLayout
          ? null
          : AppBar(
              title: const Text('Manage Stores'),
              actions: [
                IconButton(
                  tooltip: 'Upload stores CSV',
                  onPressed: controller.isLoading ? null : _uploadStoresCsv,
                  icon: const Icon(Icons.upload_file_rounded),
                ),
              ],
            ),
      floatingActionButton: webLayout
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openStoreDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            ),
      body: AppBackground(
        showTopGlow: false,
        child: controller.isLoading && controller.stores.isEmpty
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
                      title: 'Stores',
                      subtitle:
                          'Verify legitimate sellers in Lingayen Municipal Market, maintain one shop record per vendor, and show each shop QR code for buyer reports.',
                      icon: Icons.storefront_rounded,
                      webActionAtTop: true,
                      action: webLayout
                          ? SizedBox(
                              width: 280,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: controller.isLoading
                                        ? null
                                        : _showArchivedStores,
                                    icon: const Icon(
                                      Icons.inventory_2_outlined,
                                    ),
                                    label: Text(
                                      'Archived (${controller.archivedStores.length})',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: controller.isLoading
                                              ? null
                                              : _uploadStoresCsv,
                                          icon: const Icon(
                                            Icons.upload_file_rounded,
                                            size: 18,
                                          ),
                                          label: const Text('Upload CSV'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            disabledForegroundColor:
                                                Colors.white60,
                                            side: BorderSide(
                                              color: Colors.white.withValues(
                                                alpha: 0.72,
                                              ),
                                            ),
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.06),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: PopupMenuButton<String>(
                                          tooltip: 'Export stores',
                                          onSelected: _exportStores,
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
                                            height: 46,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryDark,
                                              borderRadius:
                                                  BorderRadius.circular(14),
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
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  FilledButton.icon(
                                    onPressed: () => _openStoreDialog(),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Add store'),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                    if (controller.error != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      AdminErrorBanner(message: controller.error!),
                    ],
                    if (controller.importProgress != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      AdminSectionCard(
                        title: 'Importing stores',
                        subtitle:
                            '${(controller.importProgress! * 100).round()}% complete',
                        child: LinearProgressIndicator(
                          value: controller.importProgress,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText:
                            'Search store, owner, market, address, or city',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    visibleStores.isEmpty
                        ? const AppSurfaceCard(
                            radius: 28,
                            child: EmptyStateView(
                              title: 'No verified shops yet',
                              message:
                                  'Add a legitimate Lingayen Municipal Market shop before creating a vendor account for it.',
                              icon: Icons.storefront_outlined,
                            ),
                          )
                        : webLayout
                        ? _StoresTable(
                            stores: visibleStores,
                            onEdit: (store) => _openStoreDialog(store: store),
                            onShowQr: _showStoreQr,
                            onArchive: _archiveStore,
                            onDelete: _confirmDeleteStore,
                          )
                        : AppSurfaceCard(
                            radius: 28,
                            child: Column(
                              children: [
                                for (
                                  var i = 0;
                                  i < controller.stores.length;
                                  i++
                                ) ...[
                                  _StoreRow(
                                    item: controller.stores[i],
                                    onEdit: () => _openStoreDialog(
                                      store: controller.stores[i],
                                    ),
                                    onShowQr: () =>
                                        _showStoreQr(controller.stores[i]),
                                    onDelete: () => _confirmDeleteStore(
                                      controller.stores[i],
                                    ),
                                  ),
                                  if (i != controller.stores.length - 1)
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

  Future<void> _uploadStoresCsv() async {
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
        title: 'Preview stores CSV',
        rows: rows,
      );
      if (decision == null || !mounted) return;
      final result = await context.read<AdminController>().importStoreRows(
        rows,
        strategy: decision.strategy,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Store import complete'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.summary),
                  const SizedBox(height: 8),
                  const Text(
                    'Expected columns: StoreName, OwnerName, MarketName, Address, City',
                  ),
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
                  filePrefix: 'store_import',
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
    } catch (error) {
      if (mounted) {
        _showImportMessage(
          error.toString().replaceFirst('FormatException: ', ''),
        );
      }
    }
  }

  Future<void> _exportStores(String format) async {
    final stores = context.read<AdminController>().stores;
    final headers = [
      'Store ID',
      'Store Name',
      'Owner',
      'Market',
      'Address',
      'City',
      'Date Added',
    ];
    final rows = stores
        .map(
          (store) => <Object?>[
            store.id,
            store.name,
            store.ownerName ?? '',
            store.marketName ?? '',
            store.address,
            store.city ?? '',
            store.createdAt,
          ],
        )
        .toList();
    if (format == 'pdf') {
      await AdminExportService.savePdf(
        title: 'PriceWatch Store Register',
        filePrefix: 'pricewatch_stores',
        headers: headers,
        rows: rows,
      );
    } else {
      await AdminExportService.saveXlsx(
        sheetName: 'Stores',
        filePrefix: 'pricewatch_stores',
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

  Future<void> _confirmDeleteStore(StoreModel store) async {
    if (store.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete store'),
        content: Text(
          'Delete ${store.name}? Its price history and reports will also be permanently deleted. Linked vendor accounts will remain, but their store assignment will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete store'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<AdminController>().deleteStore(store.id!);
    if (!mounted) return;
    final error = context.read<AdminController>().error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? '${store.name} was deleted.'),
        backgroundColor: error == null ? null : AppColors.danger,
      ),
    );
  }

  Future<void> _archiveStore(StoreModel store) async {
    if (store.id == null) return;
    await context.read<AdminController>().archiveStore(store.id!);
    if (!mounted) return;
    final error = context.read<AdminController>().error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? '${store.name} was archived.')),
    );
  }

  Future<void> _showArchivedStores() async {
    final controller = context.read<AdminController>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archived stores'),
        content: SizedBox(
          width: 560,
          child: controller.archivedStores.isEmpty
              ? const Text('There are no archived stores.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: controller.archivedStores.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, index) {
                    final store = controller.archivedStores[index];
                    return ListTile(
                      leading: const Icon(Icons.storefront_outlined),
                      title: Text(store.name),
                      subtitle: Text(store.ownerName ?? 'No assigned owner'),
                      trailing: TextButton.icon(
                        onPressed: () async {
                          await controller.restoreStore(store.id!);
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                        icon: const Icon(Icons.restore_rounded),
                        label: const Text('Restore'),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openStoreDialog({StoreModel? store}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: store?.name ?? '');
    final vendors = context
        .read<AdminController>()
        .users
        .where((user) => user.isVendor && user.id != null)
        .toList();
    final currentOwner = (store?.ownerName ?? '').trim().toLowerCase();
    var selectedVendorId = store?.ownerUserId ?? -1;
    for (final vendor in vendors) {
      if (selectedVendorId != -1) break;
      if (vendor.fullName.trim().toLowerCase() == currentOwner) {
        selectedVendorId = vendor.id!;
        break;
      }
    }
    final marketController = TextEditingController(
      text: store?.marketName ?? '',
    );
    final addressController = TextEditingController(text: store?.address ?? '');
    final cityController = TextEditingController(text: store?.city ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(store == null ? 'Add store' : 'Edit store'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Store name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Name is required.'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedVendorId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Owner / vendor account',
                    helperText: vendors.isEmpty
                        ? 'Create a user with the Vendor role first.'
                        : 'Only users with the Vendor role are listed.',
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: -1,
                      child: Text('No owner selected'),
                    ),
                    for (final vendor in vendors)
                      DropdownMenuItem<int>(
                        value: vendor.id!,
                        child: Text(
                          '${vendor.fullName}  •  VENDOR  •  ${vendor.email}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: vendors.isEmpty
                      ? null
                      : (value) => selectedVendorId = value ?? -1,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: marketController,
                  decoration: const InputDecoration(labelText: 'Market name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Address is required.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'City'),
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
              await context.read<AdminController>().saveStore(
                id: store?.id,
                name: nameController.text,
                ownerName: selectedVendorId == -1
                    ? ''
                    : vendors
                          .firstWhere((vendor) => vendor.id == selectedVendorId)
                          .fullName,
                ownerUserId: selectedVendorId == -1 ? null : selectedVendorId,
                marketName: marketController.text,
                address: addressController.text,
                city: cityController.text,
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

  Future<void> _showStoreQr(StoreModel store) async {
    final qrData = _qrDataFor(store);
    final exportKey = GlobalKey();
    await showDialog<void>(
      context: context,
      builder: (context) {
        final screenSize = MediaQuery.sizeOf(context);
        final dialogWidth = math.min(screenSize.width - 32, 600.0);
        final cardWidth = math.min(dialogWidth - 40, 440.0);
        final maxDialogHeight = math.min(screenSize.height * 0.92, 840.0);

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
                      if (qrData == null)
                        Container(
                          width: cardWidth,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMutedFor(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.borderFor(context),
                            ),
                          ),
                          child: Text(
                            'This store does not have enough information to generate a QR code yet.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      else
                        Center(
                          child: SizedBox(
                            width: cardWidth,
                            child: RepaintBoundary(
                              key: exportKey,
                              child: AspectRatio(
                                aspectRatio: 210 / 297,
                                child: StoreQrA4Poster(
                                  store: store,
                                  qrData: qrData,
                                ),
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
                          if (qrData != null) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () =>
                                    _downloadQrCard(exportKey, store),
                                icon: const Icon(Icons.download_rounded),
                                label: const Text('Download'),
                              ),
                            ),
                          ],
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

  String? _qrDataFor(StoreModel store) {
    // Match the vendor workspace: a persisted store always uses the canonical
    // current store payload, even when an older qrCode value is still stored.
    if (store.id != null) {
      return StoreQrCodec.encode(store);
    }
    final stored = store.qrCode?.trim();
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    return null;
  }

  Future<void> _downloadQrCard(GlobalKey key, StoreModel store) async {
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

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Store QR card downloaded.')));
  }
}

class _StoresTable extends StatelessWidget {
  const _StoresTable({
    required this.stores,
    required this.onEdit,
    required this.onShowQr,
    required this.onArchive,
    required this.onDelete,
  });

  final List<StoreModel> stores;
  final ValueChanged<StoreModel> onEdit;
  final ValueChanged<StoreModel> onShowQr;
  final ValueChanged<StoreModel> onArchive;
  final ValueChanged<StoreModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return AdminDataTableCard(
      minWidth: 1280,
      fontScale: 0.9,
      columns: const [
        'Store',
        'Owner',
        'Market',
        'Address',
        'City',
        'Date added',
        'Actions',
      ],
      rows: [
        for (var index = 0; index < stores.length; index++)
          DataRow(
            color: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return AppColors.primary.withValues(alpha: 0.06);
              }
              return index.isOdd
                  ? AppColors.surfaceMutedFor(context).withValues(alpha: 0.42)
                  : Colors.transparent;
            }),
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
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        stores[index].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _scaledStyle(
                          context,
                          Theme.of(context).textTheme.titleSmall,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text(_ownerName(stores[index]))),
              DataCell(Text(_marketName(stores[index]))),
              DataCell(
                Text(
                  stores[index].address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DataCell(
                Text(
                  (stores[index].city ?? '').trim().isEmpty
                      ? '-'
                      : stores[index].city!,
                ),
              ),
              DataCell(
                Text(
                  _dateAdded(stores[index].createdAt),
                  style: TextStyle(
                    color: AppColors.textSecondaryFor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => onArchive(stores[index]),
                      tooltip: 'Archive store',
                      icon: const Icon(Icons.inventory_2_outlined),
                    ),
                    IconButton(
                      onPressed: () => onShowQr(stores[index]),
                      tooltip: 'Show store QR',
                      icon: const Icon(Icons.qr_code_2_rounded),
                    ),
                    IconButton(
                      onPressed: () => onEdit(stores[index]),
                      tooltip: 'Edit store',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () => onDelete(stores[index]),
                      tooltip: 'Delete store',
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

  String _marketName(StoreModel store) {
    final value = (store.marketName ?? '').trim();
    return value.isEmpty ? 'Local market' : value;
  }

  String _ownerName(StoreModel store) {
    final value = (store.ownerName ?? '').trim();
    return value.isEmpty ? 'Not specified' : value;
  }

  String _dateAdded(String iso) {
    try {
      return AppFormatters.date(iso);
    } catch (_) {
      return iso.trim().isEmpty ? '-' : iso;
    }
  }

  TextStyle? _scaledStyle(
    BuildContext context,
    TextStyle? style, {
    FontWeight? weight,
  }) {
    return style?.copyWith(
      fontSize: (style.fontSize ?? 14) * 0.9,
      fontWeight: weight,
      color: AppColors.textPrimaryFor(context),
    );
  }
}

// Kept temporarily for backward-compatible previews created by older routes.
// ignore: unused_element
class _StoreQrExportCard extends StatelessWidget {
  const _StoreQrExportCard({required this.store, required this.qrData});

  final StoreModel store;
  final String qrData;

  @override
  Widget build(BuildContext context) {
    final market = (store.marketName ?? '').trim().isEmpty
        ? 'Local market'
        : store.marketName!.trim();
    final owner = (store.ownerName ?? '').trim().isEmpty
        ? 'Not assigned'
        : store.ownerName!.trim();
    final city = (store.city ?? '').trim();
    final location = city.isEmpty ? store.address : '${store.address}, $city';
    final registered = _safeRegisteredDate(store.createdAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7F0),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 13,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'VERIFIED STORE',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
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
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Owner: $owner',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                errorStateBuilder: (context, error) {
                  return Center(
                    child: Text(
                      'QR preview unavailable',
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
              children: [
                _QrDetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Registered owner',
                  value: owner,
                ),
                const Divider(height: 18),
                _QrDetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Store location',
                  value: location,
                ),
                const Divider(height: 18),
                _QrDetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date registered',
                  value: registered,
                ),
                const Divider(height: 18),
                _QrDetailRow(
                  icon: Icons.tag_rounded,
                  label: 'Store reference',
                  value: store.id == null ? 'Pending' : 'PW-${store.id}',
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

class _QrDetailRow extends StatelessWidget {
  const _QrDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({
    required this.item,
    required this.onEdit,
    required this.onShowQr,
    required this.onDelete,
  });

  final StoreModel item;
  final VoidCallback onEdit;
  final VoidCallback onShowQr;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final marketName = (item.marketName ?? '').trim().isEmpty
        ? 'Local market'
        : item.marketName!.trim();
    final cityName = (item.city ?? '').trim();
    final ownerName = (item.ownerName ?? '').trim();

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
          child: const Icon(
            Icons.storefront_rounded,
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
                marketName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (ownerName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Owner: $ownerName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                cityName.isEmpty ? item.address : '${item.address} | $cityName',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          onPressed: onShowQr,
          tooltip: 'Show store QR',
          icon: const Icon(Icons.qr_code_2_rounded),
        ),
        IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
        IconButton(
          onPressed: onDelete,
          tooltip: 'Delete store',
          color: AppColors.danger,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    );
  }
}
