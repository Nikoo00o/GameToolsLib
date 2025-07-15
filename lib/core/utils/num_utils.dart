import 'dart:math';

import 'package:game_tools_lib/core/config/fixed_config.dart';

/// contains useful number functions and also provides extensions on [int] and [double] with internal helper methods!
/// Like for example [absPoint], [getRandomNumber], or [gcd]
abstract final class NumUtils {
  static Random? _instanceRandom;

  static Random get _random => _instanceRandom ??= Random(DateTime.now().microsecondsSinceEpoch);
  static Random? _instanceSecureRandom;

  static Random get _secureRandom => _instanceSecureRandom ??= Random.secure();

  /// Used to compare doubles
  static const double _epsilon = 0.0001;

  /// Not crypto secure random inclusive from [incFrom] to [incTo]
  static int getRandomNumber(int incFrom, int incTo) {
    if (incFrom == incTo) {
      return incFrom;
    }
    return incFrom + _random.nextInt(incTo + 1 - incFrom);
  }

  /// Same as [getRandomNumber], but with [Point] where [Point.x] is the min number and [Point.y] the max
  static int getRandomNumberP(Point<int> incFromTo) => getRandomNumber(incFromTo.x, incFromTo.y);

  /// Crypto secure random inclusive from [incFrom] to [incTo]
  static int getCryptoRandomNumber(int incFrom, int incTo) => incFrom + _secureRandom.nextInt(incTo + 1 - incFrom);

  /// Returns true if a dice was rolled successfully
  /// The values for [percentChance] should range from 0.00 to 1.00 (for 0 to 100 percent where 0.5 would be 50%)
  static bool getRandomPercent(double percentChance) => getRandomNumber(0, 99) < percentChance * 100.0;

  /// Returns a [Duration] object with a random delay in milliseconds between the values of [delayInMS] (x=min, y=max).
  /// If that's null, it defaults to [defaultIfNull] and if that is null as well, then it uses [FixedConfig.shortDelayMS]
  static Duration getRandomDuration(Point<int>? delayInMS, {Point<int>? defaultIfNull}) {
    defaultIfNull ??= FixedConfig.fixedConfig.shortDelayMS;
    return Duration(milliseconds: NumUtils.getRandomNumberP(delayInMS ?? defaultIfNull));
  }

  /// Returns Absolute non negative values. If [higherThanZero] is true, then this will also not allow values of 0.
  /// For [T] = [double], this will then set the value to [_epsilon]
  static Point<T> absPoint<T extends num>(Point<T> p, {bool higherThanZero = false}) {
    final Point<T> abs = Point<T>(p.x.abs() as T, p.y.abs() as T);
    if (higherThanZero) {
      if (T == int) {
        return Point<T>(abs.x <= 1 ? 1 as T : abs.x, abs.y <= 1 ? 1 as T : abs.y);
      } else {
        return Point<T>(abs.x <= _epsilon ? _epsilon as T : abs.x, abs.y <= _epsilon ? _epsilon as T : abs.y);
      }
    }
    return abs;
  }

  /// Treats the point like a vector and returns one that has a magnitude/length of 1 in the same direction (so it
  /// points into the same distance, but both values are smaller)
  static Point<T> normalizePoint<T extends num>(Point<T> p) {
    final double divisor = p.magnitude;
    final double newX = p.x / divisor;
    final double newY = p.y / divisor;
    if (T == int) {
      return Point<T>(newX.toInt() as T, newY.toInt() as T);
    } else {
      return Point<T>(newX as T, newY as T);
    }
  }

  /// Keeps the relationship, but multiplies both components, so that they are at least [minValue].
  /// Should only be used with positive points [p], otherwise it just returns [0, 0]
  static Point<T> raisePointTo<T extends num>(Point<T> p, T minValue) {
    final T smaller = p.x < p.y ? p.x : p.y;
    if (T == int && smaller < 0) {
      return Point<T>(0 as T, 0 as T);
    } else if (smaller < _epsilon) {
      return Point<T>(0.0 as T, 0.0 as T);
    }
    if (smaller < minValue) {
      final double multiplier = minValue / smaller;
      if (T == int) {
        return Point<T>((p.x * multiplier).toInt() as T, (p.y * multiplier).toInt() as T);
      } else {
        return Point<T>(p.x * multiplier as T, p.y * multiplier as T);
      }
    } else {
      return Point<T>(p.x, p.y);
    }
  }

