import 'dart:math';

abstract final class NumUtils {
  static Random? _instanceRandom;

  static Random get _random => _instanceRandom ??= Random(DateTime.now().microsecondsSinceEpoch);
  static Random? _instanceSecureRandom;

  static Random get _secureRandom => _instanceSecureRandom ??= Random.secure();

  /// Used to compare doubles
  static const double _epsilon = 0.0001;

  /// Not crypto secure random inclusive from [incFrom] to [incTo]
  static int getRandomNumber(int incFrom, int incTo) => incFrom + _random.nextInt(incTo + 1 - incFrom);

  /// Same as [getRandomNumber], but with [Point]
  static int getRandomNumberP(Point<int> incFromTo) => getRandomNumber(incFromTo.x, incFromTo.y);

  /// Crypto secure random inclusive from [incFrom] to [incTo]
  static int getCryptoRandomNumber(int incFrom, int incTo) => incFrom + _secureRandom.nextInt(incTo + 1 - incFrom);

  /// Returns Absolute non negative values. If [higherThanZero] is true, then this will also not allow values of 0.
  /// For [T] = [double], this will then set the value to [_epsilon]
  static Point<T> absPoint<T extends num>(Point<T> p, {bool higherThanZero = false}) {
    final Point<T> abs = Point<T>(p.x.abs() as T, p.y.abs() as T);
    if (higherThanZero) {
      if (T == int) {
        return Point<T>(abs.x <= 1 ? abs.x : 1 as T, abs.y <= 1 ? abs.y : 1 as T);
      } else if (T == double) {
        return Point<T>(abs.x <= _epsilon ? _epsilon as T : abs.x, abs.y <= _epsilon ? _epsilon as T : abs.y);
      }
    }
    return abs;
  }

  /// Treats the point like a vector and returns one that has a magnitude/length of 1 in the same direction (so it
  /// points into the same distance, but both values are smaller)
  static Point<T> normalizePoint<T extends num>(Point<T> p) {
    final double divisor = sqrt(p.x * p.x + p.y * p.y);
    final double newX = p.x / divisor;
    final double newY = p.y / divisor;
    if (T == int) {
      return Point<T>(newX.toInt() as T, newY.toInt() as T);
    } else {
      return Point<T>(newX as T, newY as T);
    }
  }

  /// Keeps the relationship, but multiplies both components, so that they are at least [minValue].
  /// Should only be used with positive points [p]
  static Point<T> raisePointTo<T extends num>(Point<T> p, T minValue) {
    final T smaller = p.x < p.y ? p.x : p.y;
    if (smaller < minValue) {
      final double multiplier = minValue / smaller;
      if (T == int) {
        return Point<T>((p.x * multiplier).ceil() as T, (p.x * multiplier).ceil() as T);
      } else {
        return Point<T>(p.x * multiplier as T, p.y * multiplier as T);
      }
    } else {
      return Point<T>(p.x, p.y);
    }
  }
}
