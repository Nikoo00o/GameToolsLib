import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/locale_config_option.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/presentation/base/gt_app.dart';
import 'package:game_tools_lib/presentation/base/gt_app_theme_extension.dart';
import 'package:provider/provider.dart';

/// Base class for all widgets with some common helper functions as a mixin that can be used for each widget!
///
/// Best used to get colors like [colorPrimary] of the [theme], or text styles like [textBodyMedium], or translate
/// text with [translate]!
mixin class GTBaseWidget {
  /// Translates a translation [TranslationString.key] for the current locale and placeholders are replaced with
  /// [TranslationString.params]. This needs the current [context] to react to locale changes!
  ///
  /// Placeholders in the translation string of language.json have to start with "{0}" and then "{1}", "{2}", etc.
  /// But you always have to use [TranslationString.params] for translated strings that have those placeholders! (If
  /// you don't want to use them, use a list of empty strings with the same length!)
  String translate(TranslationString key, BuildContext context) => translateS(key, context);

  /// Translates a translation [TranslationString.key] for the current locale and placeholders are replaced with
  /// [TranslationString.params].
  ///
  /// If [context] is not null, then this will listen to locale changes and rebuild the calling widget automatically
  /// if needed! Otherwise for button callbacks, etc always leave it at null!
  ///
  /// Placeholders in the translation string of language.json have to start with "{0}" and then "{1}", "{2}", etc.
  /// But you always have to use [TranslationString.params] for translated strings that have those placeholders! (If
  /// you don't want to use them, use a list of empty strings with the same length!)
  static String translateS(TranslationString key, BuildContext? context) {
    if (context != null) {
      context.select<LocaleConfigOption, Locale?>((LocaleConfigOption option) => option.activeLocale);
    }
    return GTApp.translate(key); // IMPORTANT: first watch for changes to the locale above!!!
  }

  /// Returns the theme data. The [ThemeData.colorScheme] contains the colors used inside of the app.
  ThemeData theme(BuildContext context) => Theme.of(context);

  /// This is the same as [colorSurface] and also the default background color of a scaffold!
  Color colorScaffoldBackground(BuildContext context) => theme(context).scaffoldBackgroundColor;

  /// A color derived from [colorSurface] that is used when certain buttons, etc are disabled
  Color colorDisabled(BuildContext context) => theme(context).disabledColor;

  /// Main color used across screens and components like the text of [OutlinedButton] or [TextButton], or the fill
  /// color of [FilledButton]
  Color colorPrimary(BuildContext context) => theme(context).colorScheme.primary;

  /// Text and against shown against [colorPrimary] like the text inside of a [FilledButton]
  Color colorOnPrimary(BuildContext context) => theme(context).colorScheme.onPrimary;

  /// Standout container color for key components with a bit less emphasis than [colorPrimary]
  Color colorPrimaryContainer(BuildContext context) => theme(context).colorScheme.primaryContainer;

  /// Contrast-passing color shown against the [colorPrimaryContainer]
  Color colorOnPrimaryContainer(BuildContext context) => theme(context).colorScheme.onPrimaryContainer;

  /// Accent color used across screens and components
  Color colorSecondary(BuildContext context) => theme(context).colorScheme.secondary;

  /// Text and icons shown against [colorSecondary]
  Color colorOnSecondary(BuildContext context) => theme(context).colorScheme.onSecondary;

  /// Less prominent container color for components like the fill color [FilledButton.tonal]
  Color colorSecondaryContainer(BuildContext context) => theme(context).colorScheme.secondaryContainer;

  /// Contrast-passing color shown against the [colorSecondaryContainer] like the text of [FilledButton.tonal]
  Color colorOnSecondaryContainer(BuildContext context) => theme(context).colorScheme.onSecondaryContainer;

  /// Contrasting accent color used across screens and components
  Color colorTertiary(BuildContext context) => theme(context).colorScheme.tertiary;

  /// Text and icons shown against [colorTertiary]
  Color colorOnTertiary(BuildContext context) => theme(context).colorScheme.onTertiary;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorTertiaryContainer(BuildContext context) => theme(context).colorScheme.tertiaryContainer;

  /// Contrast-passing color shown against [colorTertiaryContainer]
  Color colorOnTertiaryContainer(BuildContext context) => theme(context).colorScheme.onTertiaryContainer;

  /// Indicates errors such as invalid input in a date picker
  Color colorError(BuildContext context) => theme(context).colorScheme.error;

  /// Used for text and icons on the [colorError]
  Color colorOnError(BuildContext context) => theme(context).colorScheme.onError;

  /// Container color for error messages and badges
  Color colorErrorContainer(BuildContext context) => theme(context).colorScheme.errorContainer;

  /// Used for text and icons on [colorErrorContainer]
  Color colorOnErrorContainer(BuildContext context) => theme(context).colorScheme.onErrorContainer;

  /// Surface color for components like cards, sheets and menus (also the [colorScaffoldBackground])
  Color colorSurface(BuildContext context) => theme(context).colorScheme.surface;

  /// Text and icons against the [colorSurface]
  Color colorOnSurface(BuildContext context) => theme(context).colorScheme.onSurface;

  /// Highest intensity of [colorSurfaceContainer]
  Color colorSurfaceContainerHighest(BuildContext context) => theme(context).colorScheme.surfaceContainerHighest;

  /// Medium high intensity of [colorSurfaceContainer]
  Color colorSurfaceContainerHigh(BuildContext context) => theme(context).colorScheme.surfaceContainerHigh;

  /// For dark theme a brighter variant of [colorSurface] and for light theme a darker shade of it.
  /// It also has more intense versions with [colorSurfaceContainerHighest] and not that intense version with
  /// [colorSurfaceContainerLowest]
  Color colorSurfaceContainer(BuildContext context) => theme(context).colorScheme.surfaceContainer;

  /// Medium low intensity of [colorSurfaceContainer]
  Color colorSurfaceContainerLow(BuildContext context) => theme(context).colorScheme.surfaceContainerLow;

  /// Lowest intensity of [colorSurfaceContainer]
  Color colorSurfaceContainerLowest(BuildContext context) => theme(context).colorScheme.surfaceContainerLowest;

  /// Displays opposite color of the surrounding ui
  Color colorInverseSurface(BuildContext context) => theme(context).colorScheme.inverseSurface;

  /// Text and icons against the [colorInverseSurface]
  Color colorOnInverseSurface(BuildContext context) => theme(context).colorScheme.onInverseSurface;

  /// Different variation of [colorSurface] shifted like 5% in the direction of [colorPrimary]
  Color colorSurfaceVariant(BuildContext context) => theme(context).colorScheme.surfaceVariant;

  /// Text and icons against the [colorSurfaceVariant]
  Color colorOnSurfaceVariant(BuildContext context) => theme(context).colorScheme.onSurfaceVariant;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorOutline(BuildContext context) => theme(context).colorScheme.outline;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorOutlineVariant(BuildContext context) => theme(context).colorScheme.outlineVariant;

  /// Used for shadows applied to elevated components, always black.
  Color colorShadow(BuildContext context) => theme(context).colorScheme.shadow;

  /// Used for scrims to separate floating components from the background, always black.
  Color colorScrim(BuildContext context) => theme(context).colorScheme.scrim;

  /// Returns the color of [ThemeData.colorScheme]. If used together with the elevation property to indicate
  /// elevation of elements!
  Color colorSurfaceTint(BuildContext context) => theme(context).colorScheme.surfaceTint;

  /// Returns the color of [ThemeData.colorScheme].
  Color colorInversePrimary(BuildContext context) => theme(context).colorScheme.inversePrimary;

  /// Version of [colorSurface] that is dimmer in both light and dark theme
  Color colorSurfaceDim(BuildContext context) => theme(context).colorScheme.surfaceDim;

  /// Version of [colorSurface] that is brighter in both light and dark theme
  Color colorSurfaceBright(BuildContext context) => theme(context).colorScheme.surfaceBright;

  /// Version of [colorPrimary] that does not care for light, or dark theme
  Color colorPrimaryFixed(BuildContext context) => theme(context).colorScheme.primaryFixed;

  /// Text and icons against the [colorPrimaryFixed]
  Color colorOnPrimaryFixed(BuildContext context) => theme(context).colorScheme.onPrimaryFixed;

  /// Dimmer Version of [colorPrimaryFixed]
  Color colorPrimaryFixedDim(BuildContext context) => theme(context).colorScheme.primaryFixedDim;

  /// Stronger hue variant of [colorOnPrimaryFixed]
  Color colorOnPrimaryFixedVariant(BuildContext context) => theme(context).colorScheme.onPrimaryFixedVariant;

  /// Version of [colorSecondary] that does not care for light, or dark theme
  Color colorSecondaryFixed(BuildContext context) => theme(context).colorScheme.secondaryFixed;

  /// Text and icons against the [colorSecondaryFixed]
  Color colorOnSecondaryFixed(BuildContext context) => theme(context).colorScheme.onSecondaryFixed;

  /// Dimmer Version of [colorSecondaryFixed]
  Color colorSecondaryFixedDim(BuildContext context) => theme(context).colorScheme.secondaryFixedDim;

  /// Stronger hue variant of [colorOnSecondaryFixed]
  Color colorOnSecondaryFixedVariant(BuildContext context) => theme(context).colorScheme.onSecondaryFixedVariant;

  /// Version of [colorTertiary] that does not care for light, or dark theme
  Color colorTertiaryFixed(BuildContext context) => theme(context).colorScheme.tertiaryFixed;

  /// Text and icons against the [colorTertiaryFixed]
  Color colorOnTertiaryFixed(BuildContext context) => theme(context).colorScheme.onTertiaryFixed;

  /// Dimmer Version of [colorTertiaryFixed]
  Color colorTertiaryFixedDim(BuildContext context) => theme(context).colorScheme.tertiaryFixedDim;

  /// Stronger hue variant of [colorOnTertiaryFixed]
  Color colorOnTertiaryFixedVariant(BuildContext context) => theme(context).colorScheme.onTertiaryFixedVariant;

  /// Custom color used for success indicators from [GTAppThemeExtension]
  Color colorSuccess(BuildContext context) => theme(context).extension<GTAppThemeExtension>()!.success;

  /// Used for text/icons on the [colorOnSuccess] color.
  Color colorOnSuccess(BuildContext context) => theme(context).extension<GTAppThemeExtension>()!.onSuccess;

  /// Custom success container color for key components that display some success like a checkbox from [GTAppThemeExtension]
  Color colorSuccessContainer(BuildContext context) =>
      theme(context).extension<GTAppThemeExtension>()!.successContainer;

  /// Contrast-passing color shown against the [colorSuccessContainer]
  Color colorOnSuccessContainer(BuildContext context) =>
      theme(context).extension<GTAppThemeExtension>()!.onSuccessContainer;

  /// Version of [colorSuccess] that does not care for light, or dark theme
  Color colorSuccessFixed(BuildContext context) => theme(context).extension<GTAppThemeExtension>()!.successFixed;

  /// Text and icons against the [colorSuccessFixed]
  Color colorOnSuccessFixed(BuildContext context) => theme(context).extension<GTAppThemeExtension>()!.onSuccessFixed;

  /// Dimmer Version of [colorSuccessFixed]
  Color colorSuccessFixedDim(BuildContext context) => theme(context).extension<GTAppThemeExtension>()!.successFixedDim;

  /// Stronger hue variant of [colorOnSuccessFixed]
  Color colorOnSuccessFixedVariant(BuildContext context) =>
      theme(context).extension<GTAppThemeExtension>()!.onSuccessFixedVariant;

  /// Returns the amount of additional colors which may be used for [colorAdditional].
  int colorAdditionalAmount(BuildContext context) =>
      theme(context).extension<GTAppThemeExtension>()!.additionalColors.length;

  /// Contains the different tones of the additional custom color at zero based [index] of
  /// [GTAppThemeExtension.additionalColors]. You can also look at the available number with [colorAdditionalAmount]
  ColorGroup colorAdditional(BuildContext context, int index) =>
      theme(context).extension<GTAppThemeExtension>()!.additionalColors.elementAt(index);

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textDisplayLarge(BuildContext context) => theme(context).textTheme.displayLarge!;

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textDisplayMedium(BuildContext context) => theme(context).textTheme.displayMedium!;

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textDisplaySmall(BuildContext context) => theme(context).textTheme.displaySmall!;

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textHeadlineLarge(BuildContext context) => theme(context).textTheme.headlineLarge!;

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textHeadlineMedium(BuildContext context) => theme(context).textTheme.headlineMedium!;

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textHeadlineSmall(BuildContext context) => theme(context).textTheme.headlineSmall!;

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textTitleLarge(BuildContext context) => theme(context).textTheme.titleLarge!;

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textTitleMedium(BuildContext context) => theme(context).textTheme.titleMedium!;

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textTitleSmall(BuildContext context) => theme(context).textTheme.titleSmall!;

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textLabelLarge(BuildContext context) => theme(context).textTheme.labelLarge!;

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textLabelMedium(BuildContext context) => theme(context).textTheme.labelMedium!;

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textLabelSmall(BuildContext context) => theme(context).textTheme.labelSmall!;

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textBodyLarge(BuildContext context) => theme(context).textTheme.bodyLarge!;

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textBodyMedium(BuildContext context) => theme(context).textTheme.bodyMedium!;

  /// Returns only the size, weight and spacing of the [ThemeData.textTheme], so that the text color will not be
  /// overridden when using this in widgets! (and so that something like a disabled color still works!)
  TextStyle textBodySmall(BuildContext context) => theme(context).textTheme.bodySmall!;

  /// Returns if the current theme is dark
  bool isDarkTheme(BuildContext context) => theme(context).brightness == Brightness.dark;

  /// Tries to show a translated bottom snack bar with the message and returns if it was successful.
  ///
  /// Because this is mostly called after some action in a callback, [listen] for [translateS] is false here to not
  /// listen to new locale changes! You should check [BuildContext.mounted] first if you call this across async gaps
  /// as well. If you want to listen to changes, then set [listen] to true instead.
  bool showToast(TranslationString key, BuildContext context, {bool listen = false}) {
    final ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? result =
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(
          SnackBar(
            content: Text(translateS(key, listen ? context : null)),
          ),
        );
    return result != null;
  }
}
