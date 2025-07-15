import 'dart:ffi';
import 'dart:math' show Point;
import 'dart:ui' show Color;
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/enums/input_enums.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/bounds.dart';
import 'package:game_tools_lib/data/game/game_window.dart' show GameWindow;
import 'package:game_tools_lib/data/native/ffi_loader.dart';
import 'package:game_tools_lib/data/native/native_image.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:opencv_dart/opencv.dart' as cv;

/// Simple integer to detect dll library mismatches. Has to be incremented when native code is modified!
/// Also Modify the version in native_window.h
const int _nativeCodeVersion = 6;

/// First local conversions of classes/structs from c code that are used in the functions below
final class _Rect extends Struct {
  @Int()
  external int left;

  @Int()
  external int top;

  @Int()
  external int right;

  @Int()
  external int bottom;
}

final class _Point extends Struct {
  @Int()
  external int x;

  @Int()
  external int y;
}

/// Then Typedefs in pairs of native function syntax, then dart function syntax
typedef versionFuncN = Int Function();
typedef versionFuncD = int Function();

typedef initWindowN = Bool Function(Int, Pointer<Utf8>, Bool, Bool);
typedef initWindowD = bool Function(int, Pointer<Utf8>, bool, bool);

typedef isWindowOpenN = Bool Function(Int);
typedef isWindowOpenD = bool Function(int);

typedef hasWindowFocusN = Bool Function(Int);
typedef hasWindowFocusD = bool Function(int);

typedef setWindowFocusN = Bool Function(Int);
typedef setWindowFocusD = bool Function(int);

typedef getWindowBoundsN = _Rect Function(Int);
typedef getWindowBoundsD = _Rect Function(int);

typedef getMainDisplayWidthN = UnsignedInt Function();
typedef getMainDisplayWidthD = int Function();

typedef getMainDisplayHeightN = UnsignedInt Function();
typedef getMainDisplayHeightD = int Function();

typedef closeWindowN = Bool Function(Int);
typedef closeWindowD = bool Function(int);

typedef cleanupMemoryN = Void Function(Pointer<UnsignedChar>);
typedef cleanupMemoryD = void Function(Pointer<UnsignedChar>);

typedef getFullMainDisplayN = Pointer<UnsignedChar> Function();

typedef getFullWindowN = Pointer<UnsignedChar> Function(Int);
typedef getFullWindowD = Pointer<UnsignedChar> Function(int);

typedef getImageOfWindowN = Pointer<UnsignedChar> Function(Int, Int, Int, Int, Int);
typedef getImageOfWindowD = Pointer<UnsignedChar> Function(int, int, int, int, int);

typedef getPixelOfWindowN = UnsignedLong Function(Int, Int, Int);
typedef getPixelOfWindowD = int Function(int, int, int);

typedef getDisplayMousePosN = _Point Function();

typedef getWindowMousePosN = _Point Function(Int);
typedef getWindowMousePosD = _Point Function(int);

typedef setDisplayMousePosN = Void Function(Int, Int);
typedef setDisplayMousePosD = void Function(int, int);

typedef setWindowMousePosN = Bool Function(Int, Int, Int);
typedef setWindowMousePosD = bool Function(int, int, int);

typedef moveMouseN = Void Function(Int, Int);
typedef moveMouseD = void Function(int, int);

typedef scrollMouseN = Void Function(Int);
typedef scrollMouseD = void Function(int);

typedef sendMouseEventN = Void Function(Int);
typedef sendMouseEventD = void Function(int);

typedef sendKeyEventN = Void Function(Bool, UnsignedShort);
typedef sendKeyEventD = void Function(bool, int);

typedef sendKeyEventsN = Void Function(Bool, Pointer<UnsignedShort>, UnsignedShort);
typedef sendKeyEventsD = void Function(bool, Pointer<UnsignedShort>, int);

typedef isKeyDownN = Bool Function(UnsignedShort);
typedef isKeyDownD = bool Function(int);

typedef isKeyToggledN = Bool Function(UnsignedShort);
typedef isKeyToggledD = bool Function(int);

