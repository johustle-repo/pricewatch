import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.height = 56,
    this.borderRadius = 16,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final compact = MediaQuery.sizeOf(context).width < 720;
    final effectiveHeight = compact
        ? (height - 4).clamp(48.0, 72.0).toDouble()
        : height;
    final effectiveRadius = compact
        ? (borderRadius - 4).clamp(14.0, 28.0).toDouble()
        : borderRadius;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.65,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradientFor(context),
          borderRadius: BorderRadius.circular(effectiveRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(
                alpha: AppColors.isDark(context)
                    ? (compact ? 0.18 : 0.22)
                    : (compact ? 0.12 : 0.16),
              ),
              blurRadius: compact ? 16 : 24,
              offset: Offset(0, compact ? 8 : 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(effectiveRadius),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: effectiveHeight,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
