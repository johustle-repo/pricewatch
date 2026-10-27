import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the viewer's light/dark preference and remembers it on the device.
class ThemeController extends ChangeNotifier {
  ThemeController({ThemeMode initialMode = ThemeMode.system})
    : _mode = initialMode;

  static const String _preferenceKey = 'theme_mode';

  ThemeMode _mode;
  ThemeMode get mode => _mode;

  /// Reads the saved preference; falls back to following the system.
  static Future<ThemeController> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(_preferenceKey);
      return ThemeController(
        initialMode: ThemeMode.values.firstWhere(
          (mode) => mode.name == saved,
          orElse: () => ThemeMode.system,
        ),
      );
    } catch (_) {
      return ThemeController();
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_preferenceKey, mode.name);
    } catch (_) {
      // The choice still applies for this session.
    }
  }

  /// Switches between light and dark, resolving "system" to whichever
  /// brightness is currently showing.
  Future<void> toggle(Brightness current) =>
      setMode(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
}
