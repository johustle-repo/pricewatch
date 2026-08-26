import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/models/ui_models.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/commodity_visual.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../../data/report_export_service.dart';
import '../../data/admin_export_service.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_page_frame.dart';
import '../widgets/admin_workspace_widgets.dart';

class ManageReportsScreen extends StatefulWidget {
  const ManageReportsScreen({super.key});

  @override
  State<ManageReportsScreen> createState() => _ManageReportsScreenState();
}

class _ManageReportsScreenState extends State<ManageReportsScreen> {
  final _searchController = TextEditingController();
  String _status = 'all';
  int _page = 0;
  static const _pageSize = 8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().loadReports();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();
    final webLayout = useAdminWebLayout(context);
    final pendingCount = controller.reports
        .where((report) => report.status == 'pending')
        .length;
    final resolvedCount = controller.reports
        .where((report) => report.status == 'resolved')
        .length;
    final query = _searchController.text.trim().toLowerCase();
    final filtered = controller.reports.where((report) {
      final matchesStatus = _status == 'all' || report.status == _status;
      final matchesQuery =
          query.isEmpty ||
          report.commodityName.toLowerCase().contains(query) ||
          report.storeName.toLowerCase().contains(query) ||
          report.userName.toLowerCase().contains(query) ||
          report.reason.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();
    final pageCount = filtered.isEmpty
        ? 1
        : (filtered.length / _pageSize).ceil();
    final safePage = _page.clamp(0, pageCount - 1);
    final visibleReports = filtered
        .skip(safePage * _pageSize)
        .take(_pageSize)
        .toList();

    return Scaffold(
      appBar: webLayout ? null : AppBar(title: const Text('Manage Reports')),
      body: AppBackground(
        showTopGlow: false,
        child: controller.isLoading && controller.reports.isEmpty
            ? const ListLoadingView(cardCount: 5)
            : AdminPageFrame(
                maxWidth: 1320,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  children: [
                    AdminPageHeader(
                      eyebrow: 'Community moderation',
                      title: 'Report management',
                      subtitle:
                          'Review overpricing complaints, check observed values against SRP snapshots, and keep reporters informed.',
                      icon: Icons.flag_rounded,
                      webActionAtTop: true,
                      action: SizedBox(
                        width: webLayout ? 220 : double.infinity,
                        child: PopupMenuButton<String>(
                          tooltip: 'Export filtered reports',
                          onSelected: (format) => _export(format, filtered),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'pdf',
                              child: Text('Export PDF'),
                            ),
                            PopupMenuItem(
                              value: 'xlsx',
                              child: Text('Export Excel'),
                            ),
                            PopupMenuItem(
                              value: 'csv',
                              child: Text('Export CSV'),
                            ),
                          ],
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.download_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Export reports',
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
                      metrics: [
                        AdminHeaderMetric(
                          label: 'Total reports',
                          value: '${controller.reports.length}',
                          icon: Icons.flag_outlined,
                          accent: AppColors.warning,
                        ),
                        AdminHeaderMetric(
                          label: 'Pending',
                          value: '$pendingCount',
                          icon: Icons.pending_actions_outlined,
                          accent: AppColors.warning,
                        ),
                        AdminHeaderMetric(
                          label: 'Resolved',
                          value: '$resolvedCount',
                          icon: Icons.verified_outlined,
                          accent: AppColors.primaryDark,
                        ),
                      ],
                    ),
                    if (controller.error != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      AdminErrorBanner(message: controller.error!),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    AdminSectionCard(
                      title: 'Complaint queue',
                      subtitle:
                          '${filtered.length} matching record(s) • page ${safePage + 1} of $pageCount',
                      action: IconButton(
                        tooltip: 'Refresh reports',
                        onPressed: () =>
                            context.read<AdminController>().loadReports(),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                      child: Column(
                        children: [
                          _ReportFilters(
                            controller: _searchController,
                            status: _status,
                            onSearch: () => setState(() => _page = 0),
                            onStatusChanged: (value) => setState(() {
                              _status = value;
                              _page = 0;
                            }),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          filtered.isEmpty
                              ? const EmptyStateView(
                                  title: 'No matching reports',
                                  message:
                                      'Try another search term or report status.',
                                  icon: Icons.flag_outlined,
                                )
                              : Column(
                                  children: [
                                    if (webLayout)
                                      _ReportsTable(
                                        reports: visibleReports,
                                        onStatusChanged: (report, value) =>
                                            _changeStatus(
                                              controller,
                                              report,
                                              value,
                                            ),
                                      )
                                    else
                                      _ReportGrid(
                                        reports: visibleReports,
                                        onStatusChanged: (report, value) =>
                                            _changeStatus(
                                              controller,
                                              report,
                                              value,
                                            ),
                                      ),
                                    if (pageCount > 1) ...[
                                      const SizedBox(height: AppSpacing.lg),
                                      _PaginationBar(
                                        page: safePage,
                                        pageCount: pageCount,
                                        onChanged: (value) =>
                                            setState(() => _page = value),
                                      ),
                                    ],
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _export(String format, List<ReportViewData> reports) async {
    if (reports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There are no reports to export.')),
      );
      return;
    }
    if (format == 'pdf') {
      await ReportExportService.savePdf(reports);
    } else if (format == 'xlsx') {
      const headers = [
        'Report ID',
        'Reporter',
        'Store',
        'Commodity',
        'Observed Price',
        'SRP',
        'Variance',
        'Reason',
        'Status',
        'Submitted',
      ];
      await AdminExportService.saveXlsx(
        sheetName: 'Reports',
        filePrefix: 'pricewatch_reports',
        headers: headers,
        rows: reports
            .map(
              (report) => <Object?>[
                report.reportId,
                report.userName,
                report.storeName,
                report.commodityName,
                report.observedPrice,
                report.srpSnapshot,
                report.observedPrice - report.srpSnapshot,
                report.reason,
                report.status,
                report.createdAt,
              ],
            )
            .toList(),
      );
    } else {
      await ReportExportService.saveCsv(reports);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${format.toUpperCase()} export downloaded.')),
      );
    }
  }

  Future<void> _changeStatus(
    AdminController controller,
    ReportViewData report,
    String? value,
  ) async {
    if (value == null || value == report.status) {
      return;
    }
    await controller.updateReportStatus(
      reportId: report.reportId,
      status: value,
    );
  }
}

class _ReportsTable extends StatelessWidget {
  const _ReportsTable({required this.reports, required this.onStatusChanged});

  final List<ReportViewData> reports;
  final Future<void> Function(ReportViewData report, String? value)
  onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return AdminDataTableCard(
      minWidth: 1280,
      columns: const [
        'Report',
        'Reporter',
        'Store',
        'Observed',
        'SRP',
        'Variance',
        'Submitted',
        'Status',
      ],
      rows: reports.map((report) {
        final variance = report.observedPrice - report.srpSnapshot;
        final varianceLabel =
            '${variance >= 0 ? '+' : '−'}₱${variance.abs().toStringAsFixed(2)}';
        final varianceColor = variance > 0
            ? AppColors.warning
            : AppColors.primaryDark;
        return DataRow(
          cells: [
            DataCell(
              Row(
                children: [
                  CommodityVisual(label: report.commodityName, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.commodityName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '#${report.reportId} • ${report.reason}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondaryFor(context),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DataCell(
              Text(
                report.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataCell(
              Text(
                report.storeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataCell(
              Text(
                '₱${report.observedPrice.toStringAsFixed(2)}',
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ),
            DataCell(
              Text(
                '₱${report.srpSnapshot.toStringAsFixed(2)}',
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(fontSize: 11.5),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: varianceColor.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  varianceLabel,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    color: varianceColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    height: 1,
                  ),
                ),
              ),
            ),
            DataCell(Text(AppFormatters.date(report.createdAt), maxLines: 1)),
            DataCell(
              SizedBox(
                width: 150,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: report.status,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'reviewed',
                        child: Text('Reviewed'),
                      ),
                      DropdownMenuItem(
                        value: 'resolved',
                        child: Text('Resolved'),
                      ),
                    ],
                    onChanged: (value) => onStatusChanged(report, value),
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _ReportGrid extends StatelessWidget {
  const _ReportGrid({required this.reports, required this.onStatusChanged});
  final List<ReportViewData> reports;
  final Future<void> Function(ReportViewData report, String? value)
  onStatusChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1050 ? 2 : 1;
      final gap = AppSpacing.lg;
      final width = columns == 1
          ? constraints.maxWidth
          : (constraints.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: reports
            .map(
              (report) => SizedBox(
                width: width,
                child: _ReportRecordCard(
                  report: report,
                  onStatusChanged: (value) => onStatusChanged(report, value),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class _ReportFilters extends StatelessWidget {
  const _ReportFilters({
    required this.controller,
    required this.status,
    required this.onSearch,
    required this.onStatusChanged,
  });
  final TextEditingController controller;
  final String status;
  final VoidCallback onSearch;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final search = TextField(
        controller: controller,
        onChanged: (_) => onSearch(),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search_rounded),
          hintText: 'Search reporter, shop, commodity, or reason',
        ),
      );
      final filter = DropdownButtonFormField<String>(
        initialValue: status,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.filter_alt_outlined),
          labelText: 'Status',
        ),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('All statuses')),
          DropdownMenuItem(value: 'pending', child: Text('Pending')),
          DropdownMenuItem(value: 'reviewed', child: Text('Reviewed')),
          DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
        ],
        onChanged: (value) {
          if (value != null) onStatusChanged(value);
        },
      );
      if (constraints.maxWidth < 720) {
        return Column(children: [search, const SizedBox(height: 12), filter]);
      }
      return Row(
        children: [
          Expanded(flex: 3, child: search),
          const SizedBox(width: 12),
          Expanded(child: filter),
        ],
      );
    },
  );
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.pageCount,
    required this.onChanged,
  });
  final int page;
  final int pageCount;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      IconButton(
        onPressed: page > 0 ? () => onChanged(page - 1) : null,
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      Text(
        'Page ${page + 1} of $pageCount',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      IconButton(
        onPressed: page + 1 < pageCount ? () => onChanged(page + 1) : null,
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ],
  );
}

class _ReportRecordCard extends StatelessWidget {
  const _ReportRecordCard({
    required this.report,
    required this.onStatusChanged,
  });

  final ReportViewData report;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      radius: 20,
      gradient: AppColors.isDark(context)
          ? null
          : const LinearGradient(colors: [Colors.white, Color(0xFFFBFCFE)]),
      borderColor: AppColors.isDark(context) ? null : const Color(0xFFE2E8F0),
      shadowColor: AppColors.isDark(context) ? null : const Color(0x120F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommodityVisual(label: report.commodityName, size: 68),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.commodityName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppStatusBadge(
                      label: report.status.toUpperCase(),
                      color: _statusColor(report.status),
                      icon: _statusIcon(report.status),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ReportMetaPill(
                label: 'Observed',
                value: AppFormatters.currency(report.observedPrice),
                accent: AppColors.warning,
              ),
              _ReportMetaPill(
                label: 'SRP',
                value: AppFormatters.currency(report.srpSnapshot),
                accent: AppColors.primaryDark,
              ),
              _ReportMetaPill(
                label: 'Reported',
                value: AppFormatters.dateTime(report.createdAt),
                accent: AppColors.sky,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Reported by ${report.userName}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            report.reason,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryFor(context),
              height: 1.5,
            ),
          ),
          if ((report.photoPath ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.backgroundAltFor(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.isDark(context)
                        ? AppColors.darkPrimarySoft
                        : AppColors.primaryDark,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      report.photoPath!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: report.status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('pending')),
              DropdownMenuItem(value: 'reviewed', child: Text('reviewed')),
              DropdownMenuItem(value: 'resolved', child: Text('resolved')),
            ],
            onChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
        return AppColors.primaryDark;
      case 'reviewed':
        return AppColors.sky;
      default:
        return AppColors.warning;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'resolved':
        return Icons.verified_rounded;
      case 'reviewed':
        return Icons.fact_check_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }
}

class _ReportMetaPill extends StatelessWidget {
  const _ReportMetaPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textPrimaryFor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
