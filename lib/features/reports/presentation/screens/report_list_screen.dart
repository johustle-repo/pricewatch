import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/store_qr_codec.dart';
import '../../../../features/admin/presentation/widgets/admin_page_frame.dart';
import '../../../../features/admin/presentation/widgets/admin_workspace_widgets.dart';
import '../../../../shared/models/ui_models.dart';
import '../../../../shared/widgets/adaptive_stat_grid.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_notification_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_shell_menu_button.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/commodity_visual.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/responsive_page.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/report_controller.dart';
import 'store_qr_scanner_screen.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthController>().currentUser;
      final controller = context.read<ReportController>();
      final userId = user?.id;
      final storeId = user?.storeId;
      if (user?.isVendor == true && storeId != null) {
        controller.loadStoreReports(storeId);
      } else if (userId != null) {
        controller.loadUserReports(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final controller = context.watch<ReportController>();
    final user = auth.currentUser;
    final userId = user?.id;
    final isVendor = user?.isVendor ?? false;
    final vendorStoreId = user?.storeId;
    final reports = controller.reports;
    final query = _searchController.text.trim().toLowerCase();
    final visibleReports = reports.where((report) {
      final matchesQuery =
          query.isEmpty ||
          report.commodityName.toLowerCase().contains(query) ||
          report.storeName.toLowerCase().contains(query) ||
          report.reason.toLowerCase().contains(query);
      return matchesQuery &&
          (_statusFilter == 'all' || report.status == _statusFilter);
    }).toList();
    final webLayout = useAdminWebLayout(context);
    final isVendorWeb = isVendor && webLayout;
    final useCommunityWebShell = !isVendor && webLayout;

    return Scaffold(
      appBar: isVendorWeb || useCommunityWebShell
          ? null
          : AppBar(
              leading: const AppShellMenuButton(),
              title: Text(isVendor ? 'Reports to My Shop' : 'My Reports'),
              actions: const [AppNotificationButton(), SizedBox(width: 8)],
            ),
      floatingActionButton: isVendor
          ? null
          : FloatingActionButton.extended(
              onPressed: _startQrReportFlow,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan QR'),
            ),
      body: userId == null
          ? const SizedBox.shrink()
          : isVendorWeb
          ? AppBackground(
              showTopGlow: false,
              child: AdminPageFrame(
                maxWidth: 1320,
                child: _VendorReportsWebView(
                  reports: reports,
                  isLoading: controller.isLoading,
                  error: controller.error,
                  onRefresh: vendorStoreId == null
                      ? null
                      : () => context.read<ReportController>().loadStoreReports(
                          vendorStoreId,
                        ),
                ),
              ),
            )
          : AppBackground(
              child: ResponsivePage(
                maxWidth: 1120,
                expandHeight: true,
                horizontalPadding: 0,
                topPadding: 0,
                bottomPadding: 0,
                edgeToEdgeDesktopOnly: true,
                child: RefreshIndicator(
                  onRefresh: () => isVendor && vendorStoreId != null
                      ? context.read<ReportController>().loadStoreReports(
                          vendorStoreId,
                        )
                      : context.read<ReportController>().loadUserReports(
                          userId,
                        ),
                  child: controller.isLoading
                      ? const ListLoadingView(cardCount: 5)
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          children: [
                            _ReportsHero(
                              isVendor: isVendor,
                              totalReports: reports.length,
                              pendingReports: reports
                                  .where((report) => report.status == 'pending')
                                  .length,
                            ),
                            if (controller.error != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              _CommunityLoadError(
                                message: controller.error!,
                                onRetry: () => isVendor && vendorStoreId != null
                                    ? controller.loadStoreReports(vendorStoreId)
                                    : controller.loadUserReports(userId),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            _CommunityReportFilters(
                              controller: _searchController,
                              status: _statusFilter,
                              onSearch: () => setState(() {}),
                              onStatusChanged: (value) =>
                                  setState(() => _statusFilter = value),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (visibleReports.isEmpty)
                              EmptyStateView(
                                title: isVendor
                                    ? 'No matching shop reports'
                                    : 'No matching reports',
                                message: isVendor
                                    ? 'Reports from buyers will appear here when they scan your shop QR code and submit a concern.'
                                    : 'Use the QR scan action to start a report faster and track its review status.',
                                icon: isVendor
                                    ? Icons.verified_outlined
                                    : Icons.flag_outlined,
                                action: isVendor
                                    ? null
                                    : SizedBox(
                                        width: 220,
                                        child: AppPrimaryButton(
                                          label: 'Scan store QR',
                                          icon: Icons.qr_code_scanner_rounded,
                                          onPressed: _startQrReportFlow,
                                        ),
                                      ),
                              )
                            else
                              ...visibleReports.map(
                                (report) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _ReportListCard(report: report),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
    );
  }

  Future<void> _startQrReportFlow() async {
    final payload = await Navigator.of(context).push<StoreQrPayload>(
      MaterialPageRoute(builder: (_) => const StoreQrScannerScreen()),
    );
    if (!mounted || payload == null) {
      return;
    }

    context.push('/report/new?storeId=${payload.storeId}');
  }
}

class _CommunityLoadError extends StatelessWidget {
  const _CommunityLoadError({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.warning),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}

class _CommunityReportFilters extends StatelessWidget {
  const _CommunityReportFilters({
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
          hintText: 'Search commodity, store, or report reason',
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
        onChanged: (value) => onStatusChanged(value ?? 'all'),
      );
      if (constraints.maxWidth < 640) {
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

class _VendorReportsWebView extends StatefulWidget {
  const _VendorReportsWebView({
    required this.reports,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
  });

  final List<ReportViewData> reports;
  final bool isLoading;
  final String? error;
  final Future<void> Function()? onRefresh;

  @override
  State<_VendorReportsWebView> createState() => _VendorReportsWebViewState();
}

class _VendorReportsWebViewState extends State<_VendorReportsWebView> {
  String _query = '';
  String _status = 'all';

  @override
  Widget build(BuildContext context) {
    final reports = widget.reports;
    final sortedReports =
        reports.where((report) {
          final query = _query.trim().toLowerCase();
          final matchesQuery =
              query.isEmpty ||
              report.commodityName.toLowerCase().contains(query) ||
              report.reason.toLowerCase().contains(query) ||
              report.userName.toLowerCase().contains(query);
          return matchesQuery && (_status == 'all' || report.status == _status);
        }).toList()..sort((a, b) {
          final aOpen = a.status == 'pending' || a.status == 'reviewed';
          final bOpen = b.status == 'pending' || b.status == 'reviewed';
          if (aOpen != bOpen) return aOpen ? -1 : 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });
    final pending = reports
        .where((report) => report.status == 'pending')
        .length;
    final resolved = reports
        .where((report) => report.status == 'resolved')
        .length;

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xxxl,
        ),
        children: [
          AdminPageHeader(
            eyebrow: 'Vendor workspace',
            title: 'Shop Reports',
            subtitle: 'Buyer reports connected to your assigned shop QR.',
            icon: Icons.assignment_rounded,
            metrics: [
              AdminHeaderMetric(
                label: 'Total reports',
                value: '${reports.length}',
                icon: Icons.flag_outlined,
              ),
              AdminHeaderMetric(
                label: 'Pending',
                value: '$pending',
                icon: Icons.pending_actions_outlined,
                accent: AppColors.warning,
              ),
              AdminHeaderMetric(
                label: 'Resolved',
                value: '$resolved',
                icon: Icons.verified_outlined,
                accent: AppColors.sky,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (widget.error != null) ...[
            AdminErrorBanner(message: widget.error!),
            const SizedBox(height: AppSpacing.md),
          ],
          AdminSectionCard(
            title: 'Reports',
            subtitle:
                'Review the submitted concern and open a report for details.',
            child: widget.isLoading
                ? const ListLoadingView(cardCount: 4)
                : reports.isEmpty
                ? const EmptyStateView(
                    title: 'No reports',
                    message: 'Buyer reports for this shop will appear here.',
                    icon: Icons.assignment_outlined,
                  )
                : Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final search = TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search commodity, reporter, or reason',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                            onChanged: (value) =>
                                setState(() => _query = value),
                          );
                          final status = DropdownButtonFormField<String>(
                            initialValue: _status,
                            decoration: const InputDecoration(
                              labelText: 'Report status',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All'),
                              ),
                              DropdownMenuItem(
                                value: 'pending',
                                child: Text('Pending'),
                              ),
                              DropdownMenuItem(
                                value: 'reviewed',
                                child: Text('Under review'),
                              ),
                              DropdownMenuItem(
                                value: 'resolved',
                                child: Text('Resolved'),
                              ),
                              DropdownMenuItem(
                                value: 'rejected',
                                child: Text('Rejected'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _status = value ?? 'all'),
                          );
                          return constraints.maxWidth < 680
                              ? Column(
                                  children: [
                                    search,
                                    const SizedBox(height: 10),
                                    status,
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(flex: 3, child: search),
                                    const SizedBox(width: 12),
                                    Expanded(child: status),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (sortedReports.isEmpty)
                        const EmptyStateView(
                          title: 'No matching reports',
                          message: 'Change the search or status filter.',
                          icon: Icons.search_off_rounded,
                        )
                      else
                        AdminDataTableCard(
                          minWidth: 1040,
                          columns: const [
                            'Commodity',
                            'Reported by',
                            'Observed price',
                            'Difference',
                            'SRP',
                            'Status',
                            'Submitted',
                            'Actions',
                          ],
                          rows: [
                            for (final report in sortedReports)
                              DataRow(
                                cells: [
                                  DataCell(
                                    _ReportTableNameCell(
                                      title: report.commodityName,
                                      subtitle: report.reason,
                                    ),
                                  ),
                                  DataCell(Text(report.userName)),
                                  DataCell(
                                    Text(
                                      AppFormatters.currency(
                                        report.observedPrice,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      AppFormatters.currency(
                                        report.observedPrice -
                                            report.srpSnapshot,
                                      ),
                                      style: TextStyle(
                                        color:
                                            report.observedPrice >
                                                report.srpSnapshot
                                            ? AppColors.warning
                                            : AppColors.primaryDark,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      AppFormatters.currency(
                                        report.srpSnapshot,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    AppStatusBadge(
                                      label: report.status.toUpperCase(),
                                      color: _ReportStatusVisual.fromStatus(
                                        report.status,
                                      ).color,
                                      icon: _ReportStatusVisual.fromStatus(
                                        report.status,
                                      ).icon,
                                    ),
                                  ),
                                  DataCell(
                                    Text(AppFormatters.date(report.createdAt)),
                                  ),
                                  DataCell(
                                    TextButton.icon(
                                      onPressed: () => context.push(
                                        '/report/${report.reportId}',
                                      ),
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                      ),
                                      label: const Text('View details'),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReportTableNameCell extends StatelessWidget {
  const _ReportTableNameCell({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.flag_rounded,
              color: AppColors.primaryDark,
              size: 19,
            ),
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

class _ReportsHero extends StatelessWidget {
  const _ReportsHero({
    required this.isVendor,
    required this.totalReports,
    required this.pendingReports,
  });

  final bool isVendor;
  final int totalReports;
  final int pendingReports;

  @override
  Widget build(BuildContext context) {
    final useDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: useDark
              ? const [Color(0xFF5A1735), Color(0xFF8C2450), Color(0xFFB42363)]
              : const [Color(0xFF9A3412), AppColors.warning, Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: useDark ? AppColors.glowStrong : const Color(0x33F97316),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isVendor ? 'Reports to your shop' : 'Community reports',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isVendor
                ? 'These are buyer concerns attached to your assigned shop. Use them to respond quickly and keep prices trusted.'
                : 'Monitor every overpricing complaint you\'ve filed and see which ones still need review.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AdaptiveStatGrid(
            minTileWidth: 110,
            children: [
              _HeroMetric(
                label: isVendor ? 'Shop reports' : 'Reports filed',
                value: '$totalReports',
              ),
              _HeroMetric(label: 'Pending review', value: '$pendingReports'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportListCard extends StatelessWidget {
  const _ReportListCard({required this.report});

  final ReportViewData report;

  @override
  Widget build(BuildContext context) {
    final visual = _ReportStatusVisual.fromStatus(report.status);

    return AppSurfaceCard(
      onTap: () => context.push('/report/${report.reportId}'),
      borderColor: visual.color.withValues(alpha: 0.2),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          visual.color.withValues(
            alpha: AppColors.isDark(context) ? 0.12 : 0.07,
          ),
          AppColors.surfaceFor(context),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 380;
          final headerContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    report.commodityName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  AppStatusBadge(
                    label: visual.label,
                    color: visual.color,
                    icon: visual.icon,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                report.storeName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Text(
                report.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
          final footer = compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppFormatters.currency(report.observedPrice),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.dateTime(report.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppFormatters.currency(report.observedPrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppFormatters.dateTime(report.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );

          if (compact) {
            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 148),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommodityVisual(label: report.commodityName, size: 64),
                      const SizedBox(width: 14),
                      Expanded(child: headerContent),
                    ],
                  ),
                  const SizedBox(height: 14),
                  footer,
                ],
              ),
            );
          }

          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 122),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommodityVisual(label: report.commodityName, size: 68),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      headerContent,
                      const SizedBox(height: 14),
                      footer,
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportStatusVisual {
  const _ReportStatusVisual({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  factory _ReportStatusVisual.fromStatus(String status) {
    switch (status) {
      case 'resolved':
        return const _ReportStatusVisual(
          label: 'Resolved',
          icon: Icons.verified_rounded,
          color: AppColors.primaryDark,
        );
      case 'reviewed':
        return const _ReportStatusVisual(
          label: 'Reviewed',
          icon: Icons.fact_check_rounded,
          color: AppColors.sky,
        );
      default:
        return const _ReportStatusVisual(
          label: 'Pending',
          icon: Icons.schedule_rounded,
          color: AppColors.warning,
        );
    }
  }
}
