import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color background = Color(0xFFF6F8FB);
  static const Color backgroundAlt = Color(0xFFEEF2F7);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color primary = Color(0xFF9D174D);
  static const Color primaryDark = Color(0xFF6F123A);
  static const Color primarySoft = Color(0xFFC93A74);
  static const Color warning = Color(0xFFF97316);
  static const Color warningText = Color(0xFFC2410C);
  static const Color success = Color(0xFF047857);
  static const Color info = Color(0xFF2563EB);
  static const Color danger = Color(0xFFDC2626);
  static const Color sky = Color(0xFFD38CAA);
  static const Color shadow = Color(0x1A0F172A);
  static const Color glowStrong = Color(0x289D174D);
  static const Color glowSoft = Color(0x189D174D);
  static const Color glowMedium = Color(0x1E9D174D);
  static const Color darkBackground = Color(0xFF08111F);
  static const Color darkBackgroundAlt = Color(0xFF0F1B2D);
  static const Color darkSurface = Color(0xFF142136);
  static const Color darkSurfaceMuted = Color(0xFF1D2C43);
  static const Color darkBorder = Color(0xFF33465F);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFB8C4D4);
  static const Color darkShadow = Color(0x40000000);
  static const Color darkPrimary = Color(0xFFB42363);
  static const Color darkPrimaryDeep = Color(0xFF7D1D49);
  static const Color darkPrimarySoft = Color(0xFFE06A9E);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, primarySoft],
  );

  static const LinearGradient darkPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5A1735), Color(0xFF7D1D49), Color(0xFFB42363)],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFCFDFE)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6F123A), Color(0xFF8B1745), Color(0xFFB42363)],
  );

  static const LinearGradient darkHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D172B), Color(0xFF172844), Color(0xFF243B5C)],
  );

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color backgroundFor(BuildContext context) =>
      isDark(context) ? darkBackground : background;

  static Color backgroundAltFor(BuildContext context) =>
      isDark(context) ? darkBackgroundAlt : backgroundAlt;

  static Color surfaceFor(BuildContext context) =>
      isDark(context) ? darkSurface : surface;

  static Color surfaceMutedFor(BuildContext context) =>
      isDark(context) ? darkSurfaceMuted : surfaceMuted;

  static Color borderFor(BuildContext context) =>
      isDark(context) ? darkBorder : border;

  static Color textPrimaryFor(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color textSecondaryFor(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  static Color shadowFor(BuildContext context) =>
      isDark(context) ? darkShadow : shadow;

  static LinearGradient surfaceGradientFor(BuildContext context) =>
      isDark(context)
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17263B), Color(0xFF111D2F)],
        )
      : surfaceGradient;

  static LinearGradient heroGradientFor(BuildContext context) =>
      isDark(context) ? darkHeroGradient : heroGradient;

  static LinearGradient primaryGradientFor(BuildContext context) =>
      isDark(context) ? darkPrimaryGradient : primaryGradient;
}
