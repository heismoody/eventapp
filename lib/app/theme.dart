import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart';

ThemeData buildAppTheme(AppPalette p) {
  final dark = p.brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: p.primary,
        brightness: p.brightness,
      ).copyWith(
        primary: p.primary,
        onPrimary: AppColors.onPrimary,
        secondary: p.accent,
        surface: p.surface,
        onSurface: p.onSurface,
        onSurfaceVariant: p.muted,
        outline: p.border,
        outlineVariant: p.border,
        error: p.danger,
        surfaceContainerLowest: p.surface,
        surfaceContainerLow: p.surfaceRaised,
        surfaceContainer: p.surfaceRaised,
        surfaceContainerHigh: p.surfaceRaised,
        surfaceContainerHighest: p.surfaceRaised,
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.background,
    dividerColor: p.border,
  );

  final text = GoogleFonts.sourceSans3TextTheme(
    base.textTheme,
  ).apply(bodyColor: p.onSurface, displayColor: p.onSurface);

  return base.copyWith(
    // Source Sans 3: same family as the web portal (app/layout.tsx).
    textTheme: text.copyWith(
      headlineLarge: GoogleFonts.sourceSans3(
        fontWeight: FontWeight.w800,
        color: p.onSurface,
      ),
      headlineMedium: GoogleFonts.sourceSans3(
        fontWeight: FontWeight.w700,
        color: p.onSurface,
      ),
      titleLarge: GoogleFonts.sourceSans3(
        fontWeight: FontWeight.w700,
        color: p.onSurface,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: p.primary.withValues(alpha: 0.4),
        disabledForegroundColor: AppColors.onPrimary.withValues(alpha: 0.7),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.inputFill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: dark
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: p.border),
            )
          : null,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: p.primary, width: 2),
      ),
      labelStyle: TextStyle(color: p.muted),
      hintStyle: TextStyle(color: p.muted.withValues(alpha: 0.8)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.primary.withValues(alpha: dark ? 0.28 : 0.15),
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: p.onSurface,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: p.border,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surfaceRaised,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.surfaceRaised,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(color: p.border),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.primary),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.primary,
        side: BorderSide(color: p.border),
      ),
    ),
  );
}