  /// returns greatest common divisor of [a] and [b]
  static int gcd(int a, int b) {
    if (a < b) {
      return gcd(b, a);
    }
    if (b == 0) {
      return a;
    } else {
      return gcd(b, a - (a / b).floor() * b);
    }
  }
}

/// Helper methods for [double which return modified values. (or bool for comparison methods that
/// use [NumUtils._epsilon]). Some utils are also in
extension DoubleExtension on double {
  /// if the [abs] difference between [other] and this is smaller than [epsilon]
  bool isEqual(double other, {double epsilon = NumUtils._epsilon}) => (this - other).abs() < epsilon;

  bool isZero({double epsilon = NumUtils._epsilon}) => isEqual(0.0, epsilon: epsilon);

  bool isLessThan(double more, {double epsilon = NumUtils._epsilon}) => this + epsilon < more;

  bool isMoreThan(double less, {double epsilon = NumUtils._epsilon}) => this - epsilon > less;

  bool isLessOrEqualThan(double moreOrEqual, {double epsilon = NumUtils._epsilon}) => !isMoreThan(moreOrEqual);

  bool isMoreOrEqualThan(double lessOrEqual, {double epsilon = NumUtils._epsilon}) => !isLessThan(lessOrEqual);

  /// 10.00 would return false, 10.10 would return true
  bool hasDecimalPoints({double epsilon = NumUtils._epsilon}) => (this - floor().toDouble()) > epsilon;
}

/// Helper methods for [int] which return modified values.
extension IntExtension on int {
  /// Returns this scaled by [scaleFactor]
  int scale(double scaleFactor) => (this * scaleFactor).round();
}

/// Helper methods for [Point] which return modified values like [abs], [scale], [move], or [toIntPoint].
/// [Point.distanceTo] and [Point.magnitude] already exist (squaredDistanceTo is faster).
/// Also provides [fromJson] for json conversion and [equals] for comparison of double points with [NumUtils._epsilon]
/// (instead of default operator==).
extension PointExtension<T extends num> on Point<T> {
  /// Returns Absolute non negative values. If [higherThanZero] is true, then this will also not allow values of 0.
  /// For [T] = [double], this will then set the value to [NumUtils._epsilon]
  Point<T> abs({bool higherThanZero = false}) => NumUtils.absPoint(this, higherThanZero: higherThanZero);

  /// Treats the point like a vector and returns one that has a magnitude/length of 1 in the same direction (so it
  /// points into the same distance, but both values are smaller)
  Point<T> normalize() => NumUtils.normalizePoint(this);

  /// Keeps the relationship, but multiplies both components, so that they are at least [minValue].
  /// Should only be used with positive points [p], otherwise it just returns [0, 0]
  Point<T> raiseTo(T minValue) => NumUtils.raisePointTo(this, minValue);

  /// Multiplies [x] with [scaleX] and [y] with [scaleY]
  Point<T> scale(double scaleX, double scaleY) {
    final Point<double> scaledP = Point<double>(x * scaleX, y * scaleY);
    if (T == int) {
      return scaledP.toIntPoint() as Point<T>;
    }
    return scaledP as Point<T>;
  }

  /// scales both with [scale]
  Point<T> scaleB(double multiplier) => scale(multiplier, multiplier);

  /// Returns a modified copy of this with added [addXValue] and [addYValue]
  Point<T> move(T addXValue, T addYValue) => Point<T>(x + addXValue as T, y + addYValue as T);

  /// Any num point copied as int (no decimal points)
  Point<int> toIntPoint() => Point<int>(x.toInt(), y.toInt());

  /// Any num point copied as double (with decimal points)
  Point<double> toDoublePoint() => Point<double>(x.toDouble(), y.toDouble());

  /// Ignores runtime type of other type and uses [DoubleExtension.isEqual] for doubles
  bool equals(Object other) {
    if (other is! Point) {
      return false;
    }
    if (T == double && other is Point<T>) {
      return (x as double).isEqual(other.x as double) && (y as double).isEqual(other.y as double);
    }
    return x == other.x && y == other.y;
  }

  static const String JSON_X = "JSON_X";
  static const String JSON_Y = "JSON_Y";

  Map<String, dynamic> toJson() => <String, dynamic>{JSON_X: x, JSON_Y: y};

  static Point<T> fromJson<T extends num>(Map<String, dynamic> json) => Point<T>(json[JSON_X] as T, json[JSON_Y] as T);
}
