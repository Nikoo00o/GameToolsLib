import 'dart:math' show Point;
import 'dart:ui' show Color;

import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/Bounds.dart';
import 'package:game_tools_lib/core/utils/num_utils.dart';
import 'package:game_tools_lib/data/native/native_image.dart';
import 'package:game_tools_lib/data/native/native_window.dart' show NativeWindow;
import 'package:game_tools_lib/game_tools_lib.dart';

/// This offers static methods like [GameWindow.mainDisplayWidth] to interact with the full native screen/display, but
/// also member methods to interact with the specific window names [name] like [getWindowBounds], or [moveMouseP]
/// which can be accessed with for example [GameToolsLib.mainGameWindow], or the list of windows!
/// You can have multiple instances of this, but you can also change the [name] by calling [rename] to find a
/// different window. Remember that objects of this only work if they have been passed to the
/// [GameToolsLib.initGameToolsLib] method as a parameter!
base class GameWindow {
  /// This is set in the constructor only once and used to identify/find the window.
  /// Name Examples: "Path of Exile", "TL", "League of Legends".
  /// For Default windows it will be checked if the windowName is contained in the real name of the window
  /// This can be disabled by setting the config variable [MutableConfig.alwaysMatchGameWindowNamesEqual] to true.
  /// You can also [rename] this to search a different window
  String _name;

  /// This is set in the constructor only once and used to identify/find the window.
  /// Name Examples: "Path of Exile", "TL", "League of Legends".
  /// For Default windows it will be checked if the windowName is contained in the real name of the window.
  /// This can be disabled by setting the config variable [MutableConfig.alwaysMatchGameWindowNamesEqual] to true.
  /// You can also [rename] this to search a different window
  String get name => _name;

  /// Used to keep track of multiple windows
  late final int _windowID;
  static int _counterForWindowID = 0;
  static const int _maxWindowID = 999;

  /// Returns [NativeWindow.instance]
  static NativeWindow get _nativeWindow => NativeWindow.instance;

  /// Can throw [WindowClosedException] if the id is over [_maxWindowID]
  /// The initializing is done in [_init] which is called when this object is passed to [GameToolsLib.initGameToolsLib]
  GameWindow({
    required String name,
  }) : _name = name {
    _windowID = _counterForWindowID++;
    if (_windowID >= _maxWindowID) {
      throw WindowClosedException(message: "too many windows created, id is $_maxWindowID, or higher: $_windowID");
    }
  }

  /// Helper method to initialize the native window which is called once for every game window passed to the
  /// [GameToolsLib.initGameToolsLib] automatically! This will also prepare itself for the native window (does not
  /// lookup the window yet, gets config variables sync).
  /// This Can throw [WindowClosedException] if the [_nativeWindow] instance was not initialized yet! (which is done
  /// automatically in [GameToolsLib.initGameToolsLib]).
  /// Can also throw [ConfigException] if the config is corrupt. calls [_init]
  /// Afterwards all other member methods of this may be called!
  void _init() {
    final bool initResult = _nativeWindow.initWindow(
      windowID: _windowID,
      windowName: _name,
      alwaysMatchEqual: MutableConfig.mutableConfig.alwaysMatchGameWindowNamesEqual.cachedValueNotNull(),
      printWindowNames: MutableConfig.mutableConfig.debugPrintGameWindowNames.cachedValueNotNull(),
    );
    if (initResult == false) {
      throw WindowClosedException(message: "could not prepare $_name for native window with id $_windowID");
    }
  }

  /// Changes the name of this window and also initializes it again by calling [_init] to find a different window!
  /// Of course this will also unset the window handle and it has to be searched again (which is done automatically
  /// in the other functions). This should never throw a [WindowClosedException] at this point in theory.
  void rename(String newName) {
    _name = newName;
    _init();
  }

  /// Searches the window handle for the [_windowID] (or [name])
  bool isWindowOpen() {
    return _nativeWindow.isWindowOpen(_windowID);
  }

  /// If the user is tabbed into the [name] window (if the window is in the foreground)
  bool hasWindowFocus() {
    return _nativeWindow.hasWindowFocus(_windowID);
  }

  /// Changes focus (sets the window to the foreground).
  /// May throw a [WindowClosedException] if the window was not open.
  void setWindowFocus() {
    final bool success = _nativeWindow.setWindowFocus(_windowID);
    if (success == false) {
      throw WindowClosedException(message: "Cant set window focus");
    }
  }

  /// The window's top left corner is ([Bounds.x], [Bounds.y]) and then it expands to ([Bounds.width], [Bounds.height]).
  /// May throw a [WindowClosedException] if the window was not open.
  ///
  /// Important: the [getWindowBounds] would also include a top window border in its height while all other methods
  /// like [getImageOfWindow], [windowMousePos], [getPixelOfWindow] and [setWindowMousePos] ignore those borders and
  /// only access space inside of the window!
  Bounds<int> getWindowBounds() {
    final Bounds<int>? bounds = _nativeWindow.getWindowBounds(_windowID);
    if (bounds == null) {
      throw WindowClosedException(message: "Cant get window bounds");
    }
    return bounds;
  }

  /// Returns a cropped Sub Image relative to top left corner of the window.
  /// May throw a [WindowClosedException] if the window was not open
  ///
  /// Important: the [getWindowBounds] would also include a top window border in its height while all other methods
  /// like [getImageOfWindow], [windowMousePos], [getPixelOfWindow] and [setWindowMousePos] ignore those borders and
  /// only access space inside of the window!
  NativeImage getImageOfWindow(int x, int y, int width, int height) {
    final NativeImage? image = _nativeWindow.getImageOfWindow(_windowID, x, y, width, height);
    if (image == null) {
      throw WindowClosedException(message: "Cant get image of window $x, $y, $width, $height");
    }
    return image;
  }

  /// Same as [getImageOfWindow], but with [Bounds]
  NativeImage getImageOfWindowB(Bounds<int> b) => getImageOfWindow(b.x, b.y, b.width, b.height);

  /// Returns the color of the pixel at [x], [y] relative to the top left corner of the window.
  /// May throw a [WindowClosedException] if the window was not open.
  /// Returns null if the position [x], [y] is outside of the window (see [isWithinWindow])!
  ///
  /// Important: the [getWindowBounds] would also include a top window border in its height while all other methods
  /// like [getImageOfWindow], [windowMousePos], [getPixelOfWindow] and [setWindowMousePos] ignore those borders and
  /// only access space inside of the window!
  Color? getPixelOfWindow(int x, int y) {
    final Color? color = _nativeWindow.getPixelOfWindow(_windowID, x, y);
    if (color == null) {
      throw WindowClosedException(message: "Cant get pixel of window $x, $y");
    }
    if (isWithinWindow(Point<int>(x, y)) == false) {
      return null;
    }
    return color;
  }

  /// Same as [getPixelOfWindow], but with [Point]
  Color? getPixelOfWindowP(Point<int> p) => getPixelOfWindow(p.x, p.y);

  /// Same as [getPixelOfWindowP] with [windowMousePos]
  Color? getPixelAtCursor() {
    final Point<int>? cursor = windowMousePos;
    if (cursor == null) {
      return null;
    }
    return getPixelOfWindow(cursor.x, cursor.y);
  }

  /// Sets the mouse to [x], [y] relative to the top left corner of the window. Prefer to use [moveMouse] instead!
  /// May throw a [WindowClosedException] if the window was not open.
  /// Affects both [windowMousePos] and [displayMousePos]
  ///
  /// Important: the [getWindowBounds] would also include a top window border in its height while all other methods
  /// like [getImageOfWindow], [windowMousePos], [getPixelOfWindow] and [setWindowMousePos] ignore those borders and
  /// only access space inside of the window!
  void setWindowMousePos(int x, int y) {
    if (_nativeWindow.setWindowMousePos(_windowID, x, y) == false) {
      throw WindowClosedException(message: "Cant set mouse to pos in window: $x, $y");
    }
  }

  /// Sets the mouse to [point] relative to the top left corner of the window in natural slower way instead of just
  /// instantly setting the mouse pos. Prefer to use this method!
  ///
  /// Optionally use [offset] to move the mouse to a random pos in an area instead (where offset would be like the
  /// radius around point as the middle point). You can also set a different [minMaxStepDelayInMS] on how long each
  /// step / mouse change should take in combination with a custom positive number of [minStepSize] and
  /// [maxStepSize] on how far the pos should be moved at a time.The default value for [minMaxStepDelayInMS]
  /// is [FixedConfig.shortDelayMS].
  ///
  /// May throw a [WindowClosedException] if the window was not open.
  /// Affects both [windowMousePos] and [displayMousePos]
  ///
  /// Important: the [getWindowBounds] would also include a top window border in its height while all other methods
  /// like [getImageOfWindow], [windowMousePos], [getPixelOfWindow] and [setWindowMousePos] ignore those borders and
  /// only access space inside of the window!
  Future<void> moveMouseP(Point<int> point, {
    Point<int> offset = const Point<int>(2, 2),
    Point<int>? minMaxStepDelayInMS,
    int minStepSize = 7,
    int maxStepSize = 19,
  }) async {
    final Point<int> startPoint = windowMousePos ?? const Point<int>(0, 0);
    minMaxStepDelayInMS ??= FixedConfig.fixedConfig.shortDelayMS; // default value for delay
    int currentX = startPoint.x; // calculate start and target
    int currentY = startPoint.y;
    int targetX = NumUtils.getRandomNumber(point.x - offset.x, point.x + offset.x);
    if (point.x >= 0 && targetX < 0) {
      targetX = 0;
    }
    int targetY = NumUtils.getRandomNumber(point.y - offset.y, point.y + offset.y);
    if (point.y >= 0 && targetY < 0) {
      targetY = 0;
    }
    bool xToRight = true; // in which direction to move
    bool yToBot = true;
    if ((targetX - currentX) < 0) {
      xToRight = false; // move left on x (so negative)
    }
    if ((targetY - currentY) < 0) {
      yToBot = false; // move left on y (so negative)
    }
    // now calculate general step vector from distance
    final Point<double> distance = Point<double>((targetX - currentX).toDouble(), (targetY - currentY).toDouble());
    final Point<double> normalized = NumUtils.normalizePoint(NumUtils.absPoint(distance, higherThanZero: true));
    final Point<double> stepXY = NumUtils.raisePointTo(normalized, 1.0);

    // and set specific step min max values
    final Point<int> xStep = Point<int>((stepXY.x * minStepSize).ceil(), (stepXY.x * maxStepSize).ceil());
    final Point<int> yStep = Point<int>((stepXY.y * minStepSize).ceil(), (stepXY.y * maxStepSize).ceil());

    bool xDone = false; // next set loop guards and start loop
    bool yDone = false;
    while (true) {
      if (!xDone) {
        currentX += xToRight ? NumUtils.getRandomNumberP(xStep) : -NumUtils.getRandomNumberP(xStep);
        if (xToRight) {
          if (currentX >= targetX) {
            currentX = targetX;
            xDone = true;
          }
        } else if (currentX < targetX) {
          currentX = targetX;
          xDone = true;
        }
      }
      if (!yDone) {
        currentY += yToBot ? NumUtils.getRandomNumberP(yStep) : -NumUtils.getRandomNumberP(yStep);
        if (yToBot) {
          if (currentY >= targetY) {
            currentY = targetY;
            yDone = true;
          }
        } else if (currentY < targetY) {
          currentY = targetY;
          yDone = true;
        }
      }
      setWindowMousePos(currentX, currentY);
      if (xDone && yDone) {
        break;
      }
      await Future<void>.delayed(Duration(milliseconds: NumUtils.getRandomNumberP(minMaxStepDelayInMS)));
    }
  }

  /// Same as [moveMouseP]
  Future<void> moveMouse(int x,
      int y, {
        int xRadius = 2,
        int yRadius = 2,
        Point<int>? minMaxStepDelayInMS,
        int minStepSize = 7,
        int maxStepSize = 19,
      }) async =>
      moveMouseP(
        Point<int>(x, y),
        offset: Point<int>(xRadius, yRadius),
        minMaxStepDelayInMS: minMaxStepDelayInMS,
        minStepSize: minStepSize,
        maxStepSize: maxStepSize,
      );

  /// Closes the target window.
  /// May throw a [WindowClosedException] if the window was not open
  void closeWindow() {
    final bool success = _nativeWindow.closeWindow(_windowID);
    if (success == false) {
      throw WindowClosedException(message: "Cant close window");
    }
  }

  /// Image of the whole full window.
  /// May throw a [WindowClosedException] if the window was not open
  NativeImage get windowFullImage {
    final NativeImage? image = _nativeWindow.getFullWindow(_windowID);
    if (image == null) {
      throw WindowClosedException(message: "Cant get full image of window");
    }
    return image;
  }

  /// Returns the mouse position relative to the top left corner of the window.
  /// May throw a [WindowClosedException] if the window was not open.
  /// Returns [null] if the cursor is currently outside of the window (see [isWithinWindow])!
  ///
  /// Important: the [getWindowBounds] would also include a top window border in its height while all other methods
  /// like [getImageOfWindow], [windowMousePos], [getPixelOfWindow] and [setWindowMousePos] ignore those borders and
  /// only access space inside of the window!
  Point<int>? get windowMousePos {
    final Point<int>? pos = _nativeWindow.getWindowMousePos(_windowID);
    if (pos == null) {
      throw WindowClosedException(message: "Cant get mouse pos inside window");
    }
    if (isWithinWindow(pos) == false) {
      return null;
    }
    return pos;
  }

  /// Returns if the [point] is inside of the visible space of the window (not a border at the top)
  /// This is not 100% correct, because it does not respect the invisible window borders and also not a window bar at
  /// the top (so its best used with borderless fullscreen applications)!
  /// Uses [getWindowBounds]!
  bool isWithinWindow(Point<int> point) {
    final Bounds<int> bounds = getWindowBounds();
    if (point.x < 0 || point.y < 0 || point.x > bounds.width || point.y > bounds.height) {
      return false;
    }
    return true;
  }

  /// Same as [setWindowMousePos], but with [Point]
  /// Using [null] as [pos] has no effect.
  set windowMousePos(Point<int>? pos) {
    if (pos != null) {
      setWindowMousePos(pos.x, pos.y);
    }
  }

  /// Full size of the whole screen
  static int get mainDisplayWidth => _nativeWindow.getMainDisplayWidth();

  /// Full size of the whole screen
  static int get mainDisplayHeight => _nativeWindow.getMainDisplayHeight();

  /// Image of the full main display screen
  static NativeImage get mainDisplayFullImage => _nativeWindow.getFullMainDisplay();

  /// Sets the mouse to [x], [y] relative to the top left corner of the full display screen.
  /// Affects both [windowMousePos] and [displayMousePos].
  /// Prefer to use [moveMouse] instead.
  static void setDisplayMousePos(int x, int y) {
    _nativeWindow.setDisplayMousePos(x, y);
  }

  /// Returns the mouse position relative to the top left corner of the full display screen
  static Point<int> get displayMousePos => _nativeWindow.getDisplayMousePos();

  /// Same as [setDisplayMousePos], but with [Point]
  static set displayMousePos(Point<int> pos) => setDisplayMousePos(pos.x, pos.y);

  /// This needs to be called when one of each config variables changes to update the native code:
  /// [alwaysMatchEqual] controls how the window names will be matched ([false] = the window title only has to
  /// contain the [GameWindow.name]. Otherwise if [true] it has to be exactly the same)
  /// [printWindowNames] is a debug variable to print out all opened windows if set to true
  static void updateConfigVariables({required bool alwaysMatchEqual, required bool printWindowNames}) {
    _nativeWindow.initWindow(
      windowID: _maxWindowID,
      windowName: "USED_FOR_CONFIG",
      alwaysMatchEqual: alwaysMatchEqual,
      printWindowNames: printWindowNames,
    );
  }
}
