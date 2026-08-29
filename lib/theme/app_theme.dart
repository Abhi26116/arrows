import 'package:flutter/material.dart';

import 'theme_controller.dart';

/// Dynamic colors from the active [ThemeController] palette.
class AppColors {
  static Color get bgTop => ThemeController.instance.palette.bgTop;
  static Color get bgMid => ThemeController.instance.palette.bgMid;
  static Color get bgBottom => ThemeController.instance.palette.bgBottom;
  static Color get surface => ThemeController.instance.palette.surface;
  static Color get surfaceHigh => ThemeController.instance.palette.surfaceHigh;
  static Color get ink => ThemeController.instance.palette.ink;
  static Color get muted => ThemeController.instance.palette.muted;
  static Color get accent => ThemeController.instance.palette.accent;
  static Color get accentSoft => ThemeController.instance.palette.accentSoft;
  static Color get success => ThemeController.instance.palette.success;
  static Color get danger => ThemeController.instance.palette.danger;
  static Color get gridLine => ThemeController.instance.palette.gridLine;
  static List<Color> get arrowPalette =>
      ThemeController.instance.palette.arrowPalette;
  static Color get arrowLine => ThemeController.instance.palette.arrowLine;
}

class AppTheme {
  static ThemeData get dark {
    final p = ThemeController.instance.palette;
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: p.bgTop,
      colorScheme: ColorScheme.dark(
        primary: p.accent,
        secondary: p.success,
        surface: p.surface,
        onPrimary: Colors.white,
        onSurface: p.ink,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: 'DMSans',
        bodyColor: p.ink,
        displayColor: p.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'DMSans',
          fontVariations: const [FontVariation('wght', 700)],
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: p.ink,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : p.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.accent
              : p.surfaceHigh.withOpacity(0.6),
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : p.surfaceHigh,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
              fontFamily: 'DMSans',
              fontVariations: [FontVariation('wght', 700)], fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}
