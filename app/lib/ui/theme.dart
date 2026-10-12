import 'package:flutter/material.dart';

/// Brand palette (from the QUIZtion logo).
abstract class BrandColors {
  /// Primary — violet.
  static const primary = Color(0xFF5546D9);

  /// Secondary — teal.
  static const secondary = Color(0xFF35C6B0);

  /// Dark navy — used for dark surfaces / dark theme background.
  static const dark = Color(0xFF20243A);

  /// Light background.
  static const lightBackground = Color(0xFFF7F8FC);
}

/// Builds the app's light and dark themes from the brand palette.
abstract class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: BrandColors.primary,
      primary: BrandColors.primary,
      secondary: BrandColors.secondary,
      brightness: Brightness.light,
    ).copyWith(
      // High-contrast text on light surfaces.
      surface: Colors.white,
      onSurface: BrandColors.dark,
      onSurfaceVariant: const Color(0xFF4A4E63),
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: BrandColors.lightBackground,
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: BrandColors.primary,
      primary: BrandColors.primary,
      secondary: BrandColors.secondary,
      brightness: Brightness.dark,
    ).copyWith(
      // Lighter violet primary reads better on dark surfaces.
      primary: const Color(0xFF9D93F0),
      onPrimary: BrandColors.dark,
      // Elevated surface, clearly lighter than the navy background.
      surface: const Color(0xFF2A2F4A),
      onSurface: Colors.white,
      onSurfaceVariant: const Color(0xFFC7CAD9),
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: BrandColors.dark,
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      ),
    );
  }
}
