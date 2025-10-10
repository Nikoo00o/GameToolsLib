import 'package:flutter/material.dart';
import 'package:game_tools_lib/presentation/base/gt_app_theme.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';

/// This should provide additional colors to the default flutter theme and can be retrieved with
/// `Theme.of(context).extension<GTAppThemeExtension>()` in the ui!
///
/// [success] is used to display some success status in the app (most of the time this would be [Colors.green]
/// except for when the theme itself is green!
///
/// The custom [additionalColors] will have TranslationStrings "color.custom.n" (1 to ...) in the config UI!
final class GTAppThemeExtension extends ThemeExtension<GTAppThemeExtension> {
  /// Custom color used for success indicators.
  /// With dark theme color tone 80 and with light 40 of [GTAppTheme.baseSuccessColor]
  final Color success;

  /// Used for text/icons on the [success] color.
  /// With dark theme color tone 20 and with light 100 of [GTAppTheme.baseSuccessColor]
  final Color onSuccess;

  /// Standout container color for key components that display some success like a checkbox, etc.
  /// With dark theme color tone 30 and with light 90 of [GTAppTheme.baseSuccessColor]
  final Color successContainer;

  /// Contrast-passing color shown against the [successContainer].
  /// With dark theme color tone 90 and with light 10 of [GTAppTheme.baseSuccessColor]
  final Color onSuccessContainer;

  /// Version of [success] that does not care for light, or dark theme
  final Color successFixed;

  /// Text and icons against the [successFixed]
  final Color onSuccessFixed;

  /// Dimmer Version of [successFixed]
  final Color successFixedDim;

  /// Stronger hue variant of [successFixed]
  final Color onSuccessFixedVariant;

  /// List of custom additional colors with their tones grouped together which can be accessed in
  /// [GTBaseWidget.colorAdditional]. For the different tones look at [ColorGroup] docs!
  final List<ColorGroup> additionalColors;

  const GTAppThemeExtension({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.successFixed,
    required this.onSuccessFixed,
    required this.successFixedDim,
    required this.onSuccessFixedVariant,
    required this.additionalColors,
  });

  @override
  GTAppThemeExtension copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? successFixed,
    Color? onSuccessFixed,
    Color? successFixedDim,
    Color? onSuccessFixedVariant,
    List<ColorGroup>? additionalColors,
  }) {
    return GTAppThemeExtension(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      successFixed: successFixed ?? this.successFixed,
      onSuccessFixed: onSuccessFixed ?? this.onSuccessFixed,
      successFixedDim: successFixedDim ?? this.successFixedDim,
      onSuccessFixedVariant: onSuccessFixedVariant ?? this.onSuccessFixedVariant,
      additionalColors: additionalColors ?? this.additionalColors,
    );
  }

  @override
  GTAppThemeExtension lerp(GTAppThemeExtension? other, double t) {
    if (other is! GTAppThemeExtension) {
      return this;
    }
    final List<ColorGroup> lerpedGroups = <ColorGroup>[];
    for (int i = 0; i < additionalColors.length; ++i) {
      final ColorGroup myGroup = additionalColors.elementAt(i);
      if (i < other.additionalColors.length) {
        final ColorGroup otherGroup = other.additionalColors.elementAt(i);
        lerpedGroups.add(myGroup.lerp(otherGroup, t));
      } else {
        lerpedGroups.add(myGroup);
      }
    }
    return GTAppThemeExtension(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      successFixed: Color.lerp(successFixed, other.successFixed, t)!,
      onSuccessFixed: Color.lerp(onSuccessFixed, other.onSuccessFixed, t)!,
      successFixedDim: Color.lerp(successFixedDim, other.successFixedDim, t)!,
      onSuccessFixedVariant: Color.lerp(onSuccessFixedVariant, other.onSuccessFixedVariant, t)!,
      additionalColors: lerpedGroups,
    );
  }
}

/// Used for [GTAppThemeExtension] to group the different tones of the additional custom colors together with
/// [normal], [onNormal], [container], [onContainer], [fixed], [onFixed], [fixedDim], [onFixedVariant].
final class ColorGroup {
  /// Custom color used for success indicators.
  /// With dark theme color tone 80 and with light 40 of [GTAppTheme.baseAdditionalColors]
  final Color normal;

  /// Used for text/icons on the [normal] color.
  /// With dark theme color tone 20 and with light 100 of [GTAppTheme.baseAdditionalColors]
  final Color onNormal;

  /// Standout container color for key components like a checkbox, etc.
  /// With dark theme color tone 30 and with light 90 of [GTAppTheme.baseAdditionalColors]
  final Color container;

  /// Contrast-passing color shown against the [container].
  /// With dark theme color tone 90 and with light 10 of [GTAppTheme.baseAdditionalColors]
  final Color onContainer;

  /// Version of [normal] that does not care for light, or dark theme
  final Color fixed;

  /// Text and icons against the [fixed]
  final Color onFixed;

  /// Dimmer Version of [fixed]
  final Color fixedDim;

  /// Stronger hue variant of [onFixed]
  final Color onFixedVariant;

  const ColorGroup({
    required this.normal,
    required this.onNormal,
    required this.container,
    required this.onContainer,
    required this.fixed,
    required this.onFixed,
    required this.fixedDim,
    required this.onFixedVariant,
  });

  ColorGroup lerp(ColorGroup? other, double t) {
    if (other is! ColorGroup) {
      return this;
    }
    return ColorGroup(
      normal: Color.lerp(normal, other.normal, t)!,
      onNormal: Color.lerp(onNormal, other.onNormal, t)!,
      container: Color.lerp(container, other.container, t)!,
      onContainer: Color.lerp(onContainer, other.onContainer, t)!,
      fixed: Color.lerp(fixed, other.fixed, t)!,
      onFixed: Color.lerp(onFixed, other.onFixed, t)!,
      fixedDim: Color.lerp(fixedDim, other.fixedDim, t)!,
      onFixedVariant: Color.lerp(onFixedVariant, other.onFixedVariant, t)!,
    );
  }
}
