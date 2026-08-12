import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_icon_mapper.dart';

class CommodityVisual extends StatelessWidget {
  const CommodityVisual({
    super.key,
    required this.label,
    this.category,
    this.size = 60,
    this.heroTag,
    this.useIllustration = true,
  });

  final String label;
  final String? category;
  final double size;
  final String? heroTag;
  final bool useIllustration;

  @override
  Widget build(BuildContext context) {
    final useDark = AppColors.isDark(context);
    final asset = _CommodityVisualMapper.assetFor(label, category: category);
    final fallbackIcon = _CommodityVisualMapper.fallbackIconFor(
      label,
      category: category,
    );
    final background = _CommodityVisualMapper.backgroundFor(
      label,
      category: category,
    );

    final visual = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: useDark ? background.withValues(alpha: 0.9) : background,
        borderRadius: BorderRadius.circular(size * 0.34),
        border: Border.all(
          color: useDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowFor(context).withValues(alpha: 0.12),
            blurRadius: size * 0.12,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: !useIllustration || asset == null
          ? Icon(
              fallbackIcon,
              color: useDark
                  ? AppColors.darkPrimaryDeep
                  : AppColors.primaryDark,
              size: size * 0.64,
            )
          : SvgPicture.asset(asset, fit: BoxFit.contain),
    );

    if (heroTag == null) {
      return visual;
    }
    return Hero(tag: heroTag!, child: visual);
  }
}

class _CommodityVisualMapper {
  const _CommodityVisualMapper._();

  static String? assetFor(String label, {String? category}) {
    final key = _normalizedKey(label, category: category);
    switch (key) {
      case 'rice':
        return 'assets/images/products/rice.svg';
      case 'eggs':
        return 'assets/images/products/eggs.svg';
      case 'fish':
        return 'assets/images/products/fish.svg';
      case 'chicken':
        return 'assets/images/products/chicken.svg';
      case 'pork':
        return 'assets/images/products/pork.svg';
      case 'vegetables':
        return 'assets/images/products/vegetables.svg';
      case 'sugar':
        return 'assets/images/products/sugar.svg';
      case 'oil':
        return 'assets/images/products/oil.svg';
      case 'canned':
        return 'assets/images/products/canned_goods.svg';
      case 'lpg':
        return 'assets/images/products/lpg.svg';
      default:
        return null;
    }
  }

  static IconData fallbackIconFor(String label, {String? category}) {
    final key = _normalizedKey(label, category: category);
    switch (key) {
      case 'rice':
        return Icons.rice_bowl_outlined;
      case 'eggs':
        return Icons.egg_outlined;
      case 'fish':
        return Icons.set_meal_outlined;
      case 'chicken':
        return Icons.restaurant_outlined;
      case 'beef':
        return Icons.kebab_dining_outlined;
      case 'pork':
        return Icons.lunch_dining_outlined;
      case 'vegetables':
        return Icons.eco_outlined;
      default:
        return AppIconMapper.fromKey(key);
    }
  }

  static Color backgroundFor(String label, {String? category}) {
    final key = _normalizedKey(label, category: category);
    switch (key) {
      case 'rice':
        return const Color(0xFFFFF3C9);
      case 'eggs':
        return const Color(0xFFFFE7C7);
      case 'fish':
        return const Color(0xFFCFEFFF);
      case 'chicken':
        return const Color(0xFFFFD9D9);
      case 'pork':
        return const Color(0xFFFFD7E7);
      case 'vegetables':
        return const Color(0xFFFFD9EF);
      case 'sugar':
        return const Color(0xFFE8ECF3);
      case 'oil':
        return const Color(0xFFFFEEA8);
      case 'canned':
        return const Color(0xFFDCEEFF);
      case 'lpg':
        return const Color(0xFFDDE3FF);
      default:
        return const Color(0xFFE7ECF4);
    }
  }

  static String _normalizedKey(String label, {String? category}) {
    final source = '${category ?? ''} ${label.toLowerCase()}';
    if (source.contains('rice')) {
      return 'rice';
    }
    if (source.contains('egg')) {
      return 'eggs';
    }
    if (source.contains('fish') ||
        source.contains('tilapia') ||
        source.contains('bangus') ||
        source.contains('galunggong')) {
      return 'fish';
    }
    if (source.contains('chicken')) {
      return 'chicken';
    }
    if (source.contains('beef')) {
      return 'beef';
    }
    if (source.contains('pork') || source.contains('meat')) {
      return 'pork';
    }
    if (source.contains('vegetable') ||
        source.contains('tomato') ||
        source.contains('onion') ||
        source.contains('potato')) {
      return 'vegetables';
    }
    if (source.contains('sugar')) {
      return 'sugar';
    }
    if (source.contains('oil')) {
      return 'oil';
    }
    if (source.contains('lpg')) {
      return 'lpg';
    }
    if (source.contains('sardine') ||
        source.contains('tuna') ||
        source.contains('corned') ||
        source.contains('canned')) {
      return 'canned';
    }
    return category?.toLowerCase() ?? 'canned';
  }
}
