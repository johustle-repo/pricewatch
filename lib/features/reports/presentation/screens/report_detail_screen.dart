import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/models/ui_models.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_notification_button.dart';
import '../../../../shared/widgets/app_shell_menu_button.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/commodity_visual.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/price_trend_badge.dart';
import '../../../../shared/widgets/responsive_page.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/report_controller.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key, required this.reportId});

  final int reportId;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportController>().loadReport(widget.reportId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final useWebShell = MediaQuery.sizeOf(context).width >= 1024;
    final controller = context.watch<ReportController>();
    final isVendor =
        context.watch<AuthController>().currentUser?.isVendor ?? false;
    final report = controller.detail;

    return Scaffold(
      appBar: useWebShell
          ? null
          : AppBar(
              leading: const AppShellMenuButton(),
              title: const Text('Report Details'),
              actions: const [AppNotificationButton(), SizedBox(width: 8)],
            ),
      body: AppBackground(
        child: controller.isLoading && report == null
            ? const ListLoadingView(cardCount: 4)
            : report == null
            ? const EmptyStateView(
                title: 'Report not found',
                message: 'The selected report is unavailable.',
                icon: Icons.find_in_page_outlined,
              )
            : ResponsivePage(
                maxWidth: 980,
                expandHeight: true,
                horizontalPadding: 0,
                topPadding: 0,
                bottomPadding: 0,
                edgeToEdgeDesktopOnly: true,
                child: ListView(
                  children: [
                    _ReportHeaderCard(report: report),
                    if (isVendor) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _VendorReportActions(
                        report: report,
                        busy: controller.isLoading,
                        onStatusChanged: (status) =>
                            _updateStatus(controller, report, status),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price snapshot',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxWidth < 360;
                              final observed = _MetricTile(
                                label: 'Observed',
                                value: AppFormatters.currency(
                                  report.observedPrice,
                                ),
                              );
                              final snapshot = _MetricTile(
                                label: 'SRP snapshot',
                                value: AppFormatters.currency(
                                  report.srpSnapshot,
                                ),
                              );

                              if (compact) {
                                return Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: observed,
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: snapshot,
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: observed),
                                  const SizedBox(width: 12),
                                  Expanded(child: snapshot),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          PriceTrendBadge(
                            delta: report.observedPrice - report.srpSnapshot,
                            label: report.observedPrice >= report.srpSnapshot
                                ? 'Observed above SRP'
                                : 'Observed below SRP',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report reason',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            report.reason,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (report.photoPath != null &&
                              report.photoPath!.trim().isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundAltFor(context),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    color: AppColors.isDark(context)
                                        ? AppColors.darkPrimarySoft
                                        : AppColors.primaryDark,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      report.photoPath!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Timeline',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _TimelineTile(
                            title: 'Report reference',
                            subtitle:
                                'PW-RPT-${report.reportId.toString().padLeft(8, '0')}',
                            icon: Icons.tag_rounded,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _TimelineTile(
                            title: 'Submitted',
                            subtitle: AppFormatters.dateTime(report.createdAt),
                            icon: Icons.upload_rounded,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _TimelineTile(
                            title: report.status == 'pending'
                                ? 'Awaiting review'
                                : report.status == 'reviewed'
                                ? 'Under review'
                                : 'Resolved',
                            subtitle: AppFormatters.dateTime(report.updatedAt),
                            icon: report.status == 'resolved'
                                ? Icons.check_circle_outline_rounded
                                : Icons.update_rounded,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _TimelineTile(
                            title: 'Reported by',
                            subtitle: report.userName,
                            icon: Icons.person_outline_rounded,
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

  Future<void> _updateStatus(
    ReportController controller,
    ReportViewData report,
    String status,
  ) async {
    if (status == report.status) return;
    final success = await controller.updateReportStatus(
      reportId: report.reportId,
      status: status,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Report marked as ${status == 'reviewed' ? 'under review' : status}.'
              : controller.error ?? 'Could not update report status.',
        ),
      ),
    );
  }
}

class _VendorReportActions extends StatelessWidget {
  const _VendorReportActions({
    required this.report,
    required this.busy,
    required this.onStatusChanged,
  });

  final ReportViewData report;
  final bool busy;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vendor response',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Update the buyer as this report is reviewed. The reporter receives a notification after every change.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: report.status,
          decoration: const InputDecoration(
            labelText: 'Report status',
            prefixIcon: Icon(Icons.fact_check_outlined),
          ),
          items: const [
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
            DropdownMenuItem(value: 'reviewed', child: Text('Under review')),
            DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
          ],
          onChanged: busy
              ? null
              : (value) {
                  if (value != null) onStatusChanged(value);
                },
        ),
      ],
    ),
  );
}

class _ReportHeaderCard extends StatelessWidget {
  const _ReportHeaderCard({required this.report});

  final ReportViewData report;

  @override
  Widget build(BuildContext context) {
    final visual = _ReportStatusVisual.fromStatus(report.status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradientFor(context),
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1E111827),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.commodityName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Store: ${report.storeName}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.84),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppStatusBadge(
                label: visual.label,
                color: visual.color,
                icon: visual.icon,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommodityVisual(label: report.commodityName, size: 82),
                const SizedBox(height: 16),
                info,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommodityVisual(label: report.commodityName, size: 82),
              const SizedBox(width: 16),
              Expanded(child: info),
            ],
          );
        },
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundAltFor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.backgroundAltFor(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: AppColors.isDark(context)
                ? AppColors.darkPrimarySoft
                : AppColors.primaryDark,
          ),
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
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
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
