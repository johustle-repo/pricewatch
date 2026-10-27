import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/market_prices.dart';

/// Shows how current a commodity's price is: not yet recorded, stale, or
/// when it was last updated and by how many stores.
class PriceFreshnessChip extends StatelessWidget {
  const PriceFreshnessChip({
    super.key,
    required this.recordedAt,
    this.storeCount = 0,
  });

  /// ISO timestamp of the newest price, or empty when none is recorded.
  final String recordedAt;
  final int storeCount;

  @override
  Widget build(BuildContext context) {
    final hasPrice = recordedAt.isNotEmpty;
    final stale = hasPrice && isStalePrice(recordedAt);
    final stores = storeCount == 1 ? '1 store' : '$storeCount stores';
    final (icon, label, color) = !hasPrice
        ? (
            Icons.hourglass_empty_rounded,
            'No price yet',
            AppColors.textSecondaryFor(context),
          )
        : stale
        ? (
            Icons.history_rounded,
            'Stale · ${AppFormatters.date(recordedAt)}',
            AppColors.isDark(context)
                ? AppColors.warning
                : AppColors.warningText,
          )
        : (
            Icons.schedule_rounded,
            storeCount > 0
                ? '${AppFormatters.date(recordedAt)} · $stores'
                : AppFormatters.date(recordedAt),
            AppColors.textSecondaryFor(context),
          );

    return Tooltip(
      message: !hasPrice
          ? 'No store has recorded a price for this item yet.'
          : stale
          ? 'The newest price is more than ${stalePriceAge.inDays} days old.'
          : 'Latest price update',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
