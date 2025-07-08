import 'dart:ffi';
import 'dart:math' show Point;
import 'dart:ui' show Color;
import 'package:ffi/ffi.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/Bounds.dart';
import 'package:game_tools_lib/data/game/game_window.dart' show GameWindow;
import 'package:game_tools_lib/data/native/ffi_loader.dart';
import 'package:game_tools_lib/data/native/native_image.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:opencv_dart/opencv.dart' as cv;

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
typedef initWindowN = Bool Function(Int, Pointer<Utf8>, Bool, Bool);
typedef initWindowD = bool Function(int, Pointer<Utf8>, bool, bool);

typedef guardFuncN = Int Function(Int);
typedef guardFuncD = int Function(int);

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
    if (bounds.left == 999999999 &&
        bounds.top == 999999999 &&
        bounds.right == 999999999 &&
        bounds.bottom == 999999999) {
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
  NativeImage getFullMainDisplay() {
    final int width = getMainDisplayWidth();
    final int height = getMainDisplayHeight();
    final Pointer<UnsignedChar> data = _getFullMainDisplay.call();
    final cv.Mat mat = cv.Mat.fromBuffer(height, width, cv.MatType.CV_8UC4, data as Pointer<Void>);
    // still needs to be deleted / cleaned up at some point. imread should also be tested
    // maybe also write some tests? also at start of program should check if opencv dll is working and also the own
    // custom dll
    // or look at https://stackoverflow.com/questions/59422546/an-efficient-way-to-convert-bytedata-in-dart-to-unsigned-char-in-c/59424471#59424471
    return NativeImage();
  }

  /// image displaying the whole window
  NativeImage? getFullWindow(int windowID) {
    final Bounds<int>? bounds = getWindowBounds(windowID);
    final Pointer<UnsignedChar> data = _getFullWindow.call(windowID);
    if (bounds == null || data.address == 0) {
      return null;
    }
    final cv.Mat mat = cv.Mat.fromBuffer(bounds.height, bounds.width, cv.MatType.CV_8UC4, data as Pointer<Void>);
    return NativeImage();
  }

  /// sub image relative to top left corner of the window
  NativeImage? getImageOfWindow(int windowID, int x, int y, int width, int height) {
    final Pointer<UnsignedChar> data = _getImageOfWindow.call(windowID, x, y, width, height);
    if (data.address == 0) {
      return null;
    }
    final cv.Mat mat = cv.Mat.fromBuffer(height, width, cv.MatType.CV_8UC4, data as Pointer<Void>);
    return NativeImage(); // todo: implement all 3
  }

  /// relative to top left corner of window, alpha is always 255
  Color? getPixelOfWindow(int windowID, int x, int y) {
    final int pixel = _getPixelOfWindow(windowID, x, y);
    if (pixel == 999999999) {
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
    if (point.x == 999999999 && point.y == 999999999) {
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
      _nativeWindowInstance = NativeWindow._();
      late final guardFuncD fun;
      try {
        fun = _nativeWindowInstance!._api.lookupFunction<guardFuncN, guardFuncD>("botGuard");
      } catch (e, s) {
        Logger.warn("initNativeWindow fail details:", e, s);
        return false;
      }
      final int result = fun.call(39184);
      if (result != (5464696 + 39184)) {
        return false;
      }
      GameWindow.updateConfigVariables(
        alwaysMatchEqual: await MutableConfig.mutableConfig.alwaysMatchGameWindowNamesEqual.valueNotNull(),
        printWindowNames: await MutableConfig.mutableConfig.debugPrintGameWindowNames.valueNotNull(),
      );
    }
    return true;
  }

  /// removes the internal [instance] reference, so mostly used for testing
  static void clearNativeWindowInstance() {
    _nativeWindowInstance = null;
  }
}
