import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFF0D1117);
  static const backgroundSoft = Color(0xFF161B22);
  static const card = Color(0xFF1C2333);
  static const elevated = Color(0xFF242D3D);
  static const primary = Color(0xFF2E7D32);
  static const primaryBright = Color(0xFF3FB950);
  static const gold = Color(0xFFFFC107);
  static const goldSoft = Color(0xFFFFD54F);
  static const accent = Color(0xFFFF6D00);
  static const textPrimary = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFF8B949E);
  static const textMuted = Color(0xFF484F58);
  static const success = Color(0xFF2EA043);
  static const danger = Color(0xFFF85149);
  static const warning = Color(0xFFD29922);
  static const info = Color(0xFF58A6FF);
  static const expert = Color(0xFFBC4DFF);
}

class AppTheme {
  static ThemeData dark() {
    final base = FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: AppColors.primary,
        primaryContainer: Color(0xFF173B20),
        secondary: AppColors.gold,
        secondaryContainer: Color(0xFF463A12),
        tertiary: AppColors.accent,
        tertiaryContainer: Color(0xFF4A2410),
        appBarColor: AppColors.background,
        error: AppColors.danger,
        errorContainer: Color(0xFF4B1D1D),
      ),
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      blendLevel: 12,
      appBarStyle: FlexAppBarStyle.background,
      useMaterial3: true,
      scaffoldBackground: AppColors.background,
    );

    final inter = GoogleFonts.interTextTheme(base.textTheme);
    final textTheme = inter.copyWith(
      displayLarge: GoogleFonts.outfit(
        textStyle: inter.displayLarge,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: GoogleFonts.outfit(
        textStyle: inter.displayMedium,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: GoogleFonts.outfit(
        textStyle: inter.headlineMedium,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: GoogleFonts.outfit(
        textStyle: inter.headlineSmall,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: GoogleFonts.outfit(
        textStyle: inter.titleLarge,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: inter.titleMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: inter.titleSmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: inter.bodyLarge?.copyWith(color: AppColors.textSecondary),
      bodyMedium: inter.bodyMedium?.copyWith(color: AppColors.textSecondary),
      bodySmall: inter.bodySmall?.copyWith(color: AppColors.textSecondary),
      labelLarge: inter.labelLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      labelMedium: inter.labelMedium?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        surface: AppColors.backgroundSoft,
        surfaceContainer: AppColors.card,
        surfaceContainerHighest: AppColors.elevated,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        primary: AppColors.primaryBright,
        secondary: AppColors.gold,
        tertiary: AppColors.accent,
        error: AppColors.danger,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.background.withValues(alpha: 0.92),
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.card.withValues(alpha: 0.82),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card.withValues(alpha: 0.82),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primaryBright, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryBright,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.elevated,
          disabledForegroundColor: AppColors.textMuted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelLarge,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 82,
        backgroundColor: AppColors.card.withValues(alpha: 0.92),
        indicatorColor: AppColors.primaryBright.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AppColors.primaryBright : AppColors.textSecondary,
          );
        }),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.card.withValues(alpha: 0.78),
        selectedColor: AppColors.primaryBright.withValues(alpha: 0.22),
        labelStyle: textTheme.labelMedium,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.elevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
