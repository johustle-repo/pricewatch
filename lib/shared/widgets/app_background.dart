import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.showTopGlow = true,
  });

  final Widget child;
  final bool showTopGlow;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 560;
    final background = AppColors.backgroundFor(context);
    final primaryGlow = AppColors.primarySoft.withValues(
      alpha: AppColors.isDark(context) ? 0.13 : 0.08,
    );
    final skyGlow = AppColors.sky.withValues(
      alpha: AppColors.isDark(context) ? 0.1 : 0.06,
    );
    final bottomGlow = AppColors.primary.withValues(
      alpha: AppColors.isDark(context) ? 0.11 : 0.06,
    );

    return DecoratedBox(
      decoration: BoxDecoration(color: background),
      child: Stack(
        children: [
          if (showTopGlow) ...[
            Positioned(
              top: compact ? -80 : -100,
              right: compact ? -70 : -40,
              child: _GlowOrb(size: compact ? 180 : 220, color: primaryGlow),
            ),
            Positioned(
              top: compact ? 96 : 80,
              left: compact ? -78 : -60,
              child: _GlowOrb(size: compact ? 144 : 180, color: skyGlow),
            ),
          ],
          Positioned(
            bottom: compact ? -70 : -90,
            left: compact ? -60 : -30,
            child: _GlowOrb(size: compact ? 150 : 200, color: bottomGlow),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
