import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/vendor_incident_model.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_notification_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_shell_menu_button.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/responsive_page.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../../../admin/presentation/widgets/admin_page_frame.dart';
import '../../../admin/presentation/widgets/admin_workspace_widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/vendor_incident_controller.dart';

const _incidentReasons = <String, String>{
  'misrepresentation': 'False identity or misrepresentation',
  'fraud': 'Fraudulent transaction or payment concern',
  'unregistered': 'Unregistered or unauthorized vendor',
  'unsafe_goods': 'Unsafe, counterfeit, or prohibited goods',
  'harassment': 'Harassment or threatening behavior',
  'other': 'Other serious concern',
};

class AddVendorIncidentScreen extends StatefulWidget {
  const AddVendorIncidentScreen({super.key});

  @override
  State<AddVendorIncidentScreen> createState() =>
      _AddVendorIncidentScreenState();
}

class _AddVendorIncidentScreenState extends State<AddVendorIncidentScreen> {
  static const _maxEvidenceBytes = 700 * 1024;
  final _formKey = GlobalKey<FormState>();
  final _vendorNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _detailsController = TextEditingController();
  final _picker = ImagePicker();
  final List<_EvidenceImage> _evidence = [];
  String _reasonCode = 'misrepresentation';
  bool _isPickingEvidence = false;

