import 'package:flutter/material.dart';
import 'package:game_tools_lib/presentation/base/gt_app_theme.dart';

/// In rgb format
final class LogColor {
  /// Red: 0 to 255
  final int r;

  /// Green: 0 to 255
  final int g;

  /// Blue: 0 to 255
  final int b;

  const LogColor(this.r, this.g, this.b);

  @override
  String toString() {
    if (r >= 255 && g >= 255 && b >= 255) {
      return "\x1B[0m";
    }
    return "\x1B[38;2;$r;$g;${b}m";
  }

  /// Color to display this in the ui
  Color getUIColor(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return Color.fromRGBO(r, g, b, 1.0);
    } else {
      return GTAppTheme.shadeColor(Color.fromRGBO(r, g, b, 1.0), 0.45);
    }
  }
}
