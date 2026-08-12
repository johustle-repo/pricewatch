import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_seal_badge.dart';

class AuthSplitLayout extends StatelessWidget {
  const AuthSplitLayout({
    super.key,
    required this.mobileChild,
    required this.desktopAside,
    required this.desktopFormChild,
    this.mobileTopSafeArea = true,
    this.desktopFormFirst = false,
  });

  final Widget mobileChild;
  final Widget desktopAside;
  final Widget desktopFormChild;
  final bool mobileTopSafeArea;
  final bool desktopFormFirst;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSplitLayout = kIsWeb && constraints.maxWidth >= 1080;
        final compactHeight = constraints.maxHeight < 820;
        final availableHeight = math.max(0.0, constraints.maxHeight);

        if (!useSplitLayout) {
          return SafeArea(
            top: mobileTopSafeArea,
            child: Center(
              child: LayoutBuilder(
                builder: (context, mobileConstraints) {
                  final mobilePadding = mobileConstraints.maxWidth < 360
                      ? AppSpacing.lg
                      : AppSpacing.xl;
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(mobilePadding),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: mobileConstraints.maxHeight,
                        maxWidth: 460,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: mobileChild,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }

        final formPane = Expanded(
          flex: 9,
          child: _DesktopScrollPane(
            minHeight: availableHeight,
            child: Align(
              alignment: compactHeight ? Alignment.topCenter : Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: compactHeight ? 470 : 490,
                ),
                child: desktopFormChild,
              ),
            ),
          ),
        );

        final asidePane = Expanded(
          flex: 11,
          child: _DesktopScrollPane(
            minHeight: availableHeight,
            child: SizedBox(height: availableHeight, child: desktopAside),
          ),
        );

        return SafeArea(
          left: false,
          top: false,
          bottom: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (desktopFormFirst) formPane else asidePane,
              if (desktopFormFirst) asidePane else formPane,
            ],
          ),
        );
      },
    );
  }
}

class _DesktopScrollPane extends StatelessWidget {
  const _DesktopScrollPane({required this.minHeight, required this.child});

  final double minHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: child,
      ),
    );
  }
}

class AuthShowcasePanel extends StatelessWidget {
  const AuthShowcasePanel({
    super.key,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.stats,
    required this.features,
    this.footer,
    this.showHeader = true,
  });

  final String badge;
  final String title;
  final String subtitle;
  final List<AuthShowcaseStat> stats;
  final List<AuthShowcaseFeature> features;
  final Widget? footer;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 580 || constraints.maxHeight < 760;
        final useDark = AppColors.isDark(context);
        final panelPadding = compact ? 28.0 : 48.0;
        final headerIconSize = compact ? 56.0 : 64.0;
        final statCardWidth = compact ? 146.0 : 170.0;
        final sectionGap = compact ? 18.0 : 20.0;
        final titleStyle =
            (compact
                    ? Theme.of(context).textTheme.headlineMedium
                    : Theme.of(context).textTheme.displaySmall)
                ?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                );

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F1D35), Color(0xFF1C3154), Color(0xFF74163F)],
              stops: [0, .58, 1],
            ),
            borderRadius: BorderRadius.zero,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _AuthShowcaseBackdropPainter(useDark: useDark),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.all(panelPadding),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader) ...[
                          Row(
                            children: [
                              Container(
                                width: headerIconSize,
                                height: headerIconSize,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                    compact ? 18 : 22,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Center(
                                  child: AppSealBadge(
                                    size: compact ? 42 : 48,
                                    padding: 3,
                                    showFrame: false,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Wrap(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFE91E63,
                                        ).withValues(alpha: .20),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        badge,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: compact ? 24 : 32),
                        ],
                        Text(title, style: titleStyle),
                        const SizedBox(height: 14),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                                height: 1.5,
                              ),
                        ),
                        SizedBox(height: compact ? 22 : 28),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: stats
                              .map(
                                (item) => SizedBox(
                                  width: statCardWidth,
                                  child: _AuthShowcaseStatCard(
                                    stat: item,
                                    compact: compact,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        SizedBox(height: sectionGap),
                        Container(
                          padding: EdgeInsets.all(compact ? 18 : 22),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF081528,
                            ).withValues(alpha: .28),
                            borderRadius: BorderRadius.circular(
                              compact ? 24 : 28,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            children: features
                                .map(
                                  (feature) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: feature == features.last ? 0 : 14,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: compact ? 38 : 42,
                                          height: compact ? 38 : 42,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: Icon(
                                            feature.icon,
                                            color: Colors.white,
                                            size: compact ? 18 : 20,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                feature.title,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                feature.description,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.76,
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
                                )
                                .toList(),
                          ),
                        ),
                        if (footer != null) ...[
                          SizedBox(height: sectionGap),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AuthShowcaseBackdropPainter extends CustomPainter {
  const _AuthShowcaseBackdropPainter({required this.useDark});

  final bool useDark;

  @override
  void paint(Canvas canvas, Size size) {
    final accent = useDark ? AppColors.darkPrimarySoft : Colors.white;
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFE91E63).withValues(alpha: .22),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .88, size.height * .12),
              radius: size.width * .48,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * .88, size.height * .12),
      size.width * .48,
      glowPaint,
    );

    final linePaint = Paint()
      ..color = accent.withValues(alpha: useDark ? 0.08 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.50 + i * 0.085);
      final path = Path()
        ..moveTo(size.width * -0.1, y)
        ..quadraticBezierTo(
          size.width * 0.48,
          y - size.height * (0.07 + i * .004),
          size.width * 1.1,
          y + size.height * 0.04,
        );
      canvas.drawPath(path, linePaint);
    }

    final ringPaint = Paint()
      ..color = accent.withValues(alpha: .055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(
      Offset(size.width * .83, size.height * .22),
      size.width * .16,
      ringPaint,
    );
    canvas.drawCircle(
      Offset(size.width * .83, size.height * .22),
      size.width * .25,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AuthShowcaseBackdropPainter oldDelegate) {
    return oldDelegate.useDark != useDark;
  }
}

class AuthShowcaseStat {
  const AuthShowcaseStat({required this.value, required this.label});

  final String value;
  final String label;
}

class AuthShowcaseFeature {
  const AuthShowcaseFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _AuthShowcaseStatCard extends StatelessWidget {
  const _AuthShowcaseStatCard({required this.stat, required this.compact});

  final AuthShowcaseStat stat;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stat.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}