/// Wrapper class for native c/c++ functions to interact with a game window, or the screen.
///
/// Before using any methods that need a window id, [initWindow] has to be called once!
/// The constructor looks up the api and functions.
/// This class should only be used in [GameWindow]!
final class NativeWindow {
  late DynamicLibrary _api;
  late initWindowD _initWindow;
  late isWindowOpenD _isWindowOpen;
  late hasWindowFocusD _hasWindowFocus;
  late setWindowFocusD _setWindowFocus;
  late getWindowBoundsD _getWindowBounds;
  late getMainDisplayWidthD _getMainDisplayWidth;
  late getMainDisplayHeightD _getMainDisplayHeight;
  late closeWindowD _closeWindow;
  late cleanupMemoryD _cleanupMemory;
  late getFullMainDisplayN _getFullMainDisplay;
  late getFullWindowD _getFullWindow;
  late getImageOfWindowD _getImageOfWindow;
  late getPixelOfWindowD _getPixelOfWindow;
  late getDisplayMousePosN _getDisplayMousePos;
  late getWindowMousePosD _getWindowMousePos;
  late setDisplayMousePosD _setDisplayMousePos;
  late setWindowMousePosD _setWindowMousePos;

  late moveMouseD _moveMouse;
  late scrollMouseD _scrollMouse;
  late sendMouseEventD _sendMouseEvent;
  late sendKeyEventD _sendKeyEvent;
  late sendKeyEventsD _sendKeyEvents;
  late isKeyDownD _isKeyDown;
  late isKeyToggledD _isKeyToggled;

  /// Now call constructor that initialized the api reference and looks up all functions with the correct types
  /// defined above!
  /// Afterwards create methods with the same name that calls the private member function pointer
  /// Can throw an exception if the function was not found
  NativeWindow._() {
    _api = FFILoader.api;
    _initWindow = _api.lookupFunction<initWindowN, initWindowD>("initWindow");
    _isWindowOpen = _api.lookupFunction<isWindowOpenN, isWindowOpenD>("isWindowOpen");
    _hasWindowFocus = _api.lookupFunction<hasWindowFocusN, hasWindowFocusD>("hasWindowFocus");
    _setWindowFocus = _api.lookupFunction<setWindowFocusN, setWindowFocusD>("setWindowFocus");
    _getWindowBounds = _api.lookupFunction<getWindowBoundsN, getWindowBoundsD>("getWindowBounds");
    _getMainDisplayWidth = _api.lookupFunction<getMainDisplayWidthN, getMainDisplayWidthD>("getMainDisplayWidth");
    _getMainDisplayHeight = _api.lookupFunction<getMainDisplayHeightN, getMainDisplayHeightD>("getMainDisplayHeight");
    _closeWindow = _api.lookupFunction<closeWindowN, closeWindowD>("closeWindow");
    _cleanupMemory = _api.lookupFunction<cleanupMemoryN, cleanupMemoryD>("cleanupMemory");
    _getFullMainDisplay = _api.lookupFunction<getFullMainDisplayN, getFullMainDisplayN>("getFullMainDisplay");
    _getFullWindow = _api.lookupFunction<getFullWindowN, getFullWindowD>("getFullWindow");
    _getImageOfWindow = _api.lookupFunction<getImageOfWindowN, getImageOfWindowD>("getImageOfWindow");
    _getPixelOfWindow = _api.lookupFunction<getPixelOfWindowN, getPixelOfWindowD>("getPixelOfWindow");
    _getDisplayMousePos = _api.lookupFunction<getDisplayMousePosN, getDisplayMousePosN>("getDisplayMousePos");
    _getWindowMousePos = _api.lookupFunction<getWindowMousePosN, getWindowMousePosD>("getWindowMousePos");
    _setDisplayMousePos = _api.lookupFunction<setDisplayMousePosN, setDisplayMousePosD>("setDisplayMousePos");
    _setWindowMousePos = _api.lookupFunction<setWindowMousePosN, setWindowMousePosD>("setWindowMousePos");
    _moveMouse = _api.lookupFunction<moveMouseN, moveMouseD>("moveMouse");
    _scrollMouse = _api.lookupFunction<scrollMouseN, scrollMouseD>("scrollMouse");
    _sendMouseEvent = _api.lookupFunction<sendMouseEventN, sendMouseEventD>("sendMouseEvent");
    _sendKeyEvent = _api.lookupFunction<sendKeyEventN, sendKeyEventD>("sendKeyEvent");
    _sendKeyEvents = _api.lookupFunction<sendKeyEventsN, sendKeyEventsD>("sendKeyEvents");
    _isKeyDown = _api.lookupFunction<isKeyDownN, isKeyDownD>("isKeyDown");
    _isKeyToggled = _api.lookupFunction<isKeyToggledN, isKeyToggledD>("isKeyToggled");
  }

