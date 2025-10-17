import 'dart:math' show Point, min, max;

import 'package:flutter/services.dart' show Clipboard, ClipboardData, LogicalKeyboardKey, PlatformException;
import 'package:flutter/widgets.dart';
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/enums/input/input_enums.dart';
import 'package:game_tools_lib/core/enums/native_image_type.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/bounds.dart';
import 'package:game_tools_lib/core/utils/utils.dart' show Utils;
import 'package:game_tools_lib/data/native/native_image.dart';
import 'package:game_tools_lib/data/native/native_overlay_window.dart';
import 'package:game_tools_lib/data/native/native_window.dart';
import 'package:game_tools_lib/domain/entities/base/model.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:provider/provider.dart';

part 'package:game_tools_lib/domain/game/input_manager.dart';

part 'package:game_tools_lib/core/enums/input/board_key.dart';

/// This offers static methods like [GameWindow.mainDisplayWidth] to interact with the full native screen/display, but
/// also member methods to interact with the specific window names [name] like [getWindowBounds], or [getImage]
/// which can be accessed with for example [GameToolsLib.mainGameWindow], or the list of windows!
/// You can have multiple instances of this, but you can also change the [name] by calling [rename] to find a
/// different window. Remember that objects of this only work if they have been passed to the
/// [GameToolsLib.initGameToolsLib] method as a parameter (and [init] and [updateConfigVariables] will be called for them!
///
/// To interact with the input of the game in more detail, look at [InputManager] with for example
/// [InputManager.leftClick], [InputManager.keyPress], [InputManager.isKeyDown], [InputManager.isMouseDown].
///
/// Here you can only use the methods: [getPixelOfWindow], [isWithinWindow] / [isWithinInnerWindow], [windowMousePos]
/// and [moveMouse] for  inputs and you can also check if the window [isOpen], or [hasFocus], or [size] (or if you
/// don't want to wait for the loop, [updateAndGetOpen] and [updateAndGetFocus] and [updateAndGetSize]).
///
/// UI App elements can also use this as a [ChangeNotifier] in a [ChangeNotifierProvider] to listen to changes from
/// [name], [isOpen] and [hasFocus] updated from [rename], [updateOpen], [updateFocus], but also [size] with
/// [width] / [height] updated from [updateSize].
///
/// Remember that [size] returns the inner size of the window and [getWindowBounds] returns the outer positions in
/// relation to the screen/display!
///
/// For comparison the [operator==] only compares the [name] of this window!
final class GameWindow with ChangeNotifier {
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

  bool _isOpen = false;

  /// if this window with the [name] is currently open (initially false).
  /// To update this, [updateFocus] is used in the event loop.
  bool get isOpen => _isOpen;

  bool _hasFocus = false;

  /// If the user is tabbed into the [name] window (if the window is in the foreground. initially false).
  /// To update this, [updateOpen] is used in the event loop.
  bool get hasFocus => _hasFocus;

  Point<int>? _size;

  /// Returns the inner size of this window which is worked with in all inner methods in contrast to the outer
  /// [getWindowBounds]! If the window is not open, then this will return null!
  /// To update this, [updateSize] is used in the event loop.
  ///
  /// Does not include the top bar (title bar) for windowed mode windows!
  Point<int>? get size => isOpen ? _size : null;

  /// Returns the width of [size] (look at doc comments there!).
  ///
  /// May throw a [WindowClosedException] if the window was not open.
  int get width {
    if (size == null) {
      throw WindowClosedException(message: "Cant get window size for $this");
    }
    return size!.x;
  }

  /// Returns the height of [size] (look at doc comments there!).
  ///
  /// May throw a [WindowClosedException] if the window was not open.
  ///
  /// Does not include the top bar (title bar) for windowed mode windows!
  int get height {
    if (size == null) {
      throw WindowClosedException(message: "Cant get window size for $this");
    }
    return size!.y;
  }

  /// Used to keep track of multiple windows
  late final int _windowID;
  static int _counterForWindowID = 0;
  static const int _maxWindowID = 999;

  /// Returns [NativeWindow.instance]
  static NativeWindow get _nativeWindow => NativeWindow.instance;

