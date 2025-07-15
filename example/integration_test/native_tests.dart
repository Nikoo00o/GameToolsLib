import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/data/game/game_window.dart';
import 'package:game_tools_lib/data/native/native_image.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:integration_test/integration_test.dart';
import 'helper/test_widgets.dart';

/// Set this to true to also test input and focus (needs to be started from cmd/terminal and also moves your mouse)
bool enableInputTests = false;

void main() {
  final IntegrationTestWidgetsFlutterBinding binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  binding.shouldPropagateDevicePointerEvents = true; // otherwise we could not interact with the test app
  WidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    // init needs to be done in each testWidgets call by calling [_initWindowAndLib]
  });

  tearDown(() async {
    await GameToolsLib.close(); // cleanup static references
    await Utils.delay(Duration(milliseconds: 20)); // get last log out of test
  });

  group("Native Code Integration Tests: ", () {
    group("Base Window Tests: ", _testBaseWindow);
    group("Image Tests: ", _testImages);
    if (enableInputTests) {
      group("Input Tests: ", _testInput);
    }
  });
}

const String _testAppName = "game_tools_lib_example";
const int _x = 10;
const int _y = 10;
const int _width = 1280;
const int _height = 720;
int _windowWidth = 1264;
int _windowHeight = 681;

GameWindow get _window => GameToolsLib.mainGameWindow;

String get _testFolder => FileUtils.combinePath(<String>[FixedConfig.fixedConfig.resourceFolderPath, "test"]);

String _testFile(String fileName) => FileUtils.combinePath(<String>[_testFolder, fileName]);

Future<void> _initWindowAndLib(WidgetTester tester, Widget home) async {
  await _initOnlyWindow(tester, home);
  await _initOnlyLib(_testAppName);
}

Future<void> _initOnlyWindow(WidgetTester tester, Widget home, [String title = _testAppName]) async {
  await tester.pumpWidget(TestApp(title: title, child: home));
  await tester.pumpAndSettle(const Duration(milliseconds: 20));
  final Size size = tester.view.physicalSize;
  _windowWidth = size.width.toInt();
  _windowHeight = size.height.toInt();
}

Future<void> _initOnlyLib([
  String searchName = _testAppName,
  List<GameWindow> moreWindows = const <GameWindow>[],
]) async {
  final bool result = await GameToolsLib.initGameToolsLib(
    config: ExampleGameToolsConfig(),
    isCalledFromTesting: true,
    gameWindows: GameToolsLib.createDefaultWindowForInit(searchName)..addAll(moreWindows),
  );
  await Utils.delay(Duration(milliseconds: 20)); // small delays until window is open
  if (result == false) {
    throw TestException(message: "default test init game tools lib failed");
  }
}