  /// Has to be called once for each [windowName] to initialize it with its [windowID] which is then used to call the
  /// functions below.
  /// [alwaysMatchEqual] controls how the window names will be matched ([false] = the window title only has to
  /// contain the [windowName]. Otherwise if [true] it has to be exactly the same)
  /// [printWindowNames] is a debug variable to print out all opened windows if set to true
  /// This only prepares native code, it does not lookup the window yet.
  /// Calling this multiple times for the same window, will reset the window handle
  bool initWindow({
    required int windowID,
    required String windowName,
    required bool alwaysMatchEqual,
    required bool printWindowNames,
  }) {
    Logger.verbose(
      "Init Native window windowID: $windowID, windowName: $windowName, "
      "alwaysMatchEqual:$alwaysMatchEqual, printWindowNames:$printWindowNames",
    );
    return _initWindow.call(windowID, windowName.toNativeUtf8(), alwaysMatchEqual, printWindowNames);
  }

  /// Searches a window with the [name] and returns if it was found
  bool isWindowOpen(int windowID) {
    return _isWindowOpen.call(windowID);
  }

  /// If the user is tabbed into the [name] window
  bool hasWindowFocus(int windowID) {
    return _hasWindowFocus.call(windowID);
  }

  /// Changes focus and returns success.
  bool setWindowFocus(int windowID) {
    return _setWindowFocus.call(windowID);
  }

  /// The window's top left corner is (x, y) and then it expands to (width, height).
  /// May return null if the window was not open.
  Bounds<int>? getWindowBounds(int windowID) {
    final _Rect bounds = _getWindowBounds.call(windowID);
    if (bounds.left == _INVALID_VALUE &&
        bounds.top == _INVALID_VALUE &&
        bounds.right == _INVALID_VALUE &&
        bounds.bottom == _INVALID_VALUE) {
      return null;
    }
    return Bounds<int>.sides(left: bounds.left, top: bounds.top, right: bounds.right, bottom: bounds.bottom);
  }

  /// Full size of the whole screen
  int getMainDisplayWidth() {
    return _getMainDisplayWidth.call();
  }

  /// Full size of the whole screen
  int getMainDisplayHeight() {
    return _getMainDisplayHeight.call();
  }

  /// Closes the target window and returns success.
  bool closeWindow(int windowID) {
    return _closeWindow.call(windowID);
  }

  /// Only use this to free [data] allocated by native c/c++ code!
  void cleanupMemory(Pointer<UnsignedChar> data) {
    _cleanupMemory.call(data);
  }

  /// image displaying the whole main display
  Future<NativeImage> getFullMainDisplay() async {
    final int width = getMainDisplayWidth();
    final int height = getMainDisplayHeight();
    final Pointer<UnsignedChar> data = _getFullMainDisplay.call();
    return NativeImage.nativeAsync(width: width, height: height, data: data);
  }

  /// image displaying the whole window
  Future<NativeImage?> getFullWindow(int windowID) async {
    final Bounds<int>? bounds = getWindowBounds(windowID);
    final Pointer<UnsignedChar> data = _getFullWindow.call(windowID);
    if (bounds == null || data.address == 0) {
      return null;
    }
    return NativeImage.nativeAsync(
      width: bounds.width,
      height: bounds.height,
      data: data,
      logXPos: 0,
      logYPos: 0,
    );
  }

  /// Returns a Sub image relative to top left corner of the window.
  /// Per default [removeAlpha] is true to remove the alpha channel, because its not used for comparison. The other
  /// methods of getting images also remove the alpha channel!
  Future<NativeImage?> getImageOfWindow(
    int windowID,
    int x,
    int y,
    int width,
    int height, {
    bool removeAlpha = true,
  }) async {
    final Pointer<UnsignedChar> data = _getImageOfWindow.call(windowID, x, y, width, height);
    if (data.address == 0) {
      return null;
    }
    return NativeImage.nativeAsync(
      width: width,
      height: height,
      data: data,
      logXPos: x,
      logYPos: y,
      removeAlpha: removeAlpha,
    );
  }

  /// relative to top left corner of window, alpha is always 255
  Color? getPixelOfWindow(int windowID, int x, int y) {
    final int pixel = _getPixelOfWindow(windowID, x, y);
    if (pixel == _INVALID_VALUE) {
      return null;
    }
    return Color.fromARGB(255, pixel, pixel >> 8, pixel >> 16);
  }

  /// can be on any display
  Point<int> getDisplayMousePos() {
    final _Point point = _getDisplayMousePos.call();
    return Point<int>(point.x, point.y);
  }

  /// relative to top left corner of window
  Point<int>? getWindowMousePos(int windowID) {
    final _Point point = _getWindowMousePos.call(windowID);
    if (point.x == _INVALID_VALUE && point.y == _INVALID_VALUE) {
      return null;
    }
    return Point<int>(point.x, point.y);
  }

