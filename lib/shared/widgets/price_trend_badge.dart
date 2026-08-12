import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PriceTrendBadge extends StatelessWidget {
  const PriceTrendBadge({
    super.key,
    required this.delta,
    this.label,
    this.maxWidth = 240,
  });

  final double delta;
  final String? label;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final isUp = delta >= 0;
    final useDark = AppColors.isDark(context);
    final color = isUp
        ? AppColors.warning
        : (useDark ? AppColors.darkPrimarySoft : AppColors.primaryDark);
    final background = color.withValues(alpha: useDark ? 0.18 : 0.12);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUp ? Icons.north_east_rounded : Icons.south_east_rounded,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label ?? (isUp ? 'Above SRP' : 'Below SRP'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
