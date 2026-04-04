import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material 3 com tokens da Direção visual v1 (verde campo + ouro, superfícies claras/escuras).
abstract final class AppTheme {
  // --- Tokens (uso opcional em widgets) ---
  static const Color primary = Color(0xFF1B7F3A);
  static const Color secondaryGold = Color(0xFFC9A227);
  static const Color surfacePage = Color(0xFFF1F5F9);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color outlineMuted = Color(0xFFE2E8F0);

  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF151D2E);
  static const Color darkSurfaceElevated = Color(0xFF1E293B);
  static const Color darkPrimary = Color(0xFF4ADE80);
  static const Color darkSecondaryGold = Color(0xFFEAB308);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: surfacePage,
    ).copyWith(
      secondary: secondaryGold,
      onSecondary: const Color(0xFF1C1917),
      secondaryContainer: const Color(0xFFFEF3C7),
      onSecondaryContainer: const Color(0xFF78350F),
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: outlineMuted,
    );

    final cardTheme = CardThemeData(
      elevation: 1,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: surfaceCard,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    );

    return _baseTheme(
      scheme: scheme,
      scaffoldBackground: surfacePage,
      cardTheme: cardTheme,
      navigationIndicator: scheme.primaryContainer,
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: darkPrimary,
      brightness: Brightness.dark,
      surface: darkSurface,
    ).copyWith(
      primary: darkPrimary,
      onPrimary: const Color(0xFF052E16),
      primaryContainer: const Color(0xFF166534),
      onPrimaryContainer: const Color(0xFFDCFCE7),
      secondary: darkSecondaryGold,
      onSecondary: const Color(0xFF1C1917),
      secondaryContainer: const Color(0xFF713F12),
      onSecondaryContainer: const Color(0xFFFEF9C3),
      surface: darkSurface,
      onSurface: const Color(0xFFF8FAFC),
      onSurfaceVariant: const Color(0xFF94A3B8),
      outline: const Color(0xFF334155),
    );

    final cardTheme = CardThemeData(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: scheme.outline.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      color: darkSurfaceElevated,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    );

    return _baseTheme(
      scheme: scheme,
      scaffoldBackground: darkBackground,
      cardTheme: cardTheme,
      navigationIndicator: scheme.primaryContainer.withValues(alpha: 0.35),
    );
  }

  static ThemeData _baseTheme({
    required ColorScheme scheme,
    required Color scaffoldBackground,
    required CardThemeData cardTheme,
    required Color navigationIndicator,
  }) {
    final baseTheme = scheme.brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    final textTheme = _editorialTextTheme(baseTheme.textTheme, scheme);
    final primaryTextTheme = GoogleFonts.interTextTheme(baseTheme.primaryTextTheme).apply(
      bodyColor: scheme.onPrimary,
      displayColor: scheme.onPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: scheme,
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
      scaffoldBackgroundColor: scaffoldBackground,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: cardTheme,
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: scheme.brightness == Brightness.dark ? 0.45 : 0.65),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: navigationIndicator,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: scheme.surface,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: navigationIndicator,
      ),
    );
  }

  /// Inter + ajustes finos de peso, entrelinha e tracking para leitura longa e títulos com “peso” editorial.
  static TextTheme _editorialTextTheme(TextTheme base, ColorScheme scheme) {
    final t = GoogleFonts.interTextTheme(base).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return t.copyWith(
      displayLarge: t.displayLarge?.copyWith(
        letterSpacing: -0.5,
        fontWeight: FontWeight.w600,
        height: 1.12,
      ),
      displayMedium: t.displayMedium?.copyWith(
        letterSpacing: -0.4,
        fontWeight: FontWeight.w600,
        height: 1.15,
      ),
      displaySmall: t.displaySmall?.copyWith(
        letterSpacing: -0.35,
        fontWeight: FontWeight.w600,
        height: 1.15,
      ),
      headlineLarge: t.headlineLarge?.copyWith(
        letterSpacing: -0.3,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      headlineMedium: t.headlineMedium?.copyWith(
        letterSpacing: -0.25,
        fontWeight: FontWeight.w600,
        height: 1.22,
      ),
      headlineSmall: t.headlineSmall?.copyWith(
        letterSpacing: -0.2,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      titleLarge: t.titleLarge?.copyWith(
        letterSpacing: -0.15,
        fontWeight: FontWeight.w600,
        height: 1.27,
      ),
      titleMedium: t.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.33,
      ),
      titleSmall: t.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.33,
      ),
      bodyLarge: t.bodyLarge?.copyWith(
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: t.bodyMedium?.copyWith(
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: t.bodySmall?.copyWith(
        height: 1.43,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: t.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: t.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      labelSmall: t.labelSmall?.copyWith(
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