  /// Can throw [WindowClosedException] if the id is over [_maxWindowID]
  /// The initializing is done in [init] which is called when this object is passed to [GameToolsLib.initGameToolsLib]
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
  /// Can also throw [ConfigException] if the config is corrupt.
  /// Afterwards all other member methods of this may be called!
  void init() {
    final bool initResult = _nativeWindow.initWindow(windowID: _windowID, windowName: _name); // verbose log init
    if (initResult == false) {
      throw WindowClosedException(message: "could not prepare $_name for native window with id $_windowID");
    }
  }

  /// Changes the name of this window and also initializes it again by calling [init] to find a different window!
  /// Of course this will also unset the window handle and it has to be searched again (which is done automatically
  /// in the other functions). This should never throw a [WindowClosedException] at this point in theory.
  /// Also waits [FixedConfig.tinyDelayMS] maximum afterwards!
  Future<void> rename(String newName) async {
    if (newName != _name) {
      Logger.verbose("Renaming $this to $newName");
      _name = newName;
      init();
      await Utils.delayMS(FixedConfig.fixedConfig.tinyDelayMS.y);
    }
  }

  /// Updates the [isOpen] (needs to search the window handle for it) and returns 1 if the open was different before
  /// and has changed. Otherwise if nothing changed, this returns 0. This is called periodically in the internal event
  /// loop!
  /// If the window had focus and is closed, then this will also update [_hasFocus] and return 2 instead!
  int updateOpen() {
    final bool oldOpen = _isOpen;
    _isOpen = _nativeWindow.isWindowOpen(_windowID);
    final bool wasChanged = oldOpen != _isOpen;
    if (wasChanged) {
      if (_isOpen == false && _hasFocus) {
        _hasFocus = false;
        return 2;
      }
      notifyListeners();
    }
    return wasChanged ? 1 : 0;
  }

  /// Updates the [hasFocus] (needs to search the window handle for it) and returns if the focus was different before
  /// and has changed. This is called periodically in the internal event loop!
  bool updateFocus() {
    final bool oldFocus = _hasFocus;
    _hasFocus = _nativeWindow.hasWindowFocus(_windowID);
    final bool wasChanged = oldFocus != _hasFocus;
    if (wasChanged) {
      notifyListeners();
    }
    return wasChanged;
  }

  /// Mainly used for testing, combines [updateOpen] and [isOpen]
  bool updateAndGetOpen() {
    updateOpen();
    return isOpen;
  }

  /// Mainly used for testing, combines [updateFocus] and [hasFocus]
  bool updateAndGetFocus() {
    updateFocus();
    return hasFocus;
  }

  /// Changes focus (sets the window to the foreground).
  /// May throw a [WindowClosedException] if the window was not open or if you don't have the correct permissions to
  /// interact with the window.
  /// Also waits [FixedConfig.tinyDelayMS] maximum afterwards!
  Future<void> setWindowFocus() async {
    final bool success = _nativeWindow.setWindowFocus(_windowID);
    if (success == false) {
      throw WindowClosedException(message: "Cant set window focus for $this");
    }
    await Utils.delayMS(FixedConfig.fixedConfig.tinyDelayMS.y);
  }

  /// Updates the [size] (needs to search the window handle for it) and returns if the size was different before
  /// and has changed. This is called periodically in the internal event loop!
  bool updateSize() {
    final Point<int>? oldSize = _size;
    _size = _nativeWindow.getWindowSize(_windowID);
    final bool wasChanged = oldSize != _size;
    if (wasChanged) {
      notifyListeners();
    }
    return wasChanged;
  }

  /// Mainly used for testing, combines [updateSize] and [size]
  Point<int>? updateAndGetSize() {
    updateSize();
    return size;
  }