  @override
  void dispose() {
    _vendorNameController.dispose();
    _locationController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VendorIncidentController>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWeb = screenWidth >= 1024;
    return Scaffold(
      appBar: isWeb
          ? null
          : AppBar(
              leading: const AppShellMenuButton(),
              title: const Text('Report Vendor Incident'),
              actions: const [AppNotificationButton(), SizedBox(width: 8)],
            ),
      body: AppBackground(
        showTopGlow: false,
        child: ListView(
          primary: true,
          padding: EdgeInsets.fromLTRB(
            screenWidth < 720 ? AppSpacing.md : AppSpacing.lg,
            AppSpacing.lg,
            screenWidth < 720 ? AppSpacing.md : AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1050),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _IncidentHero(
                        onViewReports: () =>
                            _goAfterPointerEvent(context, '/incidents'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppSurfaceCard(
                        radius: 22,
                        padding: EdgeInsets.all(screenWidth < 600 ? 18 : 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Incident information',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Only submit factual information. Your identity is visible to authorized administrators, not to the reported vendor.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondaryFor(context),
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth < 720) {
                                  return Column(
                                    children: [
                                      _vendorIdentityField(),
                                      const SizedBox(height: AppSpacing.md),
                                      _marketLocationField(),
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _vendorIdentityField()),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(child: _marketLocationField()),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            DropdownButtonFormField<String>(
                              initialValue: _reasonCode,
                              isExpanded: true,
                              menuMaxHeight: 360,
                              decoration: const InputDecoration(
                                labelText: 'Reason for reporting',
                                prefixIcon: Icon(Icons.gpp_bad_outlined),
                              ),
                              selectedItemBuilder: (context) => _incidentReasons
                                  .values
                                  .map(
                                    (label) => Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              items: _incidentReasons.entries
                                  .map(
                                    (entry) => DropdownMenuItem(
                                      value: entry.key,
                                      child: Text(
                                        entry.value,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setState(
                                () => _reasonCode = value ?? _reasonCode,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final details = _incidentDetailsField();
                                final evidence = _EvidencePicker(
                                  evidence: _evidence,
                                  isBusy: _isPickingEvidence,
                                  onCamera: _takePhoto,
                                  onGallery: _choosePhotos,
                                  onRemove: (index) =>
                                      setState(() => _evidence.removeAt(index)),
                                );
                                if (constraints.maxWidth < 820) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      details,
                                      const SizedBox(height: AppSpacing.lg),
                                      evidence,
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 6, child: details),
                                    const SizedBox(width: AppSpacing.xl),
                                    Expanded(
                                      flex: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceMutedFor(
                                            context,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: AppColors.borderFor(context),
                                          ),
                                        ),
                                        child: evidence,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            if (controller.error != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withValues(
                                    alpha: .09,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.danger.withValues(
                                      alpha: .3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  controller.error!,
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                            AppPrimaryButton(
                              onPressed: controller.isLoading ? null : _submit,
                              isLoading: controller.isLoading,
                              icon: Icons.shield_outlined,
                              label: 'Submit incident for review',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vendorIdentityField() => TextFormField(
    controller: _vendorNameController,
    decoration: const InputDecoration(
      labelText: 'Unregistered vendor',
      hintText: 'Name, alias, or physical description',
      prefixIcon: Icon(Icons.person_search_outlined),
    ),
    textInputAction: TextInputAction.next,
    validator: (value) => (value ?? '').trim().length < 2
        ? 'Enter a name, alias, or description.'
        : null,
  );

  Widget _marketLocationField() => TextFormField(
    controller: _locationController,
    decoration: const InputDecoration(
      labelText: 'Exact market location',
      hintText: 'Section, row, stall, or landmark',
      prefixIcon: Icon(Icons.location_on_outlined),
    ),
    textInputAction: TextInputAction.next,
    validator: (value) => (value ?? '').trim().length < 5
        ? 'Describe where the vendor can be found.'
        : null,
  );

  Widget _incidentDetailsField() => TextFormField(
    controller: _detailsController,
    minLines: 5,
    maxLines: 8,
    maxLength: 1200,
    decoration: const InputDecoration(
      labelText: 'What happened?',
      hintText:
          'Describe what you observed, when it happened, and any transaction details that can help verification.',
      alignLabelWithHint: true,
    ),
    validator: (value) => (value ?? '').trim().length < 20
        ? 'Provide at least 20 characters of factual detail.'
        : null,
  );

  Future<void> _takePhoto() async {
    if (_isPickingEvidence) return;
    if (_evidence.length >= 3) {
      _showMessage('You can attach up to three evidence photos.');
      return;
    }
    setState(() => _isPickingEvidence = true);
    try {
      final file = await showDialog<XFile>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _CameraCaptureDialog(),
      );
      if (file == null) return;
      await _addEvidenceFiles([file]);
    } catch (_) {
      _showMessage(
        'Camera is unavailable. Allow camera access or choose from gallery.',
      );
    } finally {
      if (mounted) setState(() => _isPickingEvidence = false);
    }
  }

  Future<void> _choosePhotos() async {
    if (_isPickingEvidence) return;
    final remaining = 3 - _evidence.length;
    if (remaining <= 0) {
      _showMessage('You can attach up to three evidence photos.');
      return;
    }
    setState(() => _isPickingEvidence = true);
    try {
      final files = await _picker.pickMultiImage(
        imageQuality: 55,
        maxWidth: 1280,
        maxHeight: 1280,
        limit: remaining,
      );
      if (files.isEmpty) return;
      await _addEvidenceFiles(files);
    } catch (_) {
      _showMessage('The selected gallery image could not be opened.');
    } finally {
      if (mounted) setState(() => _isPickingEvidence = false);
    }
  }

  Future<void> _addEvidenceFiles(List<XFile> files) async {
    var totalBytes = _evidence.fold<int>(
      0,
      (total, item) => total + item.bytes.length,
    );
    final accepted = <_EvidenceImage>[];
    var rejectedForSize = false;

    for (final file in files.take(3 - _evidence.length)) {
      final bytes = await file.readAsBytes();
      if (totalBytes + bytes.length > _maxEvidenceBytes) {
        rejectedForSize = true;
        continue;
      }
      accepted.add(_EvidenceImage(bytes: bytes));
      totalBytes += bytes.length;
    }

    if (!mounted) return;
    if (accepted.isNotEmpty) {
      setState(() => _evidence.addAll(accepted));
    }
    if (rejectedForSize) {
      _showMessage(
        'Some photos were too large. Use fewer or lower-resolution images.',
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_evidence.isEmpty) {
      _showMessage('Attach at least one photo as supporting evidence.');
      return;
    }
    final userId = context.read<AuthController>().currentUser?.id;
    if (userId == null) {
      _showMessage(
        'Your session has expired. Sign in again before submitting.',
      );
      return;
    }
    final success = await context.read<VendorIncidentController>().submit(
      userId: userId,
      reportedVendorName: _vendorNameController.text,
      marketLocation: _locationController.text,
      reasonCode: _reasonCode,
      details: _detailsController.text,
      evidencePhotos: _evidence
          .map((item) => 'data:image/jpeg;base64,${base64Encode(item.bytes)}')
          .toList(),
    );
    if (!mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vendor incident submitted securely.')),
    );
    _goAfterPointerEvent(context, '/incidents');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class VendorIncidentListScreen extends StatefulWidget {
  const VendorIncidentListScreen({super.key, this.adminMode = false});

  final bool adminMode;

  @override
  State<VendorIncidentListScreen> createState() =>
      _VendorIncidentListScreenState();
}

class _VendorIncidentListScreenState extends State<VendorIncidentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final controller = context.read<VendorIncidentController>();
    if (widget.adminMode) {
      await controller.loadAdmin();
    } else {
      final userId = context.read<AuthController>().currentUser?.id;
      if (userId != null) await controller.loadUser(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VendorIncidentController>();
    final content = controller.isLoading && controller.incidents.isEmpty
        ? const ListLoadingView(cardCount: 5)
        : ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              if (widget.adminMode)
                const AdminPageHeader(
                  title: 'Unregistered vendor incidents',
                  subtitle:
                      'Review buyer evidence and investigate reports involving vendors who are not registered in the market directory.',
                  icon: Icons.gpp_bad_rounded,
                )
              else
                _CommunityIncidentHeader(
                  total: controller.incidents.length,
                  pending: controller.incidents
                      .where(
                        (item) =>
                            item.incident.status == 'pending' ||
                            item.incident.status == 'under_review',
                      )
                      .length,
                  showAction: controller.incidents.isNotEmpty,
                ),
              if (controller.error != null) ...[
                const SizedBox(height: AppSpacing.md),
                AdminErrorBanner(message: controller.error!),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (controller.incidents.isEmpty)
                EmptyStateView(
                  title: 'No reports submitted',
                  message: widget.adminMode
                      ? 'Submitted buyer incidents will appear here.'
                      : 'If you encounter an unregistered vendor, submit factual details and photo evidence for confidential review.',
                  icon: Icons.shield_outlined,
                  action: widget.adminMode
                      ? null
                      : FilledButton.icon(
                          onPressed: () =>
                              _goAfterPointerEvent(context, '/incident/new'),
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: const Text('Report unregistered vendor'),
                        ),
                )
              else
                ...controller.incidents.map(
                  (item) => Padding(
                    key: ValueKey('vendor-incident-${item.incident.id}'),
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _IncidentCard(
                      data: item,
                      adminMode: widget.adminMode,
                      onStatus: item.incident.id == null
                          ? null
                          : (status) => controller.updateStatus(
                              item.incident.id!,
                              status,
                            ),
                      onDelete: widget.adminMode && item.incident.id != null
                          ? () => _confirmAndDelete(item)
                          : null,
                    ),
                  ),
                ),
            ],
          );
    return Scaffold(
      appBar: widget.adminMode || MediaQuery.sizeOf(context).width >= 1024
          ? null
          : AppBar(
              leading: const AppShellMenuButton(),
              title: const Text('Unregistered Vendors'),
              actions: const [AppNotificationButton(), SizedBox(width: 8)],
            ),
      body: AppBackground(
        showTopGlow: false,
        child: widget.adminMode
            ? AdminPageFrame(maxWidth: 1320, child: content)
            : ResponsivePage(
                maxWidth: 1120,
                expandHeight: true,
                horizontalPadding: 0,
                topPadding: 0,
                bottomPadding: 0,
                edgeToEdgeDesktopOnly: true,
                child: RefreshIndicator(onRefresh: _load, child: content),
              ),
      ),
    );
  }

  Future<bool> _confirmAndDelete(VendorIncidentViewData data) async {
    final incident = data.incident;
    final id = incident.id;
    if (id == null) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.delete_forever_outlined,
          color: AppColors.danger,
        ),
        title: const Text('Delete incident report?'),
        content: Text(
          'This permanently removes the report for "${incident.reportedVendorName}" and all attached photo evidence. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(0, 44),
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;

    final deleted = await context
        .read<VendorIncidentController>()
        .deleteIncident(id);
    if (!mounted) return deleted;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Incident report deleted.'
              : 'The incident report could not be deleted.',
        ),
      ),
    );
    return deleted;
  }
}

class _CommunityIncidentHeader extends StatelessWidget {
  const _CommunityIncidentHeader({
    required this.total,
    required this.pending,
    required this.showAction,
  });

  final int total;
  final int pending;
  final bool showAction;

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    radius: 20,
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confidential incident reports',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Report vendors who are not listed in the official market directory.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryFor(context),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _IncidentMetric(label: 'Submitted', value: '$total'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _IncidentMetric(label: 'In review', value: '$pending'),
            ),
          ],
        ),
        if (showAction) ...[
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _goAfterPointerEvent(context, '/incident/new'),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Report another vendor'),
          ),
        ],
      ],
    ),
  );
}

class _IncidentMetric extends StatelessWidget {
  const _IncidentMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    decoration: BoxDecoration(
      color: AppColors.surfaceMutedFor(context),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppColors.borderFor(context)),
    ),
    child: Row(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
          ),
        ),
      ],
    ),
  );
}

class _IncidentHero extends StatelessWidget {
  const _IncidentHero({required this.onViewReports});
  final VoidCallback onViewReports;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        const Icon(Icons.shield_outlined, color: Colors.white, size: 42),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report a suspicious vendor',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Help protect buyers by sending factual details and photo evidence to authorized market administrators.',
                style: TextStyle(color: Color(0xFFE9D5E1), height: 1.45),
              ),
            ],
          ),
        ),
        if (MediaQuery.sizeOf(context).width >= 700)
          OutlinedButton.icon(
            onPressed: onViewReports,
            // The application-wide button theme uses Size.fromHeight, which
            // intentionally expands buttons in vertical forms. This action is
            // a non-flex child of a Row, so it must opt out of infinite width.
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            icon: const Icon(Icons.history_rounded),
            label: const Text('My incidents'),
          ),
      ],
    ),
  );
}

