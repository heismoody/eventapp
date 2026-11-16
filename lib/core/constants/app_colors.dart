import 'package:flutter/material.dart';

/// One set of the app's colors. The values mirror the web portal's CSS
/// variables (eventsys/app/globals.css: `:root` and `:root.dark`), so the
/// app and the portal read as the same product in both themes.
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.secondary,
    required this.secondaryAlt,
    required this.success,
    required this.warning,
    required this.danger,
    required this.background,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.onSurface,
    required this.muted,
    required this.border,
    required this.inputFill,
    required this.chipFill,
    required this.chartSeries,
  });

  final Brightness brightness;

  /// Brand fills and brand text. White text on it is fine in both themes.
  final Color primary;
  final Color primaryDark;
  final Color accent;

  /// Subtle fills and hovers.
  final Color secondary;
  final Color secondaryAlt;

  final Color success;
  final Color warning;
  final Color danger;

  /// Behind the sign-in and request screens.
  final Color background;

  /// Behind the screens inside the app (dashboard, guests, settings…).
  final Color canvas;

  /// Cards, panels, list sections. Never hard-code white for these.
  final Color surface;

  /// Sheets, dialogs, menus: lighter than [surface] in dark, so elevation
  /// shows by lightness rather than shadow.
  final Color surfaceRaised;

  /// Text.
  final Color onSurface;
  final Color muted;
  final Color border;
  final Color inputFill;

  /// Neutral fill for small buttons and chips on a card.
  final Color chipFill;

  /// Category colors for charts, cycled in order.
  final List<Color> chartSeries;

  static const light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF541E06),
    primaryDark: Color(0xFF331302),
    accent: Color(0xFF8A4A1F),
    secondary: Color(0xFFF6EFE8),
    secondaryAlt: Color(0xFFECDFD2),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    background: Color(0xFFF6EFE8),
    canvas: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1C1108),
    muted: Color(0xFF7C6A5C),
    border: Color(0xFFE3D7C9),
    inputFill: Color(0xFFF0F0F0),
    chipFill: Color(0xFFF1F5F9),
    chartSeries: [
      Color(0xFF541E06),
      Color(0xFF8A4A1F),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF6366F1),
      Color(0xFFEC4899),
      Color(0xFFEF4444),
      Color(0xFF0EA5E9),
    ],
  );

  /// The portal's "roasted" dark theme.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFFB4612F),
    primaryDark: Color(0xFF94491F),
    accent: Color(0xFFD48C5A),
    secondary: Color(0xFF100D0B),
    secondaryAlt: Color(0xFF221C18),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    background: Color(0xFF0A0807),
    canvas: Color(0xFF0A0807),
    surface: Color(0xFF131010),
    surfaceRaised: Color(0xFF1C1816),
    onSurface: Color(0xFFF2E8DE),
    muted: Color(0xFFA8968A),
    border: Color(0xFF2A221D),
    inputFill: Color(0xFF1C1816),
    chipFill: Color(0xFF221C18),
    // Lighter steps of the same hues, so slices read on the dark surface.
    chartSeries: [
      Color(0xFFB4612F),
      Color(0xFFD48C5A),
      Color(0xFF34D399),
      Color(0xFFFBBF24),
      Color(0xFF818CF8),
      Color(0xFFF472B6),
      Color(0xFFF87171),
      Color(0xFF38BDF8),
    ],
  );
}

/// The colors in use right now. EventApp switches the palette when the
/// theme changes and rebuilds every widget, so screens can keep reading
/// `AppColors.muted` without a BuildContext.
class AppColors {
  AppColors._();

  static AppPalette _palette = AppPalette.light;

  static AppPalette get palette => _palette;
  static bool get isDark => _palette.brightness == Brightness.dark;

  /// Returns true when the palette actually changed.
  static bool use(AppPalette palette) {
    if (identical(palette, _palette)) return false;
    _palette = palette;
    return true;
  }

  static Color get primary => _palette.primary;
  static Color get primaryDark => _palette.primaryDark;
  static Color get accent => _palette.accent;
  static Color get secondary => _palette.secondary;
  static Color get secondaryAlt => _palette.secondaryAlt;
  static Color get success => _palette.success;
  static Color get warning => _palette.warning;
  static Color get danger => _palette.danger;
  static Color get background => _palette.background;
  static Color get canvas => _palette.canvas;
  static Color get surface => _palette.surface;
  static Color get surfaceRaised => _palette.surfaceRaised;
  static Color get onSurface => _palette.onSurface;
  static Color get muted => _palette.muted;
  static Color get border => _palette.border;
  static Color get inputFill => _palette.inputFill;
  static Color get chipFill => _palette.chipFill;
  static List<Color> get chartSeries => _palette.chartSeries;

  // The same in both themes.

  /// Text and icons on a brand fill or over a photo.
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Shadows (used at low opacity).
  static const Color shadow = Color(0xFF000000);

  /// Dimming behind overlays and the camera viewfinder.
  static const Color scrim = Color(0xFF000000);

  /// The DEV corner ribbon on test builds.
  static const Color devRibbon = Color(0xFFF57C00);
}

/// Brand colors that stay the same in both themes: the welcome photo's
/// overlay and anything else that must always look like the Cardly brand.
class BrandColors {
  BrandColors._();

  static const Color brown = Color(0xFF541E06);
  static const Color brownDark = Color(0xFF331302);
  static const Color copper = Color(0xFF8A4A1F);
}
