import 'dart:async';
import 'dart:math';
import 'dart:ui' show Color;

import 'package:game_tools_lib/core/enums/native_image_type.dart';
import 'package:game_tools_lib/core/utils/file_utils.dart';
import 'package:game_tools_lib/core/utils/list_utils.dart';
import 'package:game_tools_lib/core/utils/num_utils.dart';
import 'package:game_tools_lib/core/utils/string_utils.dart';
export 'bounds.dart';
export 'file_utils.dart';
export 'immutable_equatable.dart';
export 'list_utils.dart';
export 'nullable.dart';
export 'num_utils.dart';
export 'string_utils.dart';

/// Contains general Utils functions like [executePeriodic].
/// For specific Utils look into [NumUtils], [StringUtils], [ListUtils], [FileUtils].
abstract final class Utils {
  /// if the value is not set, then its the timestamp when the callback may be executed again
  static final Map<FutureOr<void> Function(), DateTime?> _executors = <FutureOr<void> Function(), DateTime?>{};

  /// This is a guard used for asserts in debug mode to check if you used [executePeriodicAsync] with unnamed lambda
  /// functions and have more unique [_executors] than this number (for some unknown edge cases, you may change this).
  static int maxExecutorCountGuard = 9999;

  /// Should be called from inside an (async) loop and will not loop, or block itself!
  /// This acts as a guard to only call [callback] after every [delay].
  /// The [callback] function reference/pointer should be unique across all sources that call this.
  ///
  /// IMPORTANT: you have to create the function pointer for [callback] outside of your loop and you MAY NOT use an
  /// unnamed lambda function!!!!!!!! As a guard an assert is thrown in debug mode if there are more unique [_executors]
  /// callbacks added than [maxExecutorCountGuard].
  /// Example:
  /// ```dart
  ///     int counter = 0;
  ///     void callback() { counter -= 1; }
  ///     while(true) { Utils.executePeriodicSync(delay: Duration(milliseconds: 10), callback: callback); }
  /// ```
  static Future<void> executePeriodicAsync({required Duration delay, required Future<void> Function() callback}) async {
    final DateTime now = DateTime.now();
    final DateTime? blockUntil = _executors[callback];
    if (blockUntil != null) {
      if (now.isBefore(blockUntil)) {
        return;
      }
    }
    _executors[callback] = now.add(delay);
    assert(_executors.keys.length < maxExecutorCountGuard);
    await callback.call();
  }

  /// Should be called from inside a (sync) loop and will not loop, or block itself!
  /// This acts as a guard to only call [callback] after every [delay].
  /// The [callback] function reference/pointer should be unique across all sources that call this.
  ///
  /// IMPORTANT: you have to create the function pointer for [callback] outside of your loop and you MAY NOT use an
  /// unnamed lambda function!!!!!!!! As a guard an assert is thrown in debug mode if there are more unique [_executors]
  /// callbacks added than [maxExecutorCountGuard].
  /// Example:
  /// ```dart
  ///     int counter = 0;
  ///     void callback() { counter -= 1; }
  ///     while(true) { Utils.executePeriodicSync(delay: Duration(milliseconds: 10), callback: callback); }
  /// ```
  static void executePeriodicSync({required Duration delay, required void Function() callback}) {
    final DateTime now = DateTime.now();
    final DateTime? blockUntil = _executors[callback];
    if (blockUntil != null) {
      if (now.isBefore(blockUntil)) {
        return;
      }
    }
    _executors[callback] = now.add(delay);
    assert(_executors.keys.length < maxExecutorCountGuard);
    callback.call();
  }

  /// Just shorter syntax than [Future<void>].delayed
  static Future<void> delay(Duration delay) async => Future<void>.delayed(delay);

  /// Just shorter syntax for [delay] if [milliseconds] should be used directly and no duration
  static Future<void> delayMS(int milliseconds) async => Future<void>.delayed(Duration(milliseconds: milliseconds));