class _EvidencePicker extends StatelessWidget {
  const _EvidencePicker({
    required this.evidence,
    required this.isBusy,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });
  final List<_EvidenceImage> evidence;
  final bool isBusy;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Photo evidence *',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 5),
      Text(
        'Attach 1–3 clear photos. Avoid photographing unrelated people or private information.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondaryFor(context),
        ),
      ),
      const SizedBox(height: 13),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton.icon(
            onPressed: evidence.length >= 3 || isBusy ? null : onCamera,
            icon: isBusy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_camera_outlined),
            label: Text(isBusy ? 'Opening…' : 'Take photo'),
          ),
          OutlinedButton.icon(
            onPressed: evidence.length >= 3 || isBusy ? null : onGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose photo'),
          ),
        ],
      ),
      if (evidence.isNotEmpty) ...[
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(evidence.length, (index) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    evidence[index].bytes,
                    width: 138,
                    height: 108,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: -7,
                  top: -7,
                  child: IconButton.filled(
                    onPressed: () => onRemove(index),
                    icon: const Icon(Icons.close_rounded, size: 17),
                    tooltip: 'Remove photo',
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    ],
  );
}

class _CameraCaptureDialog extends StatefulWidget {
  const _CameraCaptureDialog();

  @override
  State<_CameraCaptureDialog> createState() => _CameraCaptureDialogState();
}

