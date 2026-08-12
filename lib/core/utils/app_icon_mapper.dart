import 'package:flutter/material.dart';

class AppIconMapper {
  const AppIconMapper._();

  static IconData fromKey(String? key) {
    switch (key) {
      case 'rice':
        return Icons.grain;
      case 'eggs':
        return Icons.egg_alt;
      case 'vegetables':
        return Icons.eco;
      case 'fish':
        return Icons.set_meal;
      case 'chicken':
        return Icons.lunch_dining;
      case 'pork':
      case 'meat':
        return Icons.kebab_dining;
      case 'canned':
        return Icons.inventory_2;
      case 'lpg':
        return Icons.local_gas_station;
      case 'sugar':
        return Icons.cookie;
      case 'oil':
        return Icons.opacity;
      default:
        return Icons.shopping_basket;
    }
  }
}
