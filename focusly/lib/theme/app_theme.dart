// ─────────────────────────────────────────────────────────────────────────────
// Focusly App Theme — Deep Purple & Gold, in light and dark.
//
// Every screen reads colours through AppColors, which now resolves against a
// swappable AppPalette instead of being compile-time constants. That is what
// makes a theme switch possible without rebuilding the widget tree by hand.
//
// Consequence: AppColors members are no longer `const`, so expressions that
// use them cannot be `const` either.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One complete set of colours. Two instances exist: [AppPalette.dark] and
/// [AppPalette.light].
class AppPalette {
  final Brightness brightness;

  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color gold;
  final Color goldLight;

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceHighlight;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// The Home header keeps its deep purple gradient in BOTH themes, so text
  /// drawn on it must stay light. Using textPrimary there would put near-black
  /// text on a dark purple band in light mode.
  final Color headerText;
  final Color headerTextMuted;

  final LinearGradient headerGradient;
  final LinearGradient goldGradient;

  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.gold,
    required this.goldLight,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceHighlight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.headerText,
    required this.headerTextMuted,
    required this.headerGradient,
    required this.goldGradient,
  });

  bool get isDark => brightness == Brightness.dark;

  static const LinearGradient _headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B1D8A), Color(0xFF1A0D4A)],
  );

  static const LinearGradient _goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF7C3AED),
    primaryLight: Color(0xFF9F67FF),
    primaryDark: Color(0xFF5B21B6),
    gold: Color(0xFFF59E0B),
    goldLight: Color(0xFFFBBF24),
    background: Color(0xFF0D0820),
    surface: Color(0xFF1A1235),
    surfaceElevated: Color(0xFF251B4B),
    surfaceHighlight: Color(0xFF2E2260),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB8A9E3),
    textMuted: Color(0xFF7B6BAD),
    headerText: Color(0xFFFFFFFF),
    headerTextMuted: Color(0xFFB8A9E3),
    headerGradient: _headerGradient,
    goldGradient: _goldGradient,
  );

  /// Light mode keeps the brand purple but darkens the gold: #F59E0B on white
  /// fails contrast for anything text-sized.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF6D28D9),
    primaryLight: Color(0xFF8B5CF6),
    primaryDark: Color(0xFF4C1D95),
    gold: Color(0xFFB45309),
    goldLight: Color(0xFFD97706),
    background: Color(0xFFF7F5FC),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF1EDFA),
    surfaceHighlight: Color(0xFFE2D9F5),
    textPrimary: Color(0xFF1A1235),
    textSecondary: Color(0xFF574B7A),
    textMuted: Color(0xFF8B7FAE),
    headerText: Color(0xFFFFFFFF),
    headerTextMuted: Color(0xFFD6CCF2),
    headerGradient: _headerGradient,
    goldGradient: _goldGradient,
  );
}

/// Global colour accessor. Kept as a class of statics so the 469 existing call
/// sites did not all have to change shape — only the palette behind them moves.
class AppColors {
  static AppPalette _current = AppPalette.dark;

  static AppPalette get current => _current;
  static bool get isDark => _current.isDark;

  /// Swap the palette. Call before rebuilding the app.
  static void apply(AppPalette p) => _current = p;

  static Color get primary => _current.primary;
  static Color get primaryLight => _current.primaryLight;
  static Color get primaryDark => _current.primaryDark;
  static Color get gold => _current.gold;
  static Color get goldLight => _current.goldLight;

  static Color get background => _current.background;
  static Color get surface => _current.surface;
  static Color get surfaceElevated => _current.surfaceElevated;
  static Color get surfaceHighlight => _current.surfaceHighlight;

  static Color get textPrimary => _current.textPrimary;
  static Color get textSecondary => _current.textSecondary;
  static Color get textMuted => _current.textMuted;

  static Color get headerText => _current.headerText;
  static Color get headerTextMuted => _current.headerTextMuted;

  static LinearGradient get headerGradient => _current.headerGradient;
  static LinearGradient get goldGradient => _current.goldGradient;

  // Semantic colours stay fixed across themes: red must read as "overdue" in
  // both, and recolouring priority would change what the app is telling you.
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF10B981);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  /// Habit & project colour choices — user data, so identical in both themes.
  static const List<Color> palette = [
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFFDC2626),
    Color(0xFFD97706),
    Color(0xFFDB2777),
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFF65A30D),
    Color(0xFF9333EA),
  ];
}

class AppTheme {
  static ThemeData get darkTheme => themeFor(AppPalette.dark);
  static ThemeData get lightTheme => themeFor(AppPalette.light);

  static ThemeData themeFor(AppPalette p) {
    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      scaffoldBackgroundColor: p.background,
      colorScheme: ColorScheme(
        brightness: p.brightness,
        primary: p.primary,
        secondary: p.gold,
        surface: p.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: p.textPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        TextTheme(
          displayLarge: TextStyle(color: p.textPrimary, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: p.textPrimary, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(color: p.textSecondary),
          bodyLarge: TextStyle(color: p.textPrimary),
          bodyMedium: TextStyle(color: p.textSecondary),
          bodySmall: TextStyle(color: p.textMuted),
          labelLarge: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: p.textPrimary),
        titleTextStyle: TextStyle(
          color: p.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.gold,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.surfaceHighlight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.surfaceHighlight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
        labelStyle: TextStyle(color: p.textSecondary),
        hintStyle: TextStyle(color: p.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.primary.withOpacity(0.3),
        labelStyle: TextStyle(color: p.textSecondary, fontSize: 12),
        side: BorderSide(color: p.surfaceHighlight),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.gold,
        unselectedItemColor: p.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: p.surfaceHighlight,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.gold;
          return p.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.gold.withOpacity(0.4);
          return p.surfaceHighlight;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: p.textMuted, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}
