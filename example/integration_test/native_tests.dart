import 'dart:async';
import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/enums/native_image_type.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/logger/custom_logger.dart';
import 'package:game_tools_lib/core/logger/log_level.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/data/native/native_image.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:integration_test/integration_test.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import 'helper/test_widgets.dart';

/// Set this to true to also test input and focus (needs to be started from cmd/terminal and also moves your mouse)
bool enableInputTests = false;

/// Some logs may not be printed in tests if an expect fails, because the print was not flushed to the console yet!
void main() {
  final IntegrationTestWidgetsFlutterBinding binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  binding.shouldPropagateDevicePointerEvents = true; // otherwise we could not interact with the test app
  WidgetsFlutterBinding.ensureInitialized();
  _testBaseOpenCv();
  // dont run tests asynchronous, but rather after another here, because they have to interact!
  testWidgets("Native Code Integration Tests (has to be all in one, see internal logs): ", (WidgetTester tester) async {
    _tester = tester;
    await _initOnlyWindow(tester, TestColouredBoxes()); // init only once the app ui
    await _group("Base Window Tests", _testBaseWindow);
    await _group("Image Tests", _testImages);
    if (enableInputTests) {
      await _group("Input Tests", _testInput);
    }
    for (final (String log, Object? e, StackTrace? s) in fails) {
      await StartupLogger().log(log, LogLevel.ERROR, e, s);
    }
    _completer.complete(fails.length);
  });
  test("Running other Tests...", () async {
    final int failCount = await _completer.future; // finish when the tests are done
    if (failCount == 0) {
      await StartupLogger().log("All tests completed successfully!!!", LogLevel.INFO, null, null);
      await Logger.waitForLoggingToBeDone();
    } else {
      await Logger.waitForLoggingToBeDone();
      throw TestFailure("Some tests failed! See above!");
    }
  });
}

Completer<int> _completer = Completer<int>();
late String _currentGroup;
late WidgetTester _tester;
int testCounter = 1;
List<(String, Object?, StackTrace?)> fails = <(String, Object?, StackTrace?)>[];

/// for each individual test, will init and cleanup!
Future<void> _test(String name, Future<void> Function(WidgetTester tester) callback) async {
  await StartupLogger().log("Running test ${testCounter++} $name...", LogLevel.INFO, null, null);
  try {
    await _initOnlyLib(_testAppName); // every test should init lib
    await callback.call(_tester);
    await GameToolsLib.close();
  } catch (e, s) {
    fails.add(("Failed $_currentGroup -- $name: ", e, s));
  }
  await Future<void>.delayed(const Duration(milliseconds: 35));
}

Future<void> _group(String name, Future<void> Function() test) async {
  _currentGroup = name;
  await StartupLogger().log("Test Group $name: ", LogLevel.INFO, null, null);
  await test.call();
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

Future<void> _initOnlyWindow(WidgetTester tester, Widget home, [String title = _testAppName]) async {
  await tester.pumpWidget(TestApp(title: title, child: home));
  await tester.pumpAndSettle(const Duration(milliseconds: 30));
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
    gameManager: ExampleGameManager(),
    isCalledFromTesting: true,
    gameWindows: GameToolsLib.createDefaultWindowForInit(searchName)..addAll(moreWindows),
  );
  await Utils.delay(Duration(milliseconds: 50)); // small delays until window is open
  if (result == false) {
    throw TestException(message: "default test init game tools lib failed");
  }
}

void _testBaseOpenCv() {
  test("external testing raw opencv functions", () async {
    final cv.Mat mat = cv.Mat.empty();
    expect(mat.channels, 1, reason: "empty mat channel 1");
    expect(mat.clone().isEmpty, true, reason: "clone still empty");
  });
}

