import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/enums/gt_contrast.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/presentation/base/gt_app_theme_extension.dart';

//ignore_for_file: prefer_initializing_formals

/// A utility helper class to create a theme for the app.
///
/// Just pick your base material colors which will then be used to generate the [ColorScheme] of the [ThemeData].
/// For Reference: https://m3.material.io/styles/color/system/how-the-system-works#094adbe5-d41e-49b4-8dff-906d6094668d
///
/// For example use split complementary colors (primary and secondary on one side) from https://color.adobe.com/de/create/color-wheel
/// and adjust them a bit to your liking afterwards with the custom mode.
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

  /// A slightly different shade of the [baseNeutralColor] for more background options.
  /// If this is null, then the [baseNeutralColor] will be used instead blended by 5% to the [basePrimaryColor]!
  final Color? baseNeutralVariantColor;

  /// Used for errors (mostly some shade of red)
  final Color? baseErrorColor;

  /// Used to display some success status in the app (most of the time this would be [Colors.green] except for when
  /// the theme itself is green! See [GTAppThemeExtension.success]
  final Color baseSuccessColor;

  /// Converts the base colors to their tonal palettes
  const GTAppTheme.colors({
    required this.basePrimaryColor,
    required Color baseSecondaryColor,
    required Color baseTertiaryColor,
    required Color baseNeutralColor,
    required Color baseErrorColor,
    this.baseNeutralVariantColor,
    required this.baseSuccessColor,
  }) : baseSecondaryColor = baseSecondaryColor,
       baseTertiaryColor = baseTertiaryColor,
       baseNeutralColor = baseNeutralColor,
       baseErrorColor = baseErrorColor;

  /// Builds internal colors from the seed color
  const GTAppTheme.seed({required Color seedColor, required this.baseSuccessColor})
    : basePrimaryColor = seedColor,
      baseSecondaryColor = null,
      baseTertiaryColor = null,
      baseNeutralColor = null,
      baseNeutralVariantColor = null,
      baseErrorColor = null;

  /// Returns the material 3 theme data for this theme with the generated [ColorScheme].
  ///
  /// Depending on [darkTheme] either a dark, or light theme will be returned!
  ThemeData getTheme({required bool darkTheme, required GTContrast contrast}) {
    final MaterialColor success = convertColor(baseSuccessColor);
    final List<int> tone = _defaultTone(contrast: contrast, isDarkTheme: darkTheme);
    final List<int> fTone = _fixedTone(contrast: contrast, isDarkTheme: darkTheme);

    final GTAppThemeExtension extension = GTAppThemeExtension(
      success: _transform(success, tone),
      onSuccess: _transform(success, tone),
      successContainer: _transform(success, tone),
      onSuccessContainer: _transform(success, tone),
      successFixed: _transform(success, fTone),
      onSuccessFixed: _transform(success, fTone),
      successFixedDim: _transform(success, fTone),
      onSuccessFixedVariant: _transform(success, fTone),
    );
    return ThemeData(
      colorScheme: getColorScheme(darkTheme: darkTheme, contrast: contrast),
      useMaterial3: true,
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all<bool>(true),
      ),
      extensions: <ThemeExtension<dynamic>>[extension],
    );
  }

  /// Returns the parsed [ColorScheme] from the base material colors.
  ///
  /// [brightness] can be light, or dark for light, or dark themes!
  ColorScheme getColorScheme({required bool darkTheme, required GTContrast contrast}) {
    final Brightness brightness = darkTheme ? Brightness.dark : Brightness.light;
    if (baseSecondaryColor == null || baseTertiaryColor == null || baseNeutralColor == null || baseErrorColor == null) {
      return ColorScheme.fromSeed(seedColor: basePrimaryColor, brightness: brightness);
    }
    final MaterialColor primary = convertColor(basePrimaryColor);
    final MaterialColor secondary = convertColor(baseSecondaryColor!);
    final MaterialColor tertiary = convertColor(baseTertiaryColor!);
    final MaterialColor neutral = convertColor(baseNeutralColor!);
    final MaterialColor neutralVariant = convertColor(
      baseNeutralVariantColor ?? baseNeutralColor!.blend(basePrimaryColor, 0.05),
    );
    final MaterialColor error = convertColor(baseErrorColor!);
    final List<int> tone = _defaultTone(contrast: contrast, isDarkTheme: darkTheme);
    final List<int> nTone = _neutralColors(contrast: contrast, isDarkTheme: darkTheme);
    final List<int> vTone = _neutralVariantColors(contrast: contrast, isDarkTheme: darkTheme);
    final List<int> fTone = _fixedTone(contrast: contrast, isDarkTheme: darkTheme);
    final List<int> inverse = _inversePrimColors(contrast: contrast, isDarkTheme: darkTheme);
    int nc = 0;
    int vc = 0;

    return ColorScheme(
      primary: _transform(primary, tone),
      onPrimary: _transform(primary, tone),
      primaryContainer: _transform(primary, tone),
      onPrimaryContainer: _transform(primary, tone),
      secondary: _transform(secondary, tone),
      onSecondary: _transform(secondary, tone),
      secondaryContainer: _transform(secondary, tone),
      onSecondaryContainer: _transform(secondary, tone),
      tertiary: _transform(tertiary, tone),
      onTertiary: _transform(tertiary, tone),
      tertiaryContainer: _transform(tertiary, tone),
      onTertiaryContainer: _transform(tertiary, tone),
      error: _transform(error, tone),
      onError: _transform(error, tone),
      errorContainer: _transform(error, tone),
      onErrorContainer: _transform(error, tone),
      surface: neutral.mColorTone(nTone[nc++])!,
      onSurface: neutral.mColorTone(nTone[nc++])!,
      surfaceContainerHighest: neutral.mColorTone(nTone[nc++])!,
      surfaceContainerHigh: neutral.mColorTone(nTone[nc++])!,
      surfaceContainer: neutral.mColorTone(nTone[nc++])!,
      surfaceContainerLow: neutral.mColorTone(nTone[nc++])!,
      surfaceContainerLowest: neutral.mColorTone(nTone[nc++])!,
      inverseSurface: neutral.mColorTone(nTone[nc++])!,
      onInverseSurface: neutral.mColorTone(nTone[nc++])!,
      surfaceVariant: neutralVariant.mColorTone(vTone[vc++])!,
      onSurfaceVariant: neutralVariant.mColorTone(vTone[vc++])!,
      outline: neutralVariant.mColorTone(vTone[vc++])!,
      outlineVariant: neutralVariant.mColorTone(vTone[vc++])!,
      shadow: neutral.mColorTone(0),
      scrim: neutral.mColorTone(0),
      inversePrimary: primary.mColorTone(inverse[0]),
      surfaceTint: primary.mColorTone(inverse[1]),
      surfaceDim: neutral.mColorTone(darkTheme ? 6 : 87),
      surfaceBright: neutral.mColorTone(darkTheme ? 24 : 98),
      primaryFixed: _transform(primary, fTone),
      onPrimaryFixed: _transform(primary, fTone),
      primaryFixedDim: _transform(primary, fTone),
      onPrimaryFixedVariant: _transform(primary, fTone),
      secondaryFixed: _transform(secondary, fTone),
      onSecondaryFixed: _transform(secondary, fTone),
      secondaryFixedDim: _transform(secondary, fTone),
      onSecondaryFixedVariant: _transform(secondary, fTone),
      tertiaryFixed: _transform(tertiary, fTone),
      onTertiaryFixed: _transform(tertiary, fTone),
      tertiaryFixedDim: _transform(tertiary, fTone),
      onTertiaryFixedVariant: _transform(tertiary, fTone),
      brightness: brightness,
    );
  }

  /// can be used in order to easily transform colors into their tones by incrementing an internal counter through
  /// the tones! It will produce the order: default, onDefault, container, onContainer
  static Color _transform(MaterialColor color, List<int> tone) =>
      color.mColorTone(tone[(_transformCounter++) % 4]) ?? color;

  static int _transformCounter = 0;

  /// Returns the 4 color tones for the default version, "onDefault" version, "container" version and "onContainer"
  /// [highOrMediumContrast] true means high contrast, false means medium contrast and null means default contrast.
  static List<int> _defaultTone({required GTContrast contrast, required bool isDarkTheme}) {
    if (isDarkTheme) {
      return switch (contrast) {
        GTContrast.DEFAULT => <int>[80, 20, 30, 90],
        GTContrast.MEDIUM => <int>[90, 10, 60, 0],
        GTContrast.HIGH => <int>[95, 0, 80, 0],
      };
    } else {
      return switch (contrast) {
        GTContrast.DEFAULT => <int>[40, 100, 90, 30],
        GTContrast.MEDIUM => <int>[30, 100, 40, 100],
        GTContrast.HIGH => <int>[20, 100, 30, 100],
      };
    }
  }

  /// the 4 default color tones for the fixed versions of [_defaultTone]: fixed, onFixed, fixedDim, onFixedVariant
  static List<int> _fixedTone({required GTContrast contrast, required bool isDarkTheme}) {
    if (isDarkTheme) {
      return switch (contrast) {
        GTContrast.DEFAULT => <int>[90, 10, 80, 30],
        GTContrast.MEDIUM => <int>[90, 0, 80, 20],
        GTContrast.HIGH => <int>[90, 0, 80, 0],
      };
    } else {
      return switch (contrast) {
        GTContrast.DEFAULT => <int>[90, 10, 80, 30],
        GTContrast.MEDIUM => <int>[40, 100, 30, 100],
        GTContrast.HIGH => <int>[30, 100, 20, 100],
      };
    }
  }

  /// inversePrimary, surfaceTint
  static List<int> _inversePrimColors({required GTContrast contrast, required bool isDarkTheme}) {
    if (isDarkTheme) {
      return switch (contrast) {
        GTContrast.DEFAULT => <int>[40, 80],
        GTContrast.MEDIUM => <int>[30, 90],
        GTContrast.HIGH => <int>[20, 95],
      };
    } else {
      return switch (contrast) {
        GTContrast.DEFAULT => <int>[80, 40],
        GTContrast.MEDIUM => <int>[80, 30],
        GTContrast.HIGH => <int>[80, 20],
      };
    }
  }

  /// surface, onSurface, surfaceContainerHighest, surfaceContainerHigh, surfaceContainer, surfaceContainerLow,
  /// surfaceContainerLowest, inverseSurface, inverseOnSurface,
  static List<int> _neutralColors({required GTContrast contrast, required bool isDarkTheme}) {
    if (isDarkTheme) {
      return switch (contrast) {
        GTContrast.DEFAULT => <int>[6, 90, 22, 17, 12, 10, 4, 90, 20],
        GTContrast.MEDIUM => <int>[6, 100, 22, 17, 12, 10, 4, 90, 10],
        GTContrast.HIGH => <int>[6, 100, 22, 17, 12, 10, 4, 90, 0],
      };
    } else {
      return switch (contrast) {
        GTContrast.DEFAULT => <int>[98, 10, 90, 92, 94, 96, 100, 20, 95],
        GTContrast.MEDIUM => <int>[98, 0, 90, 92, 94, 96, 100, 20, 100],
        GTContrast.HIGH => <int>[98, 0, 90, 92, 94, 96, 100, 20, 100],
      };
    }
  }

  /// surfaceVariant, onSurfaceVariant, outline, outlineVariant
  static List<int> _neutralVariantColors({required GTContrast contrast, required bool isDarkTheme}) {
    if (isDarkTheme) {
      return switch (contrast) {
        GTContrast.DEFAULT => <int>[30, 80, 60, 30],
        GTContrast.MEDIUM => <int>[90, 10, 60, 0],
        GTContrast.HIGH => <int>[95, 0, 80, 0],
      };
    } else {
      return switch (contrast) {
        GTContrast.DEFAULT => <int>[40, 100, 90, 30],
        GTContrast.MEDIUM => <int>[30, 100, 40, 100],
        GTContrast.HIGH => <int>[20, 100, 30, 100],
      };
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
  /// So [tone] = 1 here returns the [MaterialColor] color tone 990
  /// And [tone] = 99 here returns the [MaterialColor] color tone 10
  Color? mColorTone(int tone) {
    assert(tone >= 0 && tone <= 100, "color tone must be in the inclusive range of 0 to 100!");
    return this[1000 - tone * 10];
  }
}
