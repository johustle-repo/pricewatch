import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pricewatch_apk/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('follows the device until the viewer chooses a theme', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = await ThemeController.load();
    expect(controller.mode, ThemeMode.system);
  });

  test('remembers the chosen theme', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = await ThemeController.load();
    await controller.setMode(ThemeMode.dark);

    final reloaded = await ThemeController.load();
    expect(reloaded.mode, ThemeMode.dark);
  });

  test('toggle switches away from the brightness on screen', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = await ThemeController.load();
    await controller.toggle(Brightness.light);
    expect(controller.mode, ThemeMode.dark);
    await controller.toggle(Brightness.dark);
    expect(controller.mode, ThemeMode.light);
  });
}
