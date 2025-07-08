import 'dart:math' show Point;

/// Either Point + size based access with [x], [y], [width], [height]
/// Or Sides access with [left], [top], [right], [bottom]
final class Bounds<T extends num> {
  final Point<T> pos;
  final Point<T> size;

  factory Bounds({required T x, required T y, required T width, required T height}) {
    return Bounds<T>.pos(pos: Point<T>(x, y), size: Point<T>(width, height));
  }

  factory Bounds.sides({required T left, required T top, required T right, required T bottom}) {
    return Bounds<T>.pos(pos: Point<T>(left, top), size: Point<T>(right - left as T, bottom - top as T));
  }

  const Bounds.pos({required this.pos, required this.size});

  T get x => pos.x;

  T get y => pos.y;

  T get width => size.x;

  T get height => size.y;

  /// returns [pos.x]
  T get left => x;

  /// returns [pos.y]
  T get top => y;

  /// returns [pos.x] + [size.x]
  T get right => x + width as T;

  /// returns [pos.y] + [size.y]
  T get bottom => y + height as T;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bounds &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() {
    return "{x: $x, y: $y, width: $width, height: $height}";
  }
}
