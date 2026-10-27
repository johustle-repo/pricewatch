import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_icon_mapper.dart';

/// Icon and accent color for a commodity category, shared by the buyer's
/// home and price screens so each category looks the same everywhere.
class CategoryStyle {
  const CategoryStyle._();

  static const Map<String, Color> _colors = {
    'rice': Color(0xFFB7791F),
    'eggs': Color(0xFFDD6B20),
    'vegetables': Color(0xFF2F855A),
    'fish': Color(0xFF2B6CB0),
    'meat': Color(0xFFC53030),
  };

  static IconData icon(String? key) => AppIconMapper.fromKey(key);

  /// Readable in both themes.
  static Color color(BuildContext context, String? key) =>
      AppColors.readableFor(
        context,
        _colors[(key ?? '').trim().toLowerCase()] ?? AppColors.primary,
      );
}

/// Rounded square holding a category icon on a soft tint of its color.
class CategoryIconBadge extends StatelessWidget {
  const CategoryIconBadge({super.key, required this.iconKey, this.size = 44});

  final String? iconKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = CategoryStyle.color(context, iconKey);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(CategoryStyle.icon(iconKey), color: color, size: size * 0.5),
    );
  }
}
