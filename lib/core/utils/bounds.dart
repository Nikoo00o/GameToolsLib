import 'dart:math' show Point;
import 'dart:ui';
import 'package:game_tools_lib/core/utils/num_utils.dart';
import 'package:game_tools_lib/domain/entities/base/model.dart';

export 'package:game_tools_lib/core/utils/num_utils.dart';

/// Either Point + size based access with [x], [y], [width], [height].
/// Or Sides access with [left], [top], [right], [bottom]. Important: this class is half open like [Rect], so only
/// [left]/[top] contain positions inside of this and [right]/[bottom] would be the outside borders!
/// Also provides [scale] with doubles and the +/- operators with other bounds to change all members.
/// To only return new bounds with changed [pos], use [move] instead.
/// Also contains other utility functions like [contains]
/// The Comparison Operator may also return true for different types for [T] if the values are equal!
/// And this class is immutable (like an entity, but for better performance not extending it), so members cannot be
/// changed! Also Supports JSON Conversion if needed!
final class Bounds<T extends num> implements Model {
  final Point<T> pos;
  final Point<T> size;

  factory Bounds({required T x, required T y, required T width, required T height}) {
    return Bounds<T>.pos(pos: Point<T>(x, y), size: Point<T>(width, height));
  }

  factory Bounds.sides({required T left, required T top, required T right, required T bottom}) {
    return Bounds<T>.pos(pos: Point<T>(left, top), size: Point<T>(right - left as T, bottom - top as T));
  }

  const Bounds.pos({required this.pos, required this.size});

  /// [pos.x]
  T get x => pos.x;

  /// [pos.y]
  T get y => pos.y;

  /// [size.x]
  T get width => size.x;

  /// [size.y]
  T get height => size.y;

  /// Returns [x] as the most left position inside
  T get left => x;

  /// Returns [y] as the most top position inside
  T get top => y;

  /// Returns [x] + [width] as the right side outer border (so not logically inside!)
  T get right => pos.x + size.x as T;

  /// Returns [y] + [height] as the bottom side outer border (so not logically inside!)
  T get bottom => pos.y + size.y as T;

  /// Returns [x] + [width], [y] + [height]
  Point<T> get middlePos {
    if (T == int) {
      return Point<T>((x + width / 2).round() as T, (y + height / 2).round() as T);
    }
    return Point<T>((x + width / 2.0) as T, (y + height / 2.0) as T);
  }

  Bounds<T> operator +(Bounds<T> other) => Bounds<T>.pos(pos: pos + other.pos, size: size + other.size);

  Bounds<T> operator -(Bounds<T> other) => Bounds<T>.pos(pos: pos - other.pos, size: size - other.size);

  /// Multiplies both [pos] and [size] with [scaleX] and [scaleY] for [Point.x] and [Point.y]
  Bounds<T> scale(double scaleX, double scaleY) =>
      Bounds<T>.pos(pos: pos.scale(scaleX, scaleY), size: size.scale(scaleX, scaleY));

  /// Returns a modified copy where [addX] is added to [x] and [addY] is added to [y]
  Bounds<T> move(T addX, T addY) => Bounds<T>.pos(pos: pos.move(addX, addY), size: size);

  /// Same as [move], but with [Point] [add] added instead
  Bounds<T> moveP(Point<T> add) => move(add.x, add.y);

  /// Returns true if [p] is within the area of this
  bool contains(Point<T> p) {
    if (T == double) {
      if ((p.x as double).isLessThan(left as double) || (p.x as double).isMoreOrEqualThan(right as double)) {
        return false;
      }
      if ((p.y as double).isLessThan(top as double) || (p.y as double).isMoreOrEqualThan(bottom as double)) {
        return false;
      }
      return true;
    }
    return p.x >= left && p.x < right && p.y >= top && p.y < bottom;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bounds && x == other.x && y == other.y && width == other.width && height == other.height;

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() => "Bounds(l: $left, t: $top, r: $right, b: $bottom)";

  String toStringAsPos() => "x: $x, y: $y,     width: $width, height: $height";

  static const String JSON_POS = "Position";
  static const String JSON_SIZE = "Size";

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{JSON_POS: pos.toJson(), JSON_SIZE: size.toJson()};

  factory Bounds.fromJson(Map<String, dynamic> json) => Bounds<T>.pos(
    pos: PointExtension.fromJson<T>(json[JSON_POS] as Map<String, dynamic>),
    size: PointExtension.fromJson<T>(json[JSON_SIZE] as Map<String, dynamic>),
  );
}
