import 'package:flutter/material.dart';

const String demoFontFamily = 'packages/flutter_debug_tools/DMSans';

class DemoTheme {
  static const Color canvas = Color(0xFF0D0F12);
  static const Color panel = Color(0xFF121214);
  static const Color panelRaised = Color(0xFF18191D);
  static const Color panelSoft = Color(0xFF1E2026);
  static const Color border = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color borderStrong = Color.fromRGBO(255, 255, 255, 0.14);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color.fromRGBO(255, 255, 255, 0.64);
  static const Color textMuted = Color.fromRGBO(255, 255, 255, 0.36);
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFF7A250);
  static const Color error = Color(0xFFFF6B7A);
  static const Color accent = Color(0xFFE24A79);
  static const Color accentDeep = Color(0xFF5A3386);

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF7A250), Color(0xFFE24A79), Color(0xFF5A3386)],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(38, 38, 42, 0.78), Color.fromRGBO(18, 18, 20, 0.88)],
  );

  static ThemeData theme() {
    const ColorScheme colorScheme = ColorScheme.dark(
      primary: accent,
      secondary: warning,
      tertiary: accentDeep,
      surface: panel,
      error: error,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      fontFamily: demoFontFamily,
    );

    final TextTheme textTheme = base.textTheme.copyWith(
      headlineLarge: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: textPrimary,
        fontFamily: demoFontFamily,
      ),
      headlineMedium: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: textPrimary,
        fontFamily: demoFontFamily,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: textPrimary,
        fontFamily: demoFontFamily,
      ),
      titleMedium: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: textPrimary,
        fontFamily: demoFontFamily,
      ),
      bodyLarge: const TextStyle(
        fontSize: 14,
        height: 1.5,
        color: textSecondary,
        fontFamily: demoFontFamily,
      ),
      bodyMedium: const TextStyle(
        fontSize: 12,
        height: 1.45,
        color: textSecondary,
        fontFamily: demoFontFamily,
      ),
      bodySmall: const TextStyle(
        fontSize: 10,
        height: 1.35,
        color: textMuted,
        fontFamily: demoFontFamily,
      ),
      labelLarge: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: textPrimary,
        fontFamily: demoFontFamily,
      ),
      labelSmall: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: textMuted,
        fontFamily: demoFontFamily,
      ),
    );

    final RoundedRectangleBorder rounded18 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );

    return base.copyWith(
      textTheme: textTheme,
      dividerColor: border,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: panelRaised,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardThemeData(
        color: panel,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        hintStyle: textTheme.bodyMedium,
        labelStyle: textTheme.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderStrong),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: rounded18,
          backgroundColor: accent,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: rounded18,
          side: const BorderSide(color: borderStrong),
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: borderStrong),
      ),
      switchTheme: const SwitchThemeData(
        thumbIcon: WidgetStatePropertyAll(null),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: panelRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: panelRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: textPrimary),
      ),
    );
  }
}
