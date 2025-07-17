import 'dart:math' show Point, min, max;
import 'dart:ui' show Color;

import 'package:flutter/services.dart' show Clipboard, ClipboardData, LogicalKeyboardKey, PlatformException;
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/enums/input_enums.dart';
import 'package:game_tools_lib/core/enums/native_image_type.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/bounds.dart';
import 'package:game_tools_lib/core/utils/utils.dart' show Utils;
import 'package:game_tools_lib/data/native/native_image.dart';
import 'package:game_tools_lib/data/native/native_window.dart';
import 'package:game_tools_lib/domain/entities/model.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

part 'package:game_tools_lib/data/game/input_manager.dart';

part 'package:game_tools_lib/core/enums/board_key.dart';

/// This offers static methods like [GameWindow.mainDisplayWidth] to interact with the full native screen/display, but
/// also member methods to interact with the specific window names [name] like [getWindowBounds], or [getImage]
/// which can be accessed with for example [GameToolsLib.mainGameWindow], or the list of windows!
/// You can have multiple instances of this, but you can also change the [name] by calling [rename] to find a
/// different window. Remember that objects of this only work if they have been passed to the
/// [GameToolsLib.initGameToolsLib] method as a parameter!
///
/// To interact with the input of the game in more detail, look at [InputManager] with for example
/// [InputManager.leftClick], [InputManager.keyPress], [InputManager.isKeyDown], [InputManager.isMouseDown]. Here you
/// can only use the methods: [getPixelOfWindow], [isWithinWindow], [windowMousePos] and [moveMouse]
final class GameWindow {
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
  /// Also waits [FixedConfig.tinyDelayMS] maximum afterwards!
  Future<void> rename(String newName) async {
    _name = newName;
    _init();
    await Utils.delayMS(FixedConfig.fixedConfig.tinyDelayMS.y);
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
  /// May throw a [WindowClosedException] if the window was not open or if you don't have the correct permissions to
  /// interact with the window.
  /// Also waits [FixedConfig.tinyDelayMS] maximum afterwards!
  Future<void> setWindowFocus() async {
    final bool success = _nativeWindow.setWindowFocus(_windowID);
    if (success == false) {
      throw WindowClosedException(message: "Cant set window focus: $_windowID:");
    }
    await Utils.delayMS(FixedConfig.fixedConfig.tinyDelayMS.y);
  }

  /// The window's top left corner is ([Bounds.x], [Bounds.y]) and then it expands to ([Bounds.width], [Bounds.height]).
  /// May throw a [WindowClosedException] if the window was not open.
  ///
  /// Important: the [getWindowBounds] would also include a top window border in its height while all other methods
  /// like [getImage], [windowMousePos], [getPixelOfWindow] ignore those borders and
  /// only access space inside of the window!
  Bounds<int> getWindowBounds() {
    final Bounds<int>? bounds = _nativeWindow.getWindowBounds(_windowID);
    if (bounds == null) {
      throw WindowClosedException(message: "Cant get window bounds: $_windowID:");
    }
    return bounds;
  }

  /// The middle of the window in window space (so relative to top left corner of the window)
  ///
  /// If you instead want the middle pos in screen/display space, use [getWindowBounds].[Bounds.middlePos]
  /// instead
  Point<int> getMiddle() {
    final Bounds<int> bounds = getWindowBounds();
    return bounds.size.scaleB(0.5);
  }

  /// Returns a cropped Sub Image relative to top left corner of the window.
  /// May throw a [WindowClosedException] if the window was not open
  ///
  /// Important: uses mouse position relative to top left window border, but [GameWindow.getWindowBounds] would also
  /// include a top window border in its height which is not included here!
  ///
  /// Default for [type] is [NativeImageType.RGBA] to make no copy (see docs of the type for more).
  Future<NativeImage> getImage(
    int x,
    int y,
    int width,
    int height, [
    NativeImageType type = NativeImageType.RGBA,
  ]) async {
    final NativeImage? image = await _nativeWindow.getImageOfWindow(_windowID, x, y, width, height, type);
    if (image == null) {
      throw WindowClosedException(message: "Cant get image of window $_windowID: $x, $y, $width, $height");
    }
    return image;
  }

  /// Same as [getImage], but with [Bounds]
  Future<NativeImage> getImageB(Bounds<int> b, [NativeImageType type = NativeImageType.RGBA]) async =>
      getImage(b.x, b.y, b.width, b.height, type);

  /// Image of the whole full window (as a future!).
  /// May throw a [WindowClosedException] if the window was not open.
  /// Default for [type] is [NativeImageType.RGBA] to make no copy (see docs of the type for more).
  Future<NativeImage> getFullImage([NativeImageType type = NativeImageType.RGBA]) async {
    final NativeImage? image = await _nativeWindow.getFullWindow(_windowID, type);
    if (image == null) {
      throw WindowClosedException(message: "Cant get full image of window: $_windowID:");
    }
    return image;
  }

  /// Returns the full main display screen as an image.
  /// Default for [type] is [NativeImageType.RGBA] to make no copy (see docs of the type for more).
  static Future<NativeImage> getDisplayImage([NativeImageType type = NativeImageType.RGBA]) =>
      _nativeWindow.getFullMainDisplay(type);

  /// Returns the color of the pixel at [x], [y] relative to the top left corner of the window.
  /// May throw a [WindowClosedException] if the window was not open.
  /// Returns null if the position [x], [y] is outside of the window (see [isWithinWindow])!
  ///
  /// Important: uses mouse position relative to top left window border, but [GameWindow.getWindowBounds] would also
  /// include a top window border in its height which is not included here!
  ///
  /// To see rgb values from 0 to 255 as a string from color, use [Color.rgb].
  Color? getPixelOfWindow(int x, int y) {
    final Color? color = _nativeWindow.getPixelOfWindow(_windowID, x, y);
    if (color == null) {
      throw WindowClosedException(message: "Cant get pixel of window $_windowID: $x, $y");
    }
    if (isWithinWindow(Point<int>(x, y)) == false) {
      return null;
    }
    return color;
  }

  /// Same as [getPixelOfWindow], but with [Point]
  Color? getPixelOfWindowP(Point<int> p) => getPixelOfWindow(p.x, p.y);

  /// Returns if the [point] is inside of the visible space of the window (not a border at the top)
  /// This is not 100% correct, because it does not respect the invisible window borders and also not a window bar at
  /// the top (so its best used with borderless fullscreen applications)!
  /// Uses [getWindowBounds] to get height/width and could return false positives to the bottom right of the window!
  bool isWithinWindow(Point<int> point) {
    final Bounds<int> bounds = getWindowBounds();
    if (point.x < 0 || point.y < 0 || point.x >= bounds.width || point.y >= bounds.height) {
      return false;
    }
    return true;
  }

  /// Sets the mouse to ([x],[y]) relative to the top left corner of the window in natural slower way instead of just
  /// instantly setting the mouse pos. Prefer to use this method!
  ///
  /// Optionally use ([xRadius], [yRadius]) to move the mouse to a random pos in an area instead (with a +- offset
  /// around the middle point). You can also set a different [minMaxStepDelayInMS] on how long each
  /// step / mouse change should take in combination with a custom positive number of [minStepSize] and
  /// [maxStepSize] on how far the pos should be moved at a time.The default value for [minMaxStepDelayInMS]
  /// is [FixedConfig.tinyDelayMS].
  ///
  /// May throw a [WindowClosedException] if the window was not open.
  /// Affects both [windowMousePos] and [InputManager.displayMousePos]
  ///
  /// Important: uses mouse position relative to top left window border, but [GameWindow.getWindowBounds] would also
  /// include a top window border in its height which is not included here!
  ///
  /// Very Important: use at your own risk! some games, or anti cheats may not like forced mouse movements even if they
  /// don't do anything bad and could flag you for using this!
  Future<void> moveMouse(
    int x,
    int y, {
    int xRadius = 3,
    int yRadius = 3,
    Point<int>? minMaxStepDelayInMS,
    int minStepSize = 14,
    int maxStepSize = 18,
  }) async => InputManager.moveMouseInWindow(
    Point<int>(x, y),
    this,
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
      throw WindowClosedException(message: "Cant close window: $_windowID:");
    }
  }

  /// Returns the mouse position relative to the top left corner of the window.
  /// May throw a [WindowClosedException] if the window was not open.
  /// Returns [null] if the cursor is currently outside of the window (see [isWithinWindow])!
  ///
  /// Important: uses mouse position relative to top left window border, but [GameWindow.getWindowBounds] would also
  /// include a top window border in its height which is not included here!
  Point<int>? get windowMousePos => InputManager.getWindowMousePos(this);

  /// Full size of the whole screen
  static int get mainDisplayWidth => _nativeWindow.getMainDisplayWidth();

  /// Full size of the whole screen
  static int get mainDisplayHeight => _nativeWindow.getMainDisplayHeight();

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