  /// The window's top left corner is ([Bounds.x], [Bounds.y]) and then it expands to ([Bounds.width], [Bounds.height]).
  /// May throw a [WindowClosedException] if the window was not open.
  ///
  /// Important: the [getWindowBounds] would also include a top window border in its height while all other methods
  /// like [getImage], [windowMousePos], [getPixelOfWindow], [size], [width], [height], [getMiddle], etc ignore those
  /// borders and  only access space inside of the window!
  ///
  /// So to get the inner size of this window or work inside of it, use [size] instead!!! This is only for
  /// screen/display related stuff!
  Bounds<int> getWindowBounds() {
    final Bounds<int>? bounds = _nativeWindow.getWindowBounds(_windowID);
    if (bounds == null) {
      throw WindowClosedException(message: "Cant get window bounds for $this");
    }
    return bounds;
  }

  /// The middle of the window in window space (so relative to top left corner of the window)
  ///
  /// If you instead want the middle pos in screen/display space, use [getWindowBounds].[Bounds.middlePos]
  /// instead
  Point<int> getMiddle() {
    if (size == null) {
      throw WindowClosedException(message: "Cant get window size for $this");
    }
    return size!.scaleB(0.5);
  }

  /// Returns a cropped Sub Image relative to top left corner of the window (part of a screenshot).
  /// May throw a [WindowClosedException] if the window was not open. This inner image will not contain any top
  /// bar, or side borders and uses [NativeOverlayWindow.getInnerOverlayAreaForWindow] for it!
  ///
  /// Important: uses mouse position relative to top left window border, but [GameWindow.getWindowBounds] would also
  /// include a top window border in its height which is not included here!
  ///
  /// Default for [type] is [NativeImageType.RGBA] to make no copy (see docs of the type for more).
  ///
  /// [width] and [height] are nullable and will expand to the end of the window if null!
  ///
  /// Remember that this image might be obscured by your overlay, as an alternative you can use flickering and delayed
  /// [OverlayManager.getWindowImageWithoutOverlay] (should not be used often!)!
  Future<NativeImage> getImage(
    int x,
    int y,
    int? width,
    int? height, [
    NativeImageType type = NativeImageType.RGBA,
  ]) async {
    final Bounds<int> innerBounds = NativeOverlayWindow.getInnerOverlayAreaForWindow(this);
    final int finalWidth = width ?? (innerBounds.width - x);
    final int finalHeight = height ?? (innerBounds.height - y);

    final NativeImage? image = await _nativeWindow.getImageOfWindow(
      _windowID,
      innerBounds.x + x,
      innerBounds.y + y,
      finalWidth,
      finalHeight,
      type,
    );
    if (image == null) {
      throw WindowClosedException(message: "Cant get image of window $this: $x, $y, $width, $height");
    }
    return image;
  }

  /// Same as [getImage], but with [Bounds]
  Future<NativeImage> getImageB(Bounds<int> b, [NativeImageType type = NativeImageType.RGBA]) async =>
      getImage(b.x, b.y, b.width, b.height, type);

  /// Image or screenshot of the whole full inner window window (as a future!) per default if [includeBorders] is
  /// false, so the area from 0, 0 to [size] that is also used for the overlay window, etc. In that case [getImage]
  /// is used. But if [includeBorders] is true, it will use the full outer [getWindowBounds] instead to also include
  /// top bar and border shadow spaces, etc.
  /// May throw a [WindowClosedException] if the window was not open.
  /// Default for [type] is [NativeImageType.RGBA] to make no copy (see docs of the type for more).
  ///
  /// Remember that this image might be obscured by your overlay, as an alternative you can use flickering and delayed
  /// [OverlayManager.getWindowImageWithoutOverlay] (should not be used often!)!
  Future<NativeImage> getFullImage({NativeImageType type = NativeImageType.RGBA, bool includeBorders = false}) async {
    final NativeImage? image = includeBorders
        ? await _nativeWindow.getFullOuterWindow(_windowID, type)
        : await getImage(0, 0, null, null, type);
    if (image == null) {
      throw WindowClosedException(message: "Cant get full image of window: $this");
    }
    return image;
  }

  /// Returns the full main display screen as an image.
  /// Default for [type] is [NativeImageType.RGBA] to make no copy (see docs of the type for more).
  static Future<NativeImage> getDisplayImage([NativeImageType type = NativeImageType.RGBA]) =>
      _nativeWindow.getFullMainDisplay(type);

