import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_seal_badge.dart';

class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required super.child,
    required this.openDrawer,
  });

  final VoidCallback openDrawer;

  static AppShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppShellScope>();
  }

  @override
  bool updateShouldNotify(AppShellScope oldWidget) =>
      oldWidget.openDrawer != openDrawer;
}

class AppShellMenuButton extends StatelessWidget {
  const AppShellMenuButton({super.key, this.showMobileBrand = true});

  final bool showMobileBrand;

  @override
  Widget build(BuildContext context) {
    final shell = AppShellScope.maybeOf(context);
    final width = MediaQuery.sizeOf(context).width;
    if (shell == null && width < 720 && showMobileBrand) {
      return const Center(
        child: AppSealBadge(size: 30, padding: 2.5, showFrame: false),
      );
    }
    if (shell == null || width >= 1180) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Material(
        color: AppColors.surfaceFor(
          context,
        ).withValues(alpha: AppColors.isDark(context) ? 0.92 : 0.96),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.borderFor(context)),
        ),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: shell.openDrawer,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              Icons.menu_rounded,
              color: AppColors.textPrimaryFor(context),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
