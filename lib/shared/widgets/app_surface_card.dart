import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.gradient,
    this.borderColor,
    this.shadowColor,
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? borderColor;
  final Color? shadowColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final effectiveRadius = compact ? radius - 4 : radius;
    final decoration = BoxDecoration(
      gradient: gradient ?? AppColors.surfaceGradientFor(context),
      borderRadius: BorderRadius.circular(effectiveRadius),
      border: Border.all(color: borderColor ?? AppColors.borderFor(context)),
      boxShadow: [
        BoxShadow(
          color:
              shadowColor ??
              AppColors.shadowFor(
                context,
              ).withValues(alpha: compact ? 0.08 : 0.11),
          blurRadius: compact ? 14 : 18,
          offset: Offset(0, compact ? 5 : 7),
        ),
      ],
    );

    if (onTap == null) {
      // Most surface cards are structural content inside a vertical viewport.
      // A Material -> Ink render chain is unnecessary for those cards and can
      // leave the ink feature without a size when an ancestor is rebuilding at
      // a responsive breakpoint. A decorated container has deterministic
      // constraints and still renders the exact same surface treatment.
      return Container(padding: padding, decoration: decoration, child: child);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(effectiveRadius),
        onTap: onTap,
        child: Ink(
          decoration: decoration,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