class _CameraCaptureDialogState extends State<_CameraCaptureDialog>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('no-camera', 'No camera was found.');
      }
      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() => _error = _cameraErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'The camera could not start. Check camera access and try again.',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }
    setState(() => _isCapturing = true);
    try {
      final photo = await controller.takePicture();
      if (mounted) Navigator.of(context).pop(photo);
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _error = _cameraErrorMessage(error);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final controller = _controller;
    return Dialog(
      insetPadding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 0 : 24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 820),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
              child: Row(
                children: [
                  const Icon(Icons.photo_camera_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Take evidence photo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isCapturing
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close camera',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: Colors.black,
                child: Center(
                  child: _error != null
                      ? Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.no_photography_outlined,
                                color: Colors.white70,
                                size: 44,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'On web, camera access requires HTTPS or localhost.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white60),
                              ),
                            ],
                          ),
                        )
                      : controller == null || !controller.value.isInitialized
                      ? const CircularProgressIndicator(color: Colors.white)
                      : AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: CameraPreview(controller),
                        ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        controller == null ||
                            !controller.value.isInitialized ||
                            _error != null ||
                            _isCapturing
                        ? null
                        : _capture,
                    icon: _isCapturing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera_rounded),
                    label: Text(_isCapturing ? 'Capturing…' : 'Capture photo'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cameraErrorMessage(CameraException error) {
    if (error.code.contains('AccessDenied') ||
        error.code.contains('permission')) {
      return 'Camera access was denied. Allow camera permission in your device or browser settings.';
    }
    return error.description ?? 'The camera could not start.';
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    required this.data,
    required this.adminMode,
    required this.onStatus,
    required this.onDelete,
  });
  final VendorIncidentViewData data;
  final bool adminMode;
  final ValueChanged<String>? onStatus;
  final Future<bool> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final incident = data.incident;
    final created = DateTime.tryParse(incident.createdAt)?.toLocal();
    return AppSurfaceCard(
      radius: 20,
      padding: const EdgeInsets.all(20),
      onTap: adminMode
          ? () => _showIncidentPreview(context, data, onStatus, onDelete)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.gpp_bad_outlined,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.reportedVendorName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _incidentReasons[incident.reasonCode] ?? 'Other concern',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      incident.marketLocation,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _IncidentStatus(status: incident.status),
                  if (adminMode) ...[
                    const SizedBox(height: 7),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Click to review',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (onDelete != null) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: onDelete,
                            tooltip: 'Delete incident report',
                            visualDensity: VisualDensity.compact,
                            color: AppColors.danger,
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(incident.details, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: incident.evidencePhotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, index) {
                final bytes = _decodeEvidence(incident.evidencePhotos[index]);
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: bytes == null
                      ? null
                      : () => _showEvidencePreview(context, bytes, index + 1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: bytes == null
                        ? const SizedBox(
                            width: 120,
                            child: Icon(Icons.broken_image),
                          )
                        : Image.memory(bytes, width: 145, fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${adminMode ? 'Reported by ${data.reporterName} • ' : ''}${created == null ? incident.createdAt : DateFormat('MMM d, y • h:mm a').format(created)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
              if (adminMode)
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: incident.status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'under_review',
                        child: Text('Under review'),
                      ),
                      DropdownMenuItem(
                        value: 'resolved',
                        child: Text('Resolved'),
                      ),
                      DropdownMenuItem(
                        value: 'dismissed',
                        child: Text('Dismissed'),
                      ),
                    ],
                    onChanged: onStatus == null
                        ? null
                        : (value) {
                            if (value != null && value != incident.status) {
                              Future<void>.delayed(Duration.zero, () {
                                onStatus!(value);
                              });
                            }
                          },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _showIncidentPreview(
  BuildContext context,
  VendorIncidentViewData data,
  ValueChanged<String>? onStatus,
  Future<bool> Function()? onDelete,
) {
  final incident = data.incident;
  final created = DateTime.tryParse(incident.createdAt)?.toLocal();
  final updated = DateTime.tryParse(incident.updatedAt)?.toLocal();
  var selectedStatus = incident.status;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 780),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 12, 14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.fact_check_outlined,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Incident review',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            incident.id == null
                                ? 'Unregistered incident record'
                                : 'Reference #${incident.id}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondaryFor(context),
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      tooltip: 'Close preview',
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.borderFor(context)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _IncidentDetailTile(
                            icon: Icons.person_search_outlined,
                            label: 'Reported vendor',
                            value: incident.reportedVendorName,
                          ),
                          _IncidentDetailTile(
                            icon: Icons.location_on_outlined,
                            label: 'Market location',
                            value: incident.marketLocation,
                          ),
                          _IncidentDetailTile(
                            icon: Icons.person_outline_rounded,
                            label: 'Reported by',
                            value: data.reporterName,
                          ),
                          _IncidentDetailTile(
                            icon: Icons.gpp_bad_outlined,
                            label: 'Reason',
                            value:
                                _incidentReasons[incident.reasonCode] ??
                                'Other serious concern',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Incident statement',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMutedFor(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.borderFor(context),
                          ),
                        ),
                        child: SelectableText(
                          incident.details,
                          style: const TextStyle(height: 1.55),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Photo evidence (${incident.evidencePhotos.length})',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Text(
                            'Select a photo to enlarge',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondaryFor(context),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (incident.evidencePhotos.isEmpty)
                        const Text('No photo evidence is attached.')
                      else
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (
                              var index = 0;
                              index < incident.evidencePhotos.length;
                              index++
                            )
                              _EvidencePreviewTile(
                                bytes: _decodeEvidence(
                                  incident.evidencePhotos[index],
                                ),
                                index: index + 1,
                              ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Text(
                            'Submitted: ${created == null ? incident.createdAt : DateFormat('MMM d, y • h:mm a').format(created)}',
                          ),
                          Text(
                            'Last updated: ${updated == null ? incident.updatedAt : DateFormat('MMM d, y • h:mm a').format(updated)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: AppColors.borderFor(context)),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Moderation status',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem(
                            value: 'under_review',
                            child: Text('Under review'),
                          ),
                          DropdownMenuItem(
                            value: 'resolved',
                            child: Text('Resolved'),
                          ),
                          DropdownMenuItem(
                            value: 'dismissed',
                            child: Text('Dismissed'),
                          ),
                        ],
                        onChanged: onStatus == null
                            ? null
                            : (value) {
                                if (value == null || value == selectedStatus) {
                                  return;
                                }
                                setDialogState(() => selectedStatus = value);
                                onStatus(value);
                              },
                      ),
                    ),
                    const SizedBox(width: 14),
                    if (onDelete != null) ...[
                      TextButton.icon(
                        onPressed: () async {
                          final deleted = await onDelete();
                          if (deleted && dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Delete'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                      ),
                      child: const Text('Close'),
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

class _IncidentDetailTile extends StatelessWidget {
  const _IncidentDetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: (MediaQuery.sizeOf(context).width - 88).clamp(220, 390).toDouble(),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surfaceMutedFor(context),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.borderFor(context)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              SelectableText(
                value,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EvidencePreviewTile extends StatelessWidget {
  const _EvidencePreviewTile({required this.bytes, required this.index});

  final Uint8List? bytes;
  final int index;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: bytes == null
        ? null
        : () => _showEvidencePreview(context, bytes!, index),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      width: 190,
      height: 135,
      decoration: BoxDecoration(
        color: AppColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes == null
          ? const Center(child: Icon(Icons.broken_image_outlined))
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(bytes!, fit: BoxFit.cover),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .68),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Photo $index',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    ),
  );
}

Future<void> _showEvidencePreview(
  BuildContext context,
  Uint8List bytes,
  int index,
) => showDialog<void>(
  context: context,
  builder: (dialogContext) => Dialog(
    backgroundColor: Colors.black,
    insetPadding: const EdgeInsets.all(20),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 820),
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: .8,
              maxScale: 5,
              child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: Text(
              'Evidence photo $index',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton.filled(
              onPressed: () => Navigator.of(dialogContext).pop(),
              tooltip: 'Close image preview',
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    ),
  ),
);

class _IncidentStatus extends StatelessWidget {
  const _IncidentStatus({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'resolved' => AppColors.success,
      'dismissed' => AppColors.textSecondaryFor(context),
      'under_review' => AppColors.sky,
      _ => AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EvidenceImage {
  const _EvidenceImage({required this.bytes});
  final Uint8List bytes;
}

Uint8List? _decodeEvidence(String value) {
  try {
    return base64Decode(value.split(',').last);
  } catch (_) {
    return null;
  }
}

void _goAfterPointerEvent(BuildContext context, String location) {
  // Web hover processing may still be walking the old render tree during the
  // button callback. Wait until the current frame is complete before replacing
  // the route so MouseTracker never receives a half-disposed render object.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future<void>.delayed(const Duration(milliseconds: 16), () {
      if (context.mounted) context.go(location);
    });
  });
}