Future<void> _testBaseWindow() async {
  await _test("window finding and default settings", (WidgetTester tester) async {
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
  await _test("color and pos test", (WidgetTester tester) async {
    Logger.warn("this test can fail if you un focus the window");
    expect(_window.getPixelOfWindow(0, 0)?.equals(Colors.blue), true, reason: "top left blue (blue light filter on?)");
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

Future<void> _testImages() async {
  await _test("raw image exception test", (WidgetTester tester) async {
    final NativeImage img = await NativeImage.readAsync(path: _testFile("full_crop.png"));
    expect(() async {
      await NativeImage.readAsync(path: _testFile("_NOT_EXISTING.png")); // wrong img path
    }, throwsA(predicate((Object e) => e is ImageException)));
    expect(() async {
      img.cleanupMemory(img.getRawData()); // cleanup with current data
    }, throwsA(predicate((Object e) => e is ImageException)));
    final NativeImage clone = await img.clone();
    expect(identical(clone, img), false, reason: "clone not identical");
    expect(clone, img, reason: "clone equal");
    img.cleanupMemory(null);
    img.cleanupMemory(null);
    expect(img.getRawData(), null, reason: "cleanup call be called with null multiple times");
    expect(() async {
      await img.clone(); // clone with null
    }, throwsA(predicate((Object e) => e is ImageException)));
    expect(() async {
      await img.scale(1.5, 2.5); // scale with null
    }, throwsA(predicate((Object e) => e is ImageException)));
    expect(() async {
      await img.getSubImage(0, 0, 1, 1); // subimg with null
    }, throwsA(predicate((Object e) => e is ImageException)));
    await img.resize(10, 10); // resize is fine, but does nothing
    expect(img.width == 0 && img.height == 0, true, reason: "still 0 size");
  });
  await _test("testing raw image functions", (WidgetTester tester) async {
    final int cleanups = NativeImage.cleanupCounter;
    final NativeImage full = NativeImage.readSync(path: _testFile("full_crop.png"));
    final NativeImage correct = NativeImage.readSync(path: _testFile("correct_crop.png"));
    final NativeImage wrong = NativeImage.readSync(path: _testFile("wrong_crop.png"));
    final NativeImage corAlpha = NativeImage.readSync(
      path: _testFile("correct_crop_alpha.png"),
      type: NativeImageType.RGBA,
    );
    final NativeImage corAlpha2 = NativeImage.readSync(
      path: _testFile("correct_crop_alpha_2.png"),
      type: NativeImageType.RGBA,
    );
    expect(NativeImage.cleanupCounter, cleanups, reason: "read should not change type");
    final NativeImage correctWA = NativeImage.readSync(path: _testFile("correct_crop.png"), type: NativeImageType.RGBA);
    expect(NativeImage.cleanupCounter, cleanups + 1, reason: "but explicit type change should!");
    final NativeImage fullGray = NativeImage.readSync(path: _testFile("full_crop.png"), type: NativeImageType.GRAY);
    expect(NativeImage.cleanupCounter, cleanups + 1, reason: "but not for gray!");
    final NativeImage part = await full.getSubImage(48, 47, 5, 3);
    expect(correct.colorAtPixel(0, 0)?.equals(Colors.yellow), true, reason: "correct pixel from file");
    expect(correct.colorAtPixel(1, 1)?.equals(Colors.red), true, reason: "correct pixel2 from file");
    expect(TestMockNativeImageWrapper(full).native, null, reason: "file has no native data");
    expect(full.type, NativeImageType.RGB, reason: "rgb image");
    expect(part.width == 5 && part.height == 3, true, reason: "sub img correct sizes");
    expect(part == correct, true, reason: "img comp true");
    expect(part == wrong, false, reason: "img comp false");
    expect(part.equals(wrong, pixelValueThreshold: 150, maxAmountOfPixelsNotEqual: 0), false, reason: "too low rgb");
    expect(part.equals(wrong, pixelValueThreshold: 151, maxAmountOfPixelsNotEqual: 0), true, reason: "rgb skip");
    expect(part.equals(wrong, pixelValueThreshold: 0, maxAmountOfPixelsNotEqual: 1), true, reason: "skip 1 pixel");

    expect(corAlpha.type, NativeImageType.RGBA, reason: "rgba image");
    expect(corAlpha2.type, NativeImageType.RGBA, reason: "rgba image");
    expect(corAlpha.colorAtPixel(2, 1)?.alpha, 152, reason: "alpha value in alpha");
    expect(corAlpha.colorAtPixel(0, 0)?.equals(Colors.yellow), true, reason: "correct pixel from alpha file");
    expect(corAlpha.colorAtPixel(0, 2)?.equals(Colors.red), true, reason: "correct pixel2 from alpha file");
    expect(corAlpha == correct, true, reason: "default still true");
    expect(corAlpha2 == correct, true, reason: "default still true");
    expect(corAlpha2 == corAlpha, false, reason: "alpha alpha false");
    expect(corAlpha2.equals(corAlpha, pixelValueThreshold: 200, maxAmountOfPixelsNotEqual: 0), true, reason: "value");
    expect(corAlpha2.equals(corAlpha, pixelValueThreshold: 0, maxAmountOfPixelsNotEqual: 2), true, reason: "pixel");
    expect(corAlpha2.equals(corAlpha, pixelValueThreshold: 50, maxAmountOfPixelsNotEqual: 0), false, reason: "value");
    expect(corAlpha2.equals(corAlpha, pixelValueThreshold: 0, maxAmountOfPixelsNotEqual: 1), false, reason: "value");
    expect(corAlpha2.equals(corAlpha, ignoreAlpha: true), true, reason: "compare with skip alpha also true");
    expect(correctWA.type, NativeImageType.RGBA, reason: "changed rgba image");
    expect(correctWA == correct, true, reason: "changed alpha image should still be same");

    final NativeImage scaled1 = await correct.clone();
    final NativeImage scaled2 = await correct.clone();
    await scaled1.resize(10, 6);
    await scaled2.scale(2.0, 2.0);
    expect(scaled1.width == 10 && scaled1.height == 6, true, reason: "correct dim for scale");
    expect(scaled1 == scaled2, true, reason: "scaled match");
    expect(scaled1.colorAtPixel(7, 2)?.equals(Color.fromARGB(255, 249, 141, 56)), true, reason: "scaled col");
    final NativeImage gray = await full.clone();
    gray.changeTypeSync(NativeImageType.GRAY);
    expect(gray.type == NativeImageType.GRAY && fullGray.type == gray.type, true, reason: "gray types");
    expect(gray.colorAtPixel(50, 50)?.gray, 118, reason: "gray col");
    expect(gray == fullGray, true, reason: "default equal matches gray");
    expect(gray.equals(fullGray, pixelValueThreshold: 0), false, reason: "with not 1 pxl offset its not equal tho!");
  });
  await _test("testing special image type hsv", (WidgetTester tester) async {
    final int cleanups = NativeImage.cleanupCounter;
    final NativeImage hsv = NativeImage.readSync(path: _testFile("correct_crop_alpha.png"), type: NativeImageType.HSV);
    expect(NativeImage.cleanupCounter, cleanups + 1, reason: "hsv read inc counter");
    expect(hsv.type, NativeImageType.HSV, reason: "correct hsv type");
    final NativeImage rgb = await hsv.clone();
    final NativeImage rgba = await hsv.clone();
    rgb.changeTypeSync(NativeImageType.RGB);
    expect(() async {
      rgba.changeTypeSync(NativeImageType.RGBA); // can not change to rgba
    }, throwsA(predicate((Object e) => e is ImageException)));
    rgba
      ..changeTypeSync(NativeImageType.RGB)
      ..changeTypeSync(NativeImageType.RGBA); // two way conversion
    expect(rgb.type, NativeImageType.RGB, reason: "correct conversion to rgb");
    expect(rgba.type, NativeImageType.RGBA, reason: "correct conversion to rgba");

    Color? hsvC = hsv.colorAtPixel(2, 1);
    expect(hsvC?.h == 2 && hsvC?.s == 199 && hsvC?.v == 244, true, reason: "hsv correct color");
    expect(rgb.colorAtPixel(1, 1)?.equals(Colors.red), true, reason: "correct color in rgb");
    expect(rgb.colorAtPixel(1, 1)?.equals(Colors.red), true, reason: "correct color in rgb");
    expect(rgba.colorAtPixel(2, 1)?.alpha, 255, reason: "alpha after conversion should be max");
    expect(rgb == rgba, true, reason: "conversions should be equal");
    final NativeImage hsv2 = await rgb.clone();
    hsv2.changeTypeSync(NativeImageType.HSV);
    expect(hsv2.type, NativeImageType.HSV, reason: "back to hsv");
    expect(hsv == hsv2, true, reason: "back to default should still be equal");
    rgba.changeTypeSync(NativeImageType.HSV);
    expect(rgba.type, NativeImageType.HSV, reason: "but should convert rgba back to hsv");
    hsvC = rgba.colorAtPixel(2, 1);
    expect(hsvC?.h == 2 && hsvC?.s == 199 && hsvC?.v == 244, true, reason: "converted should still have correct hsv");
    final NativeImage gray = NativeImage.readSync(path: _testFile("full_crop.png"), type: NativeImageType.GRAY);
    expect(() async {
      gray.changeTypeSync(NativeImageType.HSV); // also cant convert from gray to hsv
    }, throwsA(predicate((Object e) => e is ImageException)));
    expect(() async {
      hsv.changeTypeSync(NativeImageType.GRAY); // and cant convert from hsv to gray
    }, throwsA(predicate((Object e) => e is ImageException)));
  });
  await _test("testing image compare functions", (WidgetTester tester) async {
    final NativeImage img1 = NativeImage.readSync(path: _testFile("apple1.png"));
    final NativeImage img2 = NativeImage.readSync(path: _testFile("apple2.png"));
    final double histComp = await img1.pixelSimilarity(img2, comparePixelOverall: true);
    final double pixComp = await img1.pixelSimilarity(img2, comparePixelOverall: false);
    expect(histComp.isEqual(0.94073455), true, reason: "hist comp shows 94% similarity");
    expect(pixComp.isEqual(0.26637687), true, reason: "per pixel comp only shows 26%");
  });
  await _test("getting images from window and comparing pixel", (WidgetTester tester) async {
    Logger.warn("this test can fail if you un focus the window");
    final Bounds<int> bounds = _window.getWindowBounds();
    final int cleanups = NativeImage.cleanupCounter; // other tests could change this static val
    final NativeImage cropMiddle = await _window.getImage(582, 290, 100, 100);
    final NativeImage display = await GameWindow.getDisplayImage();
    expect(NativeImage.cleanupCounter, cleanups, reason: "cleanup still 0(can fail cause of other tests)");
    final NativeImage fullWin = await _window.getFullImage(NativeImageType.RGB);
    expect(NativeImage.cleanupCounter, cleanups + 1, reason: "cleanup still 0(can fail cause of other tests)");
    expect(cropMiddle.type, NativeImageType.RGBA, reason: "default rgba");
    expect(fullWin.type, NativeImageType.RGB, reason: "explicit rgb type");
    expect(TestMockNativeImageWrapper(cropMiddle).native, isNotNull, reason: "rgba has native data");
    expect(TestMockNativeImageWrapper(fullWin).native, null, reason: "rgb has no native data");

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
  });
}

Future<void> _testInput() async {
  await _test("focus test (only working with Command Prompt) and interact tests(moving your mouse around / using "
      "clipboard and keyboard keys, etc!)\nIMPORTANT: DON'T use your mouse and keyboard during this test and keep the"
      " terminal in focus!!!", (
    WidgetTester tester,
  ) async {
    await GameToolsLib.close();
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
