import 'dart:math' show Point;
import 'dart:ui' show Rect;
import 'package:game_tools_lib/core/utils/bounds.dart';
import 'package:game_tools_lib/domain/entities/base/model.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

/// This is the same as the [Bounds] class (look at doc comments there!), but also resolution aware.
///
/// All methods of [Bounds] are mirrored here and will be affected by the [unscaledBounds], but they will also be
/// scaled by the [creationWidth] and [creationHeight] in relation to [GameWindow.size] of the current [gameWindow]
/// for this!  Additionally also contains a [scaledBounds] getter.
///
/// For example if this was created with 2560x1440 resolution as [creationWidth]/ [creationHeight] of the window at
/// the [unscaledBounds] pos (10, 10) with size (20, 20) and the resolution of the [gameWindow] changes to 1280x720,
/// then [x] / [y] would return 5 and [width] / [height] would return 10!
///
/// Instead of all the operators and methods for modifying bounds, here only [move] is given!
/// The [gameWindow] is not used in comparison and also not in json conversion!
final class ScaledBounds<T extends num> implements Model {
  /// The initial unscaled bounds that should be used as a baseline for scaling with the initial [creationWidth] and
  /// [creationHeight]
  final Bounds<T> unscaledBounds;

  /// The initial width of the related window that this was created with which is the baseline for any scaling for
  /// [unscaledBounds]
  late final int creationWidth;

  /// The initial height of the related window that this was created with which is the baseline for any scaling for
  /// [unscaledBounds]
  late final int creationHeight;

  /// Reference to the window this is related to (most of the times just the default [GameToolsLib.mainGameWindow])
  final GameWindow gameWindow;

  /// [gameWindow] defaults to [GameToolsLib.mainGameWindow] if null.
  ///
  /// [creationWidth] and [creationHeight] may be null and then the size will be taken from the [gameWindow].
  ScaledBounds(
    this.unscaledBounds, {
    required int? creationWidth,
    required int? creationHeight,
    GameWindow? gameWindow,
  }) : gameWindow = gameWindow ?? GameToolsLib.mainGameWindow {
    this.creationWidth = creationWidth ?? this.gameWindow.width;
    this.creationHeight = creationHeight ?? this.gameWindow.height;
  }

  /// The (x, y) scale factor for the current [gameWindow]'s [GameWindow.size] in relation to the initial
  /// [creationWidth] and [creationHeight].
  ///
  /// So for example [gameWindow.width] / [creationWidth]
  Point<double> get scaleFactor => Point<double>(gameWindow.width / creationWidth, gameWindow.height / creationHeight);

  /// See [scaleFactor]
  double get scaleFactorX => gameWindow.width / creationWidth;

  /// See [scaleFactor]
  double get scaleFactorY => gameWindow.height / creationHeight;

  T _scaleX(T input) {
    if (T == int) {
      return (input * scaleFactorX).round() as T;
    }
    return input * scaleFactorX as T;
  }

  T _scaleY(T input) {
    if (T == int) {
      return (input * scaleFactorY).round() as T;
    }
    return input * scaleFactorY as T;
  }

  /// Returns the [unscaledBounds] scaled by [scaleFactor].
  ///
  /// For better precision you can also use [scaledBoundsD]
  Bounds<T> get scaledBounds {
    final Point<double> scaleFactor = this.scaleFactor;
    return unscaledBounds.scale(scaleFactor.x, scaleFactor.y);
  }

  /// Returns the [scaledBounds] as [double]
  Bounds<double> get scaledBoundsD {
    final Point<double> scaleFactor = this.scaleFactor;
    final Bounds<double> doubleBounds = Bounds<double>(
      x: unscaledBounds.x.toDouble(),
      y: unscaledBounds.y.toDouble(),
      width: unscaledBounds.width.toDouble(),
      height: unscaledBounds.height.toDouble(),
    );
    return doubleBounds.scale(scaleFactor.x, scaleFactor.y);
  }

  /// Accesses [unscaledBounds] scaled by [scaleFactor]!
  T get x => _scaleX(unscaledBounds.x);

  /// Accesses [unscaledBounds] scaled by [scaleFactor]!
  T get y => _scaleY(unscaledBounds.y);

  /// Accesses [unscaledBounds] scaled by [scaleFactor]!
  T get width => _scaleX(unscaledBounds.width);

  /// Accesses [unscaledBounds] scaled by [scaleFactor]!
  T get height => _scaleY(unscaledBounds.height);

  /// Accesses [unscaledBounds] scaled by [scaleFactor]!
  T get left => x;

  /// Accesses [unscaledBounds] scaled by [scaleFactor]!
  T get top => y;

  /// Accesses [unscaledBounds] scaled by [scaleFactor]!
  T get right => x + width as T;

  /// Accesses [unscaledBounds] scaled by [scaleFactor]!
  T get bottom => y + height as T;

  /// Accesses [unscaledBounds] scaled by [scaleFactor]!
  Point<T> get middlePos => scaledBounds.middlePos;

  /// This will modify the [unscaledBounds] to set them to [newPos], but it will also set [creationWidth] and
  /// [creationHeight] to the current [GameWindow.size] of the current [gameWindow]!
  ScaledBounds<T> move(Bounds<T> newPos) => ScaledBounds<T>(
    newPos,
    creationWidth: gameWindow.width,
    creationHeight: gameWindow.height,
    gameWindow: gameWindow,
  );

  /// Returns true if [p] is within the area of this
  bool contains(Point<T> p) => scaledBounds.contains(p);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScaledBounds &&
          unscaledBounds == other.unscaledBounds &&
          creationWidth == other.creationWidth &&
          creationHeight == other.creationHeight;

  @override
  int get hashCode => Object.hash(x, y, width, height, creationWidth, creationHeight);

  @override
  String toString() => "ScaledBounds(unscaled: $unscaledBounds, creation: ($creationWidth, $creationHeight))";

  /// Scaling is applied here!
  String toStringAsPos() => "x: $x, y: $y,     width: $width, height: $height";

  static const String JSON_BOUNDS = "Bounds";
  static const String JSON_CREATION_WIDTH = "Creation Width";
  static const String JSON_CREATION_HEIGHT = "Creation Height";

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    JSON_BOUNDS: unscaledBounds.toJson(),
    JSON_CREATION_WIDTH: creationWidth,
    JSON_CREATION_HEIGHT: creationHeight,
  };

  factory ScaledBounds.fromJson(Map<String, dynamic> json) => ScaledBounds<T>(
    Bounds<T>.fromJson(json[JSON_BOUNDS] as Map<String, dynamic>),
    creationWidth: json[JSON_CREATION_WIDTH] as int,
    creationHeight: json[JSON_CREATION_HEIGHT] as int,
  );

  /// Converts the [scaledBounds] to a UI [Rect] for drawing!
  Rect toRect() {
    final Bounds<T> bounds = scaledBounds;
    return Rect.fromLTRB(
      bounds.left.toDouble(),
      bounds.top.toDouble(),
      bounds.right.toDouble(),
      bounds.bottom.toDouble(),
    );
  }
}
