import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';

/// App-bar button for choosing the light, dark or system theme.
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key, this.color});

  /// Icon color for use on colored headers; defaults to the app bar color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Theme',
      initialValue: controller.mode,
      onSelected: controller.setMode,
      icon: Icon(
        isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
        color: color,
      ),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ThemeMode.light,
          child: _ThemeOption(icon: Icons.light_mode_outlined, label: 'Light'),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: _ThemeOption(icon: Icons.dark_mode_outlined, label: 'Dark'),
        ),
        PopupMenuItem(
          value: ThemeMode.system,
          child: _ThemeOption(
            icon: Icons.brightness_auto_outlined,
            label: 'Match device',
          ),
        ),
      ],
    );
  }
}

/// Segmented Light / Dark / Device picker for settings screens.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    return SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode_outlined),
          label: Text('Light'),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode_outlined),
          label: Text('Dark'),
        ),
        ButtonSegment(
          value: ThemeMode.system,
          icon: Icon(Icons.brightness_auto_outlined),
          label: Text('Device'),
        ),
      ],
      selected: {controller.mode},
      onSelectionChanged: (selection) => controller.setMode(selection.first),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [Icon(icon, size: 20), const SizedBox(width: 12), Text(label)],
  );
}
