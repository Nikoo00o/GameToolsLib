import 'package:game_tools_lib/core/config/fixed_config.dart';

/// Can be mixed in for an easy way to receive slower updates. See [performanceTickCount] and [canTick].
base mixin PerformanceTickMixin {
  /// Can be overridden in sub classes, but per default returns [FixedConfig.overlayRefreshTicks]
  int get performanceTickCount => FixedConfig.fixedConfig.overlayRefreshTicks;

  /// used for less performance impact of tick rate
  int _performanceCounter = 0;

  /// Returns true only if the performance counter was reached. Should be called periodically inside of an [onUpdate]
  /// method and then execute some more performance intensive work if this returned true!
  bool canTick() {
    if (_performanceCounter++ >= performanceTickCount) {
      _performanceCounter = 0;
      return true;
    }
    return false;
  }
}