void _testBaseWindow() {
  testWidgets("window finding and default settings", (WidgetTester tester) async {
    await _initWindowAndLib(tester, TestColouredBoxes());
    expect(_window.isWindowOpen(), true, reason: "window should be open");
    final Bounds<int> bounds = _window.getWindowBounds();
    expect(bounds.width, _width, reason: "window should have correct width");
    expect(bounds.height, _height, reason: "window should have correct width");
    expect(bounds.x, _x, reason: "window should have correct x");
    expect(bounds.y, _y, reason: "window should have correct y");
    await GameToolsLib.close();
    await _initOnlyLib("Game Tools Lib Example");
    expect(_window.isWindowOpen(), false, reason: "window should not be open with wrong name");
    await GameToolsLib.close();
    final GameWindow second = GameWindow(name: "invalid");
    await _initOnlyLib("game_tools", <GameWindow>[second]);
    expect(_window.isWindowOpen(), true, reason: "window should be open with default contains check");
    expect(second.isWindowOpen(), false, reason: "second window should not be open");
    await second.rename("tools");
    expect(second.isWindowOpen(), true, reason: "after rename second should also be open");
    await GameToolsLib.close();
    await _initOnlyLib("game_tools");
    await MutableConfig.mutableConfig.alwaysMatchGameWindowNamesEqual.setValue(true);
    expect(_window.isWindowOpen(), false, reason: "but not anymore when checking for equal");
  });
  testWidgets("color and pos test", (WidgetTester tester) async {
    await _initWindowAndLib(tester, TestColouredBoxes());
    Logger.warn("this test can fail if you un focus the window");
    expect(_window.getPixelOfWindow(0, 0)?.equals(Colors.blue), true, reason: "top left blue");
    expect(_window.getPixelOfWindow(99, 99)?.equals(Colors.blue), true, reason: "max size still blue");
    expect(_window.getPixelOfWindow(100, 100)?.equals(Colors.white), true, reason: "outer white");
    expect(_window.getPixelOfWindow(1163, 580)?.equals(Colors.white), true, reason: "before bot right white");
    expect(_window.getPixelOfWindow(1164, 581)?.equals(Colors.purple), true, reason: "bottom right purple");
    expect(_window.getPixelOfWindow(_windowWidth - 1, _windowHeight - 1)?.equals(Colors.purple), true, reason: "pur");
    expect(_window.getPixelOfWindow(_windowWidth, _windowHeight)?.equals(Colors.purple), false, reason: "no color");
    expect(_window.getPixelOfWindow(_width - 1, _height - 1)?.equals(Colors.purple), false, reason: "still no color");
    expect(_window.getPixelOfWindow(_width, _height), null, reason: "out window null");
    expect(_window.getPixelOfWindow(-1, -1), null, reason: "also -1 is null");
    expect(_window.getMiddle(), Point<int>(640, 360), reason: "middle a bit shifted");
    expect(_window.getMiddle() == _window.getWindowBounds().middlePos, false, reason: "middle should not be bounds");
    expect(_window.getPixelOfWindowP(_window.getMiddle())?.equals(Colors.yellow), true, reason: "middle ring yellow");
  });
}

void _testImages() {
  testWidgets("testing raw image functions", (WidgetTester tester) async {
    await _initOnlyLib();
    final NativeImage full = NativeImage.readSync(path: _testFile("full_crop.png"));
    final NativeImage correct = NativeImage.readSync(path: _testFile("correct_crop.png"));
    final NativeImage wrong = NativeImage.readSync(path: _testFile("wrong_crop.png"));
    final NativeImage part = await full.getSubImage(48, 47, 5, 3);
    expect(part == correct, true, reason: "img comp true");
    expect(part == wrong, false, reason: "img comp false");
    expect(part.equals(wrong, pixelRGBThreshold: 150, maxAmountOfPixelsNotEqual: 0), false, reason: "too low rgb");
    expect(part.equals(wrong, pixelRGBThreshold: 151, maxAmountOfPixelsNotEqual: 0), true, reason: "rgb skip");
    expect(part.equals(wrong, pixelRGBThreshold: 0, maxAmountOfPixelsNotEqual: 1), true, reason: "skip 1 pixel");
    // todo: test resize and scale
  });
  testWidgets("getting images from window and comparing pixel", (WidgetTester tester) async {
    await _initWindowAndLib(tester, TestColouredBoxes());
    Logger.warn("this test can fail if you un focus the window");
    final Bounds<int> bounds = _window.getWindowBounds();
    final NativeImage fullWin = await _window.windowFullImage;
    final NativeImage cropMiddle = await _window.getImageOfWindow(582, 290, 100, 100);
    final NativeImage display = await GameWindow.mainDisplayFullImage;
    expect(fullWin.width == 1280 && fullWin.height == 720, true, reason: "correct window dimensions");
    expect(cropMiddle.colorAtPixel(-1, -1), null, reason: "pixel null");
    expect(cropMiddle.colorAtPixel(100, 100), null, reason: "pixel also null");
    expect(cropMiddle.colorAtPixel(0, 0)?.equals(Colors.yellow), true, reason: "crop tl");
    expect(cropMiddle.colorAtPixel(99, 99)?.equals(Colors.yellow), true, reason: "crop br");
    expect(cropMiddle.colorAtPixel(47, 47)?.equals(Colors.yellow), true, reason: "crop mi1");
    expect(cropMiddle.colorAtPixel(48, 48)?.equals(Colors.red), true, reason: "crop mi2");
    expect(cropMiddle.colorAtPixel(51, 51)?.equals(Colors.red), true, reason: "crop mi3");
    expect(cropMiddle.colorAtPixel(52, 52)?.equals(Colors.yellow), true, reason: "crop mi4");
    // real inner window positions from full window vary a bit because of invisible borders, etc
    expect(fullWin.colorAtPixel(8, 31)?.equals(Colors.blue), true, reason: "first window pixel (might fail)");
    expect(fullWin.colorAtPixel(1271, 711)?.equals(Colors.purple), true, reason: "last window pixel (might fail)");
    expect(fullWin.colorAtPixel(638, 369)?.equals(Colors.red), true, reason: "win mid1");
    expect(fullWin.colorAtPixel(642, 373)?.equals(Colors.yellow), true, reason: "win mid2");
    // now translate from window pos to display pos
    expect(
      display.colorAtPixel(8 + bounds.x, 31 + bounds.y)?.equals(Colors.blue),
      true,
      reason: "same first pixel on display (might fail)",
    );
    expect(
      display.colorAtPixel(1271 + bounds.x, 711 + bounds.y)?.equals(Colors.purple),
      true,
      reason: "same last pixel on display (might fail)",
    );
    final NativeImage part = await cropMiddle.getSubImage(48, 47, 5, 3);
    expect(part == NativeImage.readSync(path: _testFile("correct_crop.png")), true, reason: "sub image comp equals");
    expect(part == NativeImage.readSync(path: _testFile("wrong_crop.png")), false, reason: "wrong not equal");
    // todo: also resize and scale here
  });
}

