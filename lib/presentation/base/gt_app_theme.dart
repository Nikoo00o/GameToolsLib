import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/utils.dart';

//ignore_for_file: prefer_initializing_formals

/// A utility helper class to create a theme for the app.
///
/// Just pick your base material colors which will then be used to generate the [ColorScheme] of the [ThemeData].
/// For Reference: https://m3.material.io/styles/color/system/how-the-system-works#094adbe5-d41e-49b4-8dff-906d6094668d
///
/// Your custom colors in the [GTAppTheme.colors] constructor would be the tone "50" of the color palette which will
/// then use "40" for the light theme and "80" for the dark theme for primary, secondary, tertiary!
///
/// Otherwise with the [GTAppTheme.seed] constructor you can provide just one seed color from which the colors are
/// build (for example look at https://material-foundation.github.io/material-theme-builder/ )
///
/// The generated flutter theme will be provided inside of [getTheme].
final class GTAppTheme {
  /// Used for all most important key components across the UI (FAB, tint of elevated surface, etc).
  ///
  /// In addition to the color "primary", you can also access "onPrimary" for text on a primary background color. And the
  /// same pair is provided an additional time with "primaryContainer" with a different color tone for UI elements needing
  /// less emphasis.
  ///
  /// "primaryContainer" will be brighter than the "primary" color inside of a light theme and darker inside of  a dark
  /// theme. This of course also applies to the other colors as well.
  final Color basePrimaryColor;

  /// Used for less prominent components in the UI (filter chips).
  final Color? baseSecondaryColor;

  /// Used as a contrast to balance primary and secondary colors, or bring attention to an element.
  final Color? baseTertiaryColor;

  /// Used for the surface and background (mostly black, or white).
  final Color? baseNeutralColor;

  /// If this is null, then the [baseNeutralColor] will be used instead.
  final Color? baseNeutralVariantColor;

  /// Used for errors (mostly some shade of red)
  final Color? baseErrorColor;

  /// Converts the base colors to their tonal palettes
  const GTAppTheme.colors({
    required this.basePrimaryColor,
    required Color baseSecondaryColor,
    required Color baseTertiaryColor,
    required Color baseNeutralColor,
    required Color baseErrorColor,
    this.baseNeutralVariantColor,
  }) : baseSecondaryColor = baseSecondaryColor,
       baseTertiaryColor = baseTertiaryColor,
       baseNeutralColor = baseNeutralColor,
       baseErrorColor = baseErrorColor;

  /// Builds internal colors from the seed color
  const GTAppTheme.seed(Color seedColor)
    : basePrimaryColor = seedColor,
      baseSecondaryColor = null,
      baseTertiaryColor = null,
      baseNeutralColor = null,
      baseNeutralVariantColor = null,
      baseErrorColor = null;

  /// Returns the material 3 theme data for this theme with the generated [ColorScheme].
  ///
  /// Depending on [darkTheme] either a dark, or light theme will be returned!
  ThemeData getTheme({required bool darkTheme}) => ThemeData(
    colorScheme: getColorScheme(brightness: darkTheme ? Brightness.dark : Brightness.light),
    useMaterial3: true,
  );