  /// Returns if [color1] and [color2] are equal.
  /// The default for [skipAlpha] is true, so that alpha will not be compared.
  /// Per default this still returns true if the pixel has a difference of 1 (see [pixelValueThreshold])
  static bool colorEquals(Color? color1, Color? color2, {bool skipAlpha = true, int pixelValueThreshold = 1}) {
    if (color1 == color2) {
      return true; // same reference (or both null)
    }
    if (color1 == null || color2 == null) {
      return false;
    }
    const double pixelMultiplier = 1.0 / 255.0;
    double change = color1.r.diff(color2.r) + color1.g.diff(color2.g) + color1.b.diff(color2.b);
    if (skipAlpha == false) {
      change += color1.a.diff(color2.a);
    }
    return change.isLessOrEqualThan(pixelMultiplier * pixelValueThreshold);
  }

  /// Returns if [S] is a subtype of [T] (has to be used in generic methods, because the "is" operator does not work on
  /// template types! Use it with your generic type as [S] and then test against different parent types with [T].
  static bool isSubtype<S, T>() => <S>[] is List<T>;
}

/// Helper methods for [Color] to compare equality (also has different getters for different color representations)
extension ColorExtension on Color {
  /// Returns if this is equal to [other] by using [Utils.colorEquals].
  /// The default for [skipAlpha] is true, so that alpha will not be compared.
  /// Per default this still returns true if the pixel has a difference of 1 (see [pixelValueThreshold])
  bool equals(Color? other, {bool skipAlpha = true, int pixelValueThreshold = 1}) =>
      Utils.colorEquals(this, other, skipAlpha: skipAlpha, pixelValueThreshold: pixelValueThreshold);

  /// String representation of this color with rgba values!
  String get rgb => "Color(r=$redI, g=$greenI, b=$blueI, a=$alphaI)";

  /// First 8 bits blue value as 0 to 255 (the I suffix avoids clashing with default getter)
  int get blueI => (b * 255.0).round() & 0xff;

  /// Next 8 bits after [blueI] for green value as 0 to 255
  int get greenI => (g * 255.0).round() & 0xff;

  /// Next 8 bits after [greenI] for red value as 0 to 255
  int get redI => (r * 255.0).round() & 0xff;

  /// Next 8 bits after [redI] for alpha value as 0 to 255
  int get alphaI => (a * 255.0).round() & 0xff;

  /// If only the lowest bit is set to store a grayscale image values (every r/g/b would have the same value)!
  /// Used for example with [NativeImageType.GRAY]. Same as [blueI]
  int get gray => blueI;

  /// Different color access hsv (also 0 to 255), same as [blueI]. This is the color type as an angle on color wheel
  int get h => blueI;

  /// Different color access hsv (also 0 to 255), same as [greenI]. This is the saturation representing the intensity
  /// of the color (0 is grayscale and 255 is pure color)
  int get s => greenI;

  /// Different color access hsv (also 0 to 255), same as [redI]. This is the brightness of the color (0 is black and
  /// 255 is brightest color)
  int get v => redI;

  /// Returns a color that is brighter by the percentage [factor] 0.000001 to 0.999999
  Color tint(double factor) =>
      Color.from(alpha: 1.0, red: _tint(r, factor), green: _tint(g, factor), blue: _tint(b, factor));

  /// Returns a color that is darker by the percentage [factor] 0.000001 to 0.999999
  Color shade(double factor) =>
      Color.from(alpha: 1.0, red: _shade(r, factor), green: _shade(g, factor), blue: _shade(b, factor));

  /// Returns a color that is blended into the [target] by the percentage [factor] 0.000001 to 0.999999
  /// So 5% would be 0.05
  Color blend(Color target, double factor) => Color.from(
    alpha: 1.0,
    red: _shift(r, factor, target.r),
    green: _shift(g, factor, target.g),
    blue: _shift(b, factor, target.b),
  );

  /// Moves [value] closer to 1 by [factor]
  static double _tint(double value, double factor) => _bounds(value + ((1.0 - value) * factor));

  /// Moves [value] closer to 0 by [factor]
  static double _shade(double value, double factor) => _bounds(value - (value * factor));

  /// Moves [value] closer to [target] by [factor]
  static double _shift(double value, double factor, double target) => _bounds(value + ((target - value) * factor));

  /// between 0.0 and 1.0 .
  static double _bounds(double value) => max(0.0, min(1.0, value));
}
