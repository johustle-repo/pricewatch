import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import 'admin_page_frame.dart';

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.icon = Icons.dashboard_customize_rounded,
    this.action,
    this.metrics = const [],
  });

  final String title;
  final String subtitle;
  final String? eyebrow;
  final IconData icon;
  final Widget? action;
  final List<Widget> metrics;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;
    final webLayout = useAdminWebLayout(context);
    return AppSurfaceCard(
      radius: webLayout ? 24 : (compact ? 22 : 26),
      padding: EdgeInsets.all(
        webLayout
            ? AppSpacing.xl
            : compact
            ? AppSpacing.md
            : AppSpacing.lg,
      ),
      gradient: webLayout
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF111C35), Color(0xFF182845), Color(0xFF223557)],
            )
          : null,
      borderColor: webLayout ? const Color(0xFF2C4164) : null,
      shadowColor: webLayout ? const Color(0x33101A2E) : null,
      child: Builder(
        builder: (context) {
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: webLayout ? 44 : 48,
                    height: webLayout ? 44 : 48,
                    decoration: BoxDecoration(
                      gradient: webLayout
                          ? const LinearGradient(
                              colors: [Color(0xFFE11D67), Color(0xFFFB7185)],
                            )
                          : AppColors.primaryGradientFor(context),
                      borderRadius: BorderRadius.circular(webLayout ? 12 : 16),
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eyebrow != null) ...[
                          Text(
                            eyebrow!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: webLayout
                                      ? const Color(0xFFA8B5CB)
                                      : AppColors.textSecondaryFor(context),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          title,
                          style:
                              (webLayout
                                      ? Theme.of(context).textTheme.titleLarge
                                      : Theme.of(
                                          context,
                                        ).textTheme.headlineSmall)
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: webLayout
                                        ? Colors.white
                                        : AppColors.textPrimaryFor(context),
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: webLayout
                                    ? const Color(0xFFC6D0E0)
                                    : AppColors.textSecondaryFor(context),
                              ),
                        ),
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
                  ),
                ],
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              content,
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          );
        },
      ),
    );
  }
}

class AdminHeaderMetric extends StatelessWidget {
  const AdminHeaderMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AppColors.primaryDark,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 148, maxWidth: 178),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFFF8BA7), size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFB9C5D8),
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

class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;
    return AppSurfaceCard(
      radius: compact ? 20 : 22,
      padding: compact ? const EdgeInsets.all(AppSpacing.lg) : padding,
      gradient: AppColors.isDark(context)
          ? null
          : const LinearGradient(colors: [Colors.white, Color(0xFFFCFDFE)]),
      borderColor: AppColors.isDark(context) ? null : const Color(0xFFE2E8F0),
      shadowColor: AppColors.isDark(context) ? null : const Color(0x140F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) {
              final wide = MediaQuery.sizeOf(context).width >= 980;
              final info = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                  ],
                ],
              );

              if (!wide || action == null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    info,
                    if (action != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      action!,
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: info),
                  const SizedBox(width: AppSpacing.lg),
                  Flexible(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: action!,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class AdminDataTableCard extends StatefulWidget {
  const AdminDataTableCard({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth = 900,
    this.fontScale = 1,
  });

  final List<String> columns;
  final List<DataRow> rows;
  final double minWidth;
  final double fontScale;

  @override
  State<AdminDataTableCard> createState() => _AdminDataTableCardState();
}

class _AdminDataTableCardState extends State<AdminDataTableCard> {
  int _pageSize = 10;
  int _page = 0;

  @override
  void didUpdateWidget(covariant AdminDataTableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pageCount = _pageCount(widget.rows.length);
    if (_page >= pageCount) _page = pageCount - 1;
  }

  int _pageCount(int count) => count == 0 ? 1 : (count / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    final pageCount = _pageCount(widget.rows.length);
    final visibleRows = widget.rows
        .skip(_page * _pageSize)
        .take(_pageSize)
        .toList();
    final headingColor = AppColors.isDark(context)
        ? AppColors.surfaceMutedFor(context)
        : const Color(0xFF17233B);

    return AppSurfaceCard(
      radius: 20,
      padding: EdgeInsets.zero,
      borderColor: AppColors.isDark(context) ? null : const Color(0xFFDCE3EC),
      shadowColor: AppColors.isDark(context) ? null : const Color(0x100F172A),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth > widget.minWidth
                    ? constraints.maxWidth
                    : widget.minWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: DataTable(
                      headingRowColor: WidgetStatePropertyAll(headingColor),
                      headingTextStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(
                            fontSize:
                                (Theme.of(
                                      context,
                                    ).textTheme.labelLarge?.fontSize ??
                                    14) *
                                widget.fontScale,
                            color: AppColors.isDark(context)
                                ? AppColors.textSecondaryFor(context)
                                : const Color(0xFFE8EEF7),
                            fontWeight: FontWeight.w800,
                          ),
                      dataRowColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return AppColors.isDark(context)
                              ? AppColors.surfaceMutedFor(context)
                              : const Color(0xFFF7F9FC);
                        }
                        return Colors.transparent;
                      }),
                      dataTextStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(
                            fontSize:
                                (Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.fontSize ??
                                    14) *
                                widget.fontScale,
                            color: AppColors.textPrimaryFor(context),
                          ),
                      dividerThickness: 0.8,
                      horizontalMargin: AppSpacing.lg,
                      columnSpacing: AppSpacing.xl,
                      headingRowHeight: 58,
                      dataRowMinHeight: 68,
                      dataRowMaxHeight: 82,
                      columns: [
                        for (final column in widget.columns)
                          DataColumn(
                            label: Text(
                              column,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      rows: visibleRows,
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.rows.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceFor(context),
                border: Border(
                  top: BorderSide(color: AppColors.borderFor(context)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Page ${_page + 1} of $pageCount · ${widget.rows.length} records',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(width: 12),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _pageSize,
                      items: const [10, 25, 50]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value rows'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        _pageSize = value ?? 10;
                        _page = 0;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Previous page',
                    onPressed: _page == 0
                        ? null
                        : () => setState(() => _page--),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  IconButton(
                    tooltip: 'Next page',
                    onPressed: _page >= pageCount - 1
                        ? null
                        : () => setState(() => _page++),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class AdminErrorBanner extends StatelessWidget {
  const AdminErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? const Color(0xFF4B2A1D)
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Something needs attention',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
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

class AdminResponsiveSplit extends StatelessWidget {
  const AdminResponsiveSplit({
    super.key,
    required this.primary,
    required this.secondary,
    this.spacing = AppSpacing.lg,
    this.breakpoint = 980,
    this.primaryFlex = 3,
    this.secondaryFlex = 2,
  });

  final Widget primary;
  final Widget secondary;
  final double spacing;
  final double breakpoint;
  final int primaryFlex;
  final int secondaryFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              primary,
              SizedBox(height: spacing),
              secondary,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: primaryFlex, child: primary),
            SizedBox(width: spacing),
            Expanded(flex: secondaryFlex, child: secondary),
          ],
        );
      },
    );
  }
}