void _testInput() {
  testWidgets("focus test (only working with Command Prompt) and interact tests(moving your mouse around / using "
      "clipboard and keyboard keys, etc!)\nIMPORTANT: DON'T use your mouse and keyboard during this test and keep the"
      " terminal in focus!!!", (
    WidgetTester tester,
  ) async {
    await _initOnlyWindow(tester, TestColouredBoxes());
    final GameWindow second = GameWindow(name: "Command Prompt");
    await _initOnlyLib("game_tools", <GameWindow>[second]);
    Logger.warn("this test can fail if you un focus the window");
    Logger.warn(
      "Remember to start the tests from the terminal command prompt and not with the run configuration: "
      "\"cd example && flutter test integration_test/native_tests.dart\""
      "and also don't use your mouse and keyboard during the tests and keep the terminal in focus!!!",
    );
    expect(
      second.isWindowOpen(),
      true,
      reason:
          "IMPORTANT: you have to start the tests from the command prompt and keep it in focus (don't use mouse)!\n"
          "(first cd into example dir and then run \"flutter test integration_test/native_tests.dart\") so that the "
          "test can find a window called \"Command Prompt\"",
    );
    await second.setWindowFocus();
    expect(_window.hasWindowFocus(), false, reason: "window should have no focus at first");
    await _window.setWindowFocus();
    expect(_window.hasWindowFocus(), true, reason: "window should have focus after change");
    await _window.moveMouse(80, 640, xRadius: 0, yRadius: 0);
    expect(_window.windowMousePos, Point<int>(80, 640), reason: "first move mouse should match");
    await InputManager.leftClick();
    await Future<void>.delayed(Duration(milliseconds: 25));
    expect(find.text("after button"), findsOneWidget, reason: "button should be clicked");
    await _window.moveMouse(1130, 50, xRadius: 0, yRadius: 0);
    expect(_window.windowMousePos, Point<int>(1130, 50), reason: "second move mouse should match");
    await InputManager.leftClick();
    final String userClip = await InputManager.getClipboard();
    final String preClip = "_before_test_data";
    await InputManager.setClipboard(preClip);
    final String testData = await InputManager.getSelectedData(selectFirst: true);
    await InputManager.pasteDataIntoSelected("_after_test_data");
    final String shouldBePreAgain = await InputManager.getClipboard();
    await InputManager.setClipboard(userClip);
    expect(preClip, shouldBePreAgain, reason: "old clipboard should stay untouched (also restored user clip)");
    expect(testData, "after button", reason: "copy selected data");
    await Future<void>.delayed(Duration(milliseconds: 25));
    expect(find.text("_after_test_data"), findsOneWidget, reason: "paste data into selected");
    Logger.info("Testing if a key is down is not done here, because it needs real user input");
  });
}