  /// Returns the parsed [ColorScheme] from the base material colors.
  ///
  /// [brightness] can be light, or dark for light, or dark themes!
  ColorScheme getColorScheme({required Brightness brightness}) {
    final bool isDark = brightness == Brightness.dark;
    if (baseSecondaryColor == null || baseTertiaryColor == null || baseNeutralColor == null || baseErrorColor == null) {
      return ColorScheme.fromSeed(seedColor: basePrimaryColor, brightness: brightness);
    }
    final MaterialColor primary = convertColor(basePrimaryColor);
    final MaterialColor secondary = convertColor(baseSecondaryColor!);
    final MaterialColor tertiary = convertColor(baseTertiaryColor!);
    final MaterialColor neutral = convertColor(baseNeutralColor!);
    final MaterialColor neutralVariant = convertColor(baseNeutralVariantColor ?? baseNeutralColor!);
    final MaterialColor error = convertColor(baseErrorColor!);
    if (isDark) {
      return ColorScheme(
        primary: primary.mColorTone(80)!,
        onPrimary: primary.mColorTone(20)!,
        primaryContainer: primary.mColorTone(30)!,
        onPrimaryContainer: primary.mColorTone(90)!,
        secondary: secondary.mColorTone(80)!,
        onSecondary: secondary.mColorTone(20)!,
        secondaryContainer: secondary.mColorTone(30)!,
        onSecondaryContainer: secondary.mColorTone(90)!,
        tertiary: tertiary.mColorTone(80)!,
        onTertiary: tertiary.mColorTone(20)!,
        tertiaryContainer: tertiary.mColorTone(30)!,
        onTertiaryContainer: tertiary.mColorTone(90)!,
        surface: neutral.mColorTone(10)!,
        onSurface: neutral.mColorTone(90)!,
        surfaceContainerHighest: neutralVariant.mColorTone(30)!,
        onSurfaceVariant: neutralVariant.mColorTone(80)!,
        outline: neutralVariant.mColorTone(60)!,
        outlineVariant: neutralVariant.mColorTone(30)!,
        error: error.mColorTone(80)!,
        onError: error.mColorTone(20)!,
        errorContainer: error.mColorTone(30)!,
        onErrorContainer: error.mColorTone(90)!,
        shadow: neutral.mColorTone(0),
        surfaceTint: primary.mColorTone(50),
        inverseSurface: neutral.mColorTone(90),
        onInverseSurface: neutral.mColorTone(20),
        inversePrimary: primary.mColorTone(40),
        scrim: neutral.mColorTone(0),
        brightness: brightness,
      );
    } else {
      return ColorScheme(
        primary: primary.mColorTone(40)!,
        onPrimary: primary.mColorTone(100)!,
        primaryContainer: primary.mColorTone(90)!,
        onPrimaryContainer: primary.mColorTone(10)!,
        secondary: secondary.mColorTone(40)!,
        onSecondary: secondary.mColorTone(100)!,
        secondaryContainer: secondary.mColorTone(90)!,
        onSecondaryContainer: secondary.mColorTone(10)!,
        tertiary: tertiary.mColorTone(40)!,
        onTertiary: tertiary.mColorTone(100)!,
        tertiaryContainer: tertiary.mColorTone(90)!,
        onTertiaryContainer: tertiary.mColorTone(10)!,
        surface: neutral.mColorTone(99)!,
        onSurface: neutral.mColorTone(10)!,
        surfaceContainerHighest: neutralVariant.mColorTone(90)!,
        onSurfaceVariant: neutralVariant.mColorTone(30)!,
        outline: neutralVariant.mColorTone(50)!,
        outlineVariant: neutralVariant.mColorTone(80)!,
        error: error.mColorTone(40)!,
        onError: error.mColorTone(100)!,
        errorContainer: error.mColorTone(90)!,
        onErrorContainer: error.mColorTone(10)!,
        shadow: neutral.mColorTone(0),
        surfaceTint: primary.mColorTone(50),
        inverseSurface: neutral.mColorTone(20),
        onInverseSurface: neutral.mColorTone(95),
        inversePrimary: primary.mColorTone(80),
        scrim: neutral.mColorTone(0),
        brightness: brightness,
      );
    }
  }

  /// The returned material color also has [0] set to white and [1000] set to black and of course [500] set to the color
  /// itself. This also contains some additional tints and shades.
  ///
  /// [900] is the material color tone [10].
  /// [50] is the material color tone [95].
  /// [10] is the material color tone [99].
  static MaterialColor convertColor(Color color) {
    final Map<int, Color> colorMap = <int, Color>{
      0: tintColor(color, 1.0),
      10: tintColor(color, 0.98),
      50: tintColor(color, 0.9),
      100: tintColor(color, 0.8),
      200: tintColor(color, 0.6),
      300: tintColor(color, 0.4),
      400: tintColor(color, 0.2),
      500: color,
      600: shadeColor(color, 0.2),
      700: shadeColor(color, 0.4),
      800: shadeColor(color, 0.6),
      900: shadeColor(color, 0.8),
      1000: shadeColor(color, 1.0),
    };
    return MaterialColor(color.toARGB32(), colorMap);
  }

  /// Returns a color that is brighter by the percentage [factor] 0.000001 to 0.999999
  static Color tintColor(Color color, double factor) => color.tint(factor);

  /// Returns a color that is darker by the percentage [factor] 0.000001 to 0.999999
  static Color shadeColor(Color color, double factor) => color.shade(factor);

  /// Returns a color that is the [source] blended into the [target] by the percentage [factor] 0.000001 to 0.999999
  static Color blend(Color source, Color target, double factor) => source.blend(target, factor);
}

extension on MaterialColor {
  /// Returns the material color tone from 0 to 100 of this color by using the swatch shades.
  Color? mColorTone(int tone) {
    assert(tone >= 0 && tone <= 100, "color tone must be in the inclusive range of 0 to 100!");
    return this[1000 - tone * 10];
  }
}
