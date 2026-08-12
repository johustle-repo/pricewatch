import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    super.key,
    required this.child,
    this.maxWidth = 1180,
    this.expandHeight = false,
    this.includeBottomSafeArea = false,
    this.horizontalPadding,
    this.topPadding = AppSpacing.lg,
    this.bottomPadding = AppSpacing.xxxl,
    this.edgeToEdgeDesktopOnly = false,
  });

  final Widget child;
  final double maxWidth;
  final bool expandHeight;
  final bool includeBottomSafeArea;
  final double? horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final bool edgeToEdgeDesktopOnly;

  static bool isWide(BuildContext context, {double breakpoint = 1024}) {
    return MediaQuery.sizeOf(context).width >= breakpoint;
  }

  static bool isTablet(BuildContext context, {double breakpoint = 720}) {
    return MediaQuery.sizeOf(context).width >= breakpoint;
  }

  static double horizontalPaddingFor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1440) {
      return 32;
    }
    if (width >= 1024) {
      return 28;
    }
    if (width >= 720) {
      return 24;
    }
    return 16;
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = includeBottomSafeArea
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktopLike = constraints.maxWidth >= 720;
        final horizontal = edgeToEdgeDesktopOnly && !isDesktopLike
            ? horizontalPaddingFor(context)
            : (horizontalPadding ?? horizontalPaddingFor(context));
        final resolvedTop = edgeToEdgeDesktopOnly && !isDesktopLike
            ? AppSpacing.md
            : topPadding;
        final resolvedBottom = edgeToEdgeDesktopOnly && !isDesktopLike
            ? AppSpacing.xxxl + 12
            : bottomPadding;
        final availableWidth = math
            .max(0, constraints.maxWidth - (horizontal * 2))
            .toDouble();
        final contentWidth = math.min(maxWidth, availableWidth);
        final verticalPadding = resolvedTop + resolvedBottom + safeBottom;
        final availableHeight = expandHeight
            ? math.max(0, constraints.maxHeight - verticalPadding).toDouble()
            : null;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            resolvedTop,
            horizontal,
            resolvedBottom + safeBottom,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: contentWidth,
              height: availableHeight,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
