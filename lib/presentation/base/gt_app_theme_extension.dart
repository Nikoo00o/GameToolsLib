import 'package:flutter/material.dart';
import 'package:game_tools_lib/presentation/base/gt_app_theme.dart';

/// This should provide additional colors to the default flutter theme and can be retrieved with
/// `Theme.of(context).extension<GTAppThemeExtension>()` in the ui!
///
/// [success] is used to display some success status in the app (most of the time this would be [Colors.green]
/// except for when the theme itself is green!
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

  const GTAppThemeExtension({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.successFixed,
    required this.onSuccessFixed,
    required this.successFixedDim,
    required this.onSuccessFixedVariant,
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
    );
  }

  @override
  GTAppThemeExtension lerp(GTAppThemeExtension? other, double t) {
    if (other is! GTAppThemeExtension) {
      return this;
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
    );
  }
}
