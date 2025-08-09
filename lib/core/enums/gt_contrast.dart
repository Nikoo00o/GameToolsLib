import 'package:game_tools_lib/presentation/base/gt_app_theme.dart';

/// The contrast mode that affects the [GTAppTheme]
enum GTContrast {
  /// 0
  DEFAULT,

  /// 1
  MEDIUM,

  /// 2
  HIGH;

  @override
  String toString() {
    return name;
  }

  factory GTContrast.fromString(String data) {
    return values.firstWhere((GTContrast element) => element.name == data);
  }

  double getContrastLevel() => switch (this) {
    DEFAULT => 0.0,
    MEDIUM => 0.5,
    HIGH => 1.0,
  };
}
