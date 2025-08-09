import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/enums/gt_contrast.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/presentation/base/gt_app_theme_extension.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';

//ignore_for_file: prefer_initializing_formals

/// A utility helper class to create a theme for the app. The colors will be converted to the final tones and can be
/// accessed in [GTBaseWidget] afterwards like for example for [basePrimaryColor] you have [GTBaseWidget.colorPrimary],
/// etc. For non material default colors like [baseSuccessColor] and [baseAdditionalColors] look at
/// [GTAppThemeExtension]!
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
/// For reference the detailed baseline color tokens are listed for every configuration in
/// https://m3.material.io/styles/color/static/baseline#b5a485b5-ee5f-4890-b7a2-ead284121e37
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

  /// A slightly different optional shade of the [baseNeutralColor] for more background options.
  /// If this is null, then the [baseNeutralColor] will be used instead blended by 5% to the [basePrimaryColor]!
  final Color? baseNeutralVariantColor;

  /// Used for errors (mostly some shade of red)
  final Color? baseErrorColor;

  /// Used to display some success status in the app (most of the time this would be [Colors.green] except for when
  /// the theme itself is green! See [GTAppThemeExtension.success] with [GTBaseWidget.colorSuccess],etc
  final Color baseSuccessColor;

  /// The contrast mode which affects the colors of the theme (the default would be [GTContrast.DEFAULT] ). Dark vs
  /// light theme will be decided in [getTheme].
  final GTContrast contrast;

  /// See unmodifiable getter [baseAdditionalColors]
  final List<Color> _baseAdditionalColors;

  /// Used to display additional non material default index based colors which are used across the app. This is only
  /// optional and can also be left empty if the other colors are enough. Look at [GTAppThemeExtension.additionalColors]
  /// for more info!
  UnmodifiableListView<Color> get baseAdditionalColors => UnmodifiableListView<Color>(_baseAdditionalColors);

  /// Converts the base colors to their tonal palettes. [baseSecondaryColor], etc are non nullable params for
  /// [GTAppTheme.baseSecondaryColor], etc
  const GTAppTheme.colors({
    required this.basePrimaryColor,
    required Color baseSecondaryColor,
    required Color baseTertiaryColor,
    required Color baseNeutralColor,
    required Color baseErrorColor,
    this.baseNeutralVariantColor,
    required this.baseSuccessColor,
    required this.contrast,
    required List<Color> baseAdditionalColors,
  }) : baseSecondaryColor = baseSecondaryColor,
       baseTertiaryColor = baseTertiaryColor,
       baseNeutralColor = baseNeutralColor,
       baseErrorColor = baseErrorColor,
       _baseAdditionalColors = baseAdditionalColors;

  /// Builds internal colors from the seed color
  const GTAppTheme.seed({
    required Color seedColor,
    required this.baseSuccessColor,
    this.contrast = GTContrast.DEFAULT,
    required List<Color> baseAdditionalColors,
  }) : basePrimaryColor = seedColor,
       baseSecondaryColor = null,
       baseTertiaryColor = null,
       baseNeutralColor = null,
       baseNeutralVariantColor = null,
       baseErrorColor = null,
       _baseAdditionalColors = baseAdditionalColors;

  static Color? _readColor(String part) {
    if (part == "null") {
      return null;
    }
    return Color(int.parse(part));
  }

  factory GTAppTheme.fromString(String data) {
    final List<String> parts = data.split("|");
    int i = 0;
    final Color basePrimaryColor = _readColor(parts[i++])!;
    final Color? baseSecondaryColor = _readColor(parts[i++]);
    final Color? baseTertiaryColor = _readColor(parts[i++]);
    final Color? baseNeutralColor = _readColor(parts[i++]);
    final Color? baseErrorColor = _readColor(parts[i++]);
    final Color? baseNeutralVariantColor = _readColor(parts[i++]);
    final Color baseSuccessColor = _readColor(parts[i++])!;
    final GTContrast contrast = GTContrast.fromString(parts[i++]);
    final List<String> innerParts = parts[i++].split("-");
    if (innerParts.length == 1 && innerParts.first.isEmpty) {
      innerParts.clear();
    }
    final List<Color> baseAdditionalColors = <Color>[];
    for (final String part in innerParts) {
      baseAdditionalColors.add(Color(int.parse(part)));
    }
    if (baseSecondaryColor == null || baseTertiaryColor == null || baseNeutralColor == null || baseErrorColor == null) {
      return GTAppTheme.seed(
        seedColor: basePrimaryColor,
        baseSuccessColor: baseSuccessColor,
        contrast: contrast,
        baseAdditionalColors: baseAdditionalColors,
      );
    } else {
      return GTAppTheme.colors(
        basePrimaryColor: basePrimaryColor,
        baseSecondaryColor: baseSecondaryColor,
        baseTertiaryColor: baseTertiaryColor,
        baseNeutralColor: baseNeutralColor,
        baseErrorColor: baseErrorColor,
        baseNeutralVariantColor: baseNeutralVariantColor,
        baseSuccessColor: baseSuccessColor,
        contrast: contrast,
        baseAdditionalColors: baseAdditionalColors,
      );
    }
  }

  static void _writeColor(Color? color, StringBuffer buff) {
    buff.write(color?.toARGB32());
    buff.write("|");
  }

  @override
  String toString() {
    final StringBuffer buff = StringBuffer();
    _writeColor(basePrimaryColor, buff);
    _writeColor(baseSecondaryColor, buff);
    _writeColor(baseTertiaryColor, buff);
    _writeColor(baseNeutralColor, buff);
    _writeColor(baseErrorColor, buff);
    _writeColor(baseNeutralVariantColor, buff);
    _writeColor(baseSuccessColor, buff);
    buff.write("${contrast.name}|");
    for (final Color color in baseAdditionalColors) {
      buff.write(color.toARGB32());
      buff.write("-");
    }
    return buff.toString();
  }

  GTAppThemeExtension _getExtension({required bool darkTheme}) {
    final MaterialColor success = convertColor(baseSuccessColor);
    final List<int> tone = _defaultTone(contrast: contrast, isDarkTheme: darkTheme);
    final List<int> fTone = _fixedTone(contrast: contrast, isDarkTheme: darkTheme);
    final List<ColorGroup> additionalColors = <ColorGroup>[];
    for (final Color baseColor in baseAdditionalColors) {
      final MaterialColor base = convertColor(baseColor);
      additionalColors.add(
        ColorGroup(
          normal: _transform(base, tone),
          onNormal: _transform(base, tone),
          container: _transform(base, tone),
          onContainer: _transform(base, tone),
          fixed: _transform(base, fTone),
          onFixed: _transform(base, fTone),
          fixedDim: _transform(base, fTone),
          onFixedVariant: _transform(base, fTone),
        ),
      );
    }
    return GTAppThemeExtension(
      success: _transform(success, tone),
      onSuccess: _transform(success, tone),
      successContainer: _transform(success, tone),
      onSuccessContainer: _transform(success, tone),
      successFixed: _transform(success, fTone),
      onSuccessFixed: _transform(success, fTone),
      successFixedDim: _transform(success, fTone),
      onSuccessFixedVariant: _transform(success, fTone),
      additionalColors: additionalColors,
    );
  }

  /// Returns the material 3 theme data for this theme with the generated [ColorScheme].
  ///
  /// Depending on [darkTheme] either a dark, or light theme will be returned!
  ThemeData getTheme({required bool darkTheme}) {
    return ThemeData(
      colorScheme: getColorScheme(darkTheme: darkTheme),
      useMaterial3: true,
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all<bool>(true),
      ),
      extensions: <ThemeExtension<dynamic>>[_getExtension(darkTheme: darkTheme)],
    );
  }

  /// Returns the parsed [ColorScheme] from the base material colors.
  ColorScheme getColorScheme({required bool darkTheme}) {
    final Brightness brightness = darkTheme ? Brightness.dark : Brightness.light;
    if (baseSecondaryColor == null || baseTertiaryColor == null || baseNeutralColor == null || baseErrorColor == null) {
      return ColorScheme.fromSeed(
        seedColor: basePrimaryColor,
        brightness: brightness,
        contrastLevel: contrast.getContrastLevel(),
      );
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
        GTContrast.MEDIUM => <int>[30, 90, 70, 60],
        GTContrast.HIGH => <int>[30, 100, 95, 80],
      };
    } else {
      return switch (contrast) {
        GTContrast.DEFAULT => <int>[90, 30, 50, 80],
        GTContrast.MEDIUM => <int>[90, 20, 30, 50],
        GTContrast.HIGH => <int>[90, 0, 20, 30],
      };
    }
  }

  /// The returned material color also has [0] set to white and [1000] set to black and of course [500] set to the color
  /// itself. This also contains some additional tints and shades.
  ///
  /// 10 steps here from dart (keys of the map) are equal to 1 step in the material color tone (and an increment of
  /// the double scale of 0.02):
  /// [900] is the material color tone [10].
  /// [50] is the material color tone [95].
  /// [10] is the material color tone [99].
  static MaterialColor convertColor(Color color) {
    final Map<int, Color> colorMap = <int, Color>{
      0: tintColor(color, 1.0), // 100
      10: tintColor(color, 0.98), // 99
      20: tintColor(color, 0.96), // 98
      40: tintColor(color, 0.92), // 96
      50: tintColor(color, 0.9), // 95
      60: tintColor(color, 0.88), // 94
      80: tintColor(color, 0.84), // 92
      100: tintColor(color, 0.8), // 90
      200: tintColor(color, 0.6), // 80
      300: tintColor(color, 0.4), // 70
      400: tintColor(color, 0.2), // 60
      500: color, // 50
      600: shadeColor(color, 0.2), // 40
      700: shadeColor(color, 0.4), // 30
      780: shadeColor(color, 0.56), // 22
      800: shadeColor(color, 0.6), // 20
      830: shadeColor(color, 0.66), // 17
      880: shadeColor(color, 0.76), // 12
      900: shadeColor(color, 0.8), // 10
      940: shadeColor(color, 0.88), // 6
      960: shadeColor(color, 0.92), // 4
      1000: shadeColor(color, 1.0), // 0
    };
    return MaterialColor(color.toARGB32(), colorMap);
  }

  /// Returns a color that is brighter by the percentage [factor] 0.000001 to 0.999999
  static Color tintColor(Color color, double factor) => color.tint(factor);

  /// Returns a color that is darker by the percentage [factor] 0.000001 to 0.999999
  static Color shadeColor(Color color, double factor) => color.shade(factor);

  /// Returns a color that is the [source] blended into the [target] by the percentage [factor] 0.000001 to 0.999999
  static Color blend(Color source, Color target, double factor) => source.blend(target, factor);

  /// Important: this is not a true copy constructor, because for [baseSecondaryColor], [baseTertiaryColor],
  /// [baseNeutralColor] and [baseErrorColor] this will use [basePrimaryColor] as a default fallback if they were
  /// null and if they are null in the params AND IF ANY OF THEM IS NOT NULL (otherwise if all of them are null, seed
  /// constructor is used!)!
  GTAppTheme copyWith({
    Color? basePrimaryColor,
    Color? baseSecondaryColor,
    Color? baseTertiaryColor,
    Color? baseNeutralColor,
    Color? baseErrorColor,
    Color? baseNeutralVariantColor,
    Color? baseSuccessColor,
    GTContrast? newContrast,
    List<Color>? baseAdditionalColors,
  }) {
    final Color primary = basePrimaryColor ?? this.basePrimaryColor;
    final Color? secondary = baseSecondaryColor ?? this.baseSecondaryColor;
    final Color? tertiary = baseTertiaryColor ?? this.baseTertiaryColor;
    final Color? neutral = baseNeutralColor ?? this.baseNeutralColor;
    final Color? error = baseErrorColor ?? this.baseErrorColor;
    final Color success = baseSuccessColor ?? this.baseSuccessColor;
    final GTContrast contrast = newContrast ?? this.contrast;
    final List<Color> additionalColors = baseAdditionalColors ?? _baseAdditionalColors;
    if (secondary == null && tertiary == null && neutral == null && error == null) {
      return GTAppTheme.seed(
        seedColor: primary,
        baseSuccessColor: success,
        contrast: contrast,
        baseAdditionalColors: additionalColors,
      );
    } else {
      return GTAppTheme.colors(
        basePrimaryColor: primary,
        baseSecondaryColor: secondary ?? primary,
        baseTertiaryColor: tertiary ?? primary,
        baseNeutralColor: neutral ?? primary,
        baseErrorColor: error ?? primary,
        baseNeutralVariantColor: baseNeutralVariantColor ?? this.baseNeutralVariantColor,
        baseSuccessColor: success,
        contrast: contrast,
        baseAdditionalColors: additionalColors,
      );
    }
  }
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