  /// Returns the color of the pixel at [x], [y] relative to the top left corner of the window (not top bar).
  /// May throw a [WindowClosedException] if the window was not open. Uses [NativeOverlayWindow.getInnerOverlayAreaForWindow].
  /// Returns null if the position [x], [y] is outside of the window (relative to window space)!
  ///
  /// Important: uses mouse position relative to top left window border, but [GameWindow.getWindowBounds] would also
  /// include a top window border in its height which is not included here!
  ///
  /// To see rgb values from 0 to 255 as a string from color, use [Color.rgb].
  Color? getPixelOfWindow(int x, int y) {
    if (isWithinInnerWindow(x, y) == false) {
      return null;
    }
    final Bounds<int> innerBounds = NativeOverlayWindow.getInnerOverlayAreaForWindow(this);
    final int finalX = innerBounds.x + x;
    final int finalY = innerBounds.y + y;
    final Color? color = _nativeWindow.getPixelOfWindow(finalX, finalY);
    if (color == null) {
      throw WindowClosedException(message: "Cant get pixel of window $this: $x, $y");
    }
    return color;
  }

  /// Same as [getPixelOfWindow], but with [Point]
  Color? getPixelOfWindowP(Point<int> p) => getPixelOfWindow(p.x, p.y);

  /// Returns if the [point] is inside of the whole space of the window (also border at the top) in relation to
  /// screen space.
  /// IMPORTANT: don't use this with a [point] that is relational to window screen space and use [isWithinInnerWindow]!
  bool isWithinWindow(Point<int> point) {
    final Bounds<int> bounds = getWindowBounds();
    if (point.x < bounds.left || point.y < bounds.top || point.x >= bounds.right || point.y >= bounds.bottom) {
      return false;
    }
    return true;
  }

  /// Returns if [x], [y] are inside of the inner visible space of the window (without border at the top) in relation to
  /// top left corner of the window in window space. Also look at [isWithinWindow] for screen space that includes the
  /// top bar. Important: this may call [updateAndGetSize] if size was null before! If the window was closed, then
  /// this will throw a [WindowClosedException]!
  bool isWithinInnerWindow(int x, int y) {
    final Point<int>? size = _size ?? updateAndGetSize();
    if (size == null) {
      throw WindowClosedException(message: "Cant get size for $this");
    }
    if (x < 0 || y < 0 || x >= size.x || y >= size.y) {
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
      throw WindowClosedException(message: "Cant close window: $this");
    }
  }

  /// Returns the mouse position relative to the top left corner of the window.
  /// May throw a [WindowClosedException] if the window was not open.
  /// Returns [null] if the cursor is currently outside of the window (don't use [isWithinWindow] with this)!
  ///
  /// Important: uses mouse position relative to top left window border, but [GameWindow.getWindowBounds] would also
  /// include a top window border in its height which is not included here!
  Point<int>? get windowMousePos => InputManager.getWindowMousePos(this);

  /// Full size of the whole screen
  static int get mainDisplayWidth => _nativeWindow.getMainDisplayWidth();

  /// Full size of the whole screen
  static int get mainDisplayHeight => _nativeWindow.getMainDisplayHeight();

  @override
  String toString() => "GameWindow(name: $_name, id: $_windowID, open: $_isOpen, focus: $_hasFocus)";

  @override
  bool operator ==(Object other) => other is GameWindow && other._name == _name;

  @override
  int get hashCode => _name.hashCode;

  /// This needs to be called when one of each config variables changes to update the native code:
  /// [alwaysMatchEqual] controls how the window names will be matched ([false] = the window title only has to
  /// contain the [GameWindow.name]. Otherwise if [true] it has to be exactly the same)
  /// [printWindowNames] is a debug variable to print out all opened windows if set to true
  ///
  /// This is also called automatically once before the first [init] in [GameToolsLib.initGameToolsLib]
  static void updateConfigVariables({required bool alwaysMatchEqual, required bool printWindowNames}) {
    NativeWindow.initConfig(alwaysMatchEqual: alwaysMatchEqual, printWindowNames: printWindowNames);
  }
}
