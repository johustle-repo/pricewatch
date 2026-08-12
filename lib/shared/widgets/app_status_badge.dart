import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.soft = true,
    this.maxWidth = 240,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool soft;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final foreground = _accessibleForeground(context, color);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: soft
              ? color.withValues(alpha: AppColors.isDark(context) ? 0.20 : 0.11)
              : color,
          borderRadius: BorderRadius.circular(999),
          border: soft
              ? Border.all(color: color.withValues(alpha: 0.18))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: soft ? foreground : Colors.white),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: soft ? foreground : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accessibleForeground(BuildContext context, Color source) {
    // White is intentionally used for badges placed over dark hero surfaces.
    // Do not darken it based on the surrounding light application theme.
    if (source.computeLuminance() > 0.9) {
      return Colors.white;
    }
    if (AppColors.isDark(context)) {
      return source;
    }
    final hsl = HSLColor.fromColor(source);
    return hsl.withLightness(hsl.lightness.clamp(0.22, 0.38)).toColor();
  }
}
