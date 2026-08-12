import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppSealBadge extends StatelessWidget {
  const AppSealBadge({
    super.key,
    this.size = 56,
    this.padding = 4,
    this.backgroundColor,
    this.showFrame = true,
  });

  final double size;
  final double padding;
  final Color? backgroundColor;
  final bool showFrame;

  @override
  Widget build(BuildContext context) {
    final useDark = AppColors.isDark(context);
    final outer =
        backgroundColor ??
        (useDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.18));

    final child = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: outer,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(
          color: useDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.24),
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.06),
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
                  return Image.asset(
                    'assets/icons/lingayen_seal.jpg',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.location_city_rounded,
                        color: AppColors.primaryDark,
                        size: size * 0.42,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );

    if (!showFrame) {
      return child;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: useDark ? 0.18 : 0.12),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.09),
          ),
        ],
      ),
      child: child,
    );
  }
}