  /// can be on any display
  void setDisplayMousePos(int x, int y) {
    _setDisplayMousePos.call(x, y);
  }

  /// relative to top left corner of window
  bool setWindowMousePos(int windowID, int x, int y) {
    return _setWindowMousePos.call(windowID, x, y);
  }

  /// Relative Mouse Move to current mouse position (can be negative)
  void moveMouse(int dx, int dy) {
    _moveMouse.call(dx, dy);
  }

  /// Scrolls by this amount of scroll wheel clicks into one direction (can be negative for reverse)
  void scrollMouse(int scrollClickAmount) {
    _scrollMouse.call(scrollClickAmount);
  }

  /// Sends a mouse event to interact with the mouse buttons
  void sendMouseEvent(MouseEvent mouseEvent) {
    _sendMouseEvent.call(mouseEvent.convertToPlatformCode());
  }

  /// Sends a key event to interact with the keyboard keys.
  /// [keyUp]=true will send a key release event and otherwise a key pressed down event is send.
  /// [keyCode] represents the virtual keycode of the key
  void sendKeyEvent({required bool keyUp, required LogicalKeyboardKey keyCode}) {
    _sendKeyEvent.call(keyUp, keyCode.convertToPlatformCode());
  }

  /// Same as sendKeyEvent, but with multiple key events at the same time
  void sendKeyEvents({required bool keyUp, required List<LogicalKeyboardKey> keyCodes}) {
    final int amountOfKeys = keyCodes.length;
    final Pointer<UnsignedShort> pointer = calloc<UnsignedShort>(amountOfKeys + 1);
    for (int index = 0; index < amountOfKeys; index++) {
      pointer[index] = keyCodes[index].convertToPlatformCode();
    }
    _sendKeyEvents.call(keyUp, pointer, amountOfKeys);
    calloc.free(pointer);
  }

  /// Returns if the virtual keycode is currently pressed down
  bool isKeyDown(LogicalKeyboardKey keyCode) {
    return _isKeyDown.call(keyCode.convertToPlatformCode());
  }

  /// Returns if virtual mouse key code is currently down(also works correctly if left and right mouse buttons are
  /// swapped).
  bool isMouseDown(MouseKey keyCode) {
    return _isKeyDown.call(keyCode.convertToPlatformCode());
  }

  /// Returns true if a key like caps lock, etc is toggled on. (also uses virtual key codes)
  bool isKeyToggled(LogicalKeyboardKey keyCode) {
    return _isKeyToggled.call(keyCode.convertToPlatformCode());
  }

  /// Only used for logging and also as the first use to load the opencv library in [GameToolsLib.initGameToolsLib]!
  static String get openCvVersion => cv.openCvVersion();

  static NativeWindow? _nativeWindowInstance;

  /// Returns [_nativeWindowInstance] not nullable (only works after [initNativeWindow])
  static NativeWindow get instance => _nativeWindowInstance!;

  /// Called automatically from [GameToolsLib.initGameToolsLib] to init the [_nativeWindowInstance]
  /// Multiple calls have no effect. Also calls [GameWindow.updateConfigVariables] once after getting the config
  /// async variables to test the native code!
  /// Can also throw [ConfigException] if the config is corrupt.
  ///
  /// Should not be called from anywhere else! Returns if the guard function still works (and the library was
  /// unchanged since last time)
  static Future<bool> initNativeWindow() async {
    if (_nativeWindowInstance == null) {
      late final versionFuncD fun;
      try {
        _nativeWindowInstance = NativeWindow._();
        fun = _nativeWindowInstance!._api.lookupFunction<versionFuncN, versionFuncD>("nativeCodeVersion");
      } catch (e, s) {
        Logger.warn("initNativeWindow fail details:", e, s);
        return false;
      }
      final int version = fun.call();
      if (version != _nativeCodeVersion) {
        Logger.warn("Native code has version $version and dart code has version $_nativeCodeVersion");
        return false;
      }
      GameWindow.updateConfigVariables(
        alwaysMatchEqual: await MutableConfig.mutableConfig.alwaysMatchGameWindowNamesEqual.valueNotNull(),
        printWindowNames: await MutableConfig.mutableConfig.debugPrintGameWindowNames.valueNotNull(),
      );
    }
    return true;
  }

  static const int _INVALID_VALUE = 999999999;

  /// removes the internal [instance] reference, so mostly used for testing
  static void clearNativeWindowInstance() {
    _nativeWindowInstance = null;
  }
}
