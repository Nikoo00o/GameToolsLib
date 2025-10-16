import 'dart:async';
import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/enums/native_image_type.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/data/native/native_image.dart';
import 'package:game_tools_lib/data/native/native_overlay_window.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'helper/test_widgets.dart';

/// Set this to true to also test input and focus (needs to be started from normal cmd/terminal and also moves your
/// mouse, so may not use it!): cd example && flutter test integration_test/native_tests.dart
bool enableInputTests = true;

/// If [enableInputTests] is true you may not run this from the IDE!
Future<void> main() async {
  await TestHelper.runDefaultTests(
    testGroups: <String, TestFunction>{
      "OpenCV Included from Lib": testOpenCv,
    },
  );

  await TestHelper.runOrderedTests(
    parentDescription: "Event_State_Tests",
    testGroups: <String, TestFunction>{
      "Base Window": _testBaseWindow,
      "Image": _testImages,
      if (enableInputTests) "Input": _testInput,
    },
    appTitle: TestHelper.defaultAppTitle,
    appBody: TestHelper.defaultAppBody,
  );
}

const int _x = 10;
const int _y = 10;
const int _width = 1280;
const int _height = 720;

void _testBaseWindow() {
  testO("window finding and default settings", () async {
    expect(mWindow.updateAndGetOpen(), true, reason: "window should be open");
    final Bounds<int> bounds = mWindow.getWindowBounds();
    expect(bounds.width, _width, reason: "window should have correct width");
    expect(bounds.height, _height, reason: "window should have correct width");
    expect(bounds.x, _x, reason: "window should have correct x");
    expect(bounds.y, _y, reason: "window should have correct y");
    final Point<int>? size = mWindow.updateAndGetSize();
    expect(size, Point<int>(appWidth, appHeight), reason: "window should have correct size!");
    await GameToolsLib.close();
    await TestHelper.initGameToolsLib("Game Tools Lib Example");
    expect(mWindow.updateAndGetOpen(), false, reason: "window should not be open with wrong name");
    await GameToolsLib.close();
    final GameWindow second = GameWindow(name: "invalid");
    await TestHelper.initGameToolsLib("game_tools_lib_exa", <GameWindow>[second]);
    await MutableConfig.mutableConfig.alwaysMatchGameWindowNamesEqual.setValue(false);
    expect(mWindow.updateAndGetOpen(), true, reason: "window should be open with default contains check");
    expect(second.updateAndGetOpen(), false, reason: "second window should not be open");
    await second.rename("tools");
    expect(second.updateAndGetOpen(), true, reason: "after rename second should also be open");
    await GameToolsLib.close();
    await TestHelper.initGameToolsLib("game_tools_lib_exa");
    await MutableConfig.mutableConfig.alwaysMatchGameWindowNamesEqual.setValue(true);
    expect(mWindow.updateAndGetOpen(), false, reason: "but not anymore when checking for equal");
  });

  testO("color and pos test", () async {
    Logger.warn("this test can fail if you un focus the window");
    mWindow.updateOpen(); // also needed for size to be cached without loop
    mWindow.updateSize(); // needed for getpixel

    final Bounds<int> bounds = mWindow.getWindowBounds();
    final Point<int> size = mWindow.updateAndGetSize()!;
    final Bounds<int> overlayBounds = NativeOverlayWindow.getInnerOverlayAreaForWindow(mWindow);
    Logger.info(
      "Test Window Bounds $bounds related to $_width, $_height and Size $size related to app $appWidth, "
      "$appHeight. Additional overlay bounds: $overlayBounds",
    );
    expect(bounds.width == _width && bounds.height == _height, true, reason: "bounds should match test values");
    expect(size.x == appWidth && size.y == appHeight, true, reason: "size should match test values");
    expect(mWindow.isWithinWindow(bounds.pos), true, reason: "start in window");
    expect(mWindow.isWithinWindow((bounds.pos + bounds.size).move(-1, -1)), true, reason: "end in window");
    expect(mWindow.isWithinWindow(bounds.pos.move(-1, -1)), false, reason: "before not in window");
    expect(mWindow.isWithinWindow(bounds.pos + bounds.size), false, reason: "after not in window");

    expect(mWindow.isWithinInnerWindow(bounds.right - 1, size.y - 1), false, reason: "bounds x not in window");
    expect(mWindow.isWithinInnerWindow(size.x - 1, bounds.bottom - 1), false, reason: "bounds y not in window");
    expect(mWindow.isWithinInnerWindow(0, 0), true, reason: "first pos is in window");
    expect(mWindow.isWithinInnerWindow(-1, -1), false, reason: "negative not in window");
    expect(mWindow.isWithinInnerWindow(size.x, size.y), false, reason: "size not in window");
    expect(mWindow.isWithinInnerWindow(size.x - 1, size.y - 1), true, reason: "size -1 is in window");

    expect(mWindow.getPixelOfWindow(0, 0)?.equals(Colors.blue), true, reason: "top left blue (blue light filter on?)");
    expect(mWindow.getPixelOfWindow(99, 99)?.equals(Colors.blue), true, reason: "max size still blue");
    expect(mWindow.getPixelOfWindow(100, 100)?.equals(Colors.white), true, reason: "outer white");
    expect(mWindow.getPixelOfWindow(1163, 580)?.equals(Colors.white), true, reason: "before bot right white");
    expect(mWindow.getPixelOfWindow(1164, 581)?.equals(Colors.purple), true, reason: "bottom right purple");
    expect(mWindow.getPixelOfWindow(appWidth - 1, appHeight - 1)?.equals(Colors.purple), false, reason: "win11 round");
    expect(mWindow.getPixelOfWindow(appWidth - 1, appHeight - 10)?.equals(Colors.purple), true, reason: "pur1");
    expect(mWindow.getPixelOfWindow(appWidth - 10, appHeight - 1)?.equals(Colors.purple), true, reason: "pur2");
    expect(mWindow.getPixelOfWindow(appWidth, appHeight)?.equals(Colors.purple), null, reason: "no color");
    expect(mWindow.getPixelOfWindow(_width - 1, _height - 1)?.equals(Colors.purple), null, reason: "still no color");
    expect(mWindow.getPixelOfWindow(_width, _height), null, reason: "out window null");
    expect(mWindow.getPixelOfWindow(-1, -1), null, reason: "also -1 is null");

    expect(overlayBounds.size, size, reason: "overlay size should be same as normal");
    expect(
      overlayBounds.width < bounds.width && overlayBounds.height < bounds.height,
      true,
      reason: "but overlay size smaller than bounds size",
    );
    expect(overlayBounds.left, bounds.left + 8, reason: "overlay left +8");
    expect(overlayBounds.right, bounds.right + -8, reason: "overlay right -8");
    expect(overlayBounds.top, bounds.top + 31, reason: "overlay top +31");
    expect(overlayBounds.bottom, bounds.bottom - 8, reason: "overlay bot -8");

    expect(mWindow.getMiddle(), const Point<int>(632, 341), reason: "middle pos rounded");
    expect(mWindow.getPixelOfWindowP(mWindow.getMiddle())?.equals(Colors.red), true, reason: "middle pix red");

    expect(mWindow.getMiddle() == mWindow.getWindowBounds().middlePos, false, reason: "middle should not be bounds");
    expect(
      const Point<int>(650, 370) == mWindow.getWindowBounds().middlePos,
      true,
      reason: "default opening pos on windows (this might fail) tested with bounds middle pos",
    );
  });
}

void _testImages() {
  testO("raw image exception test", () async {
    final NativeImage img = await NativeImage.readAsync(path: testFile("full_crop.png"));
    expect(() async {
      await NativeImage.readAsync(path: testFile("_NOT_EXISTING.png")); // wrong img path
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
      img.getSubImage(0, 0, 1, 1); // subimg with null
    }, throwsA(predicate((Object e) => e is ImageException)));
    await img.resize(10, 10); // resize is fine, but does nothing
    expect(img.width == 0 && img.height == 0, true, reason: "still 0 size");
  });
  testO("testing raw image functions", () async {
    final int cleanups = NativeImage.cleanupCounter;
    final NativeImage full = NativeImage.readSync(path: testFile("full_crop.png"));
    final NativeImage correct = NativeImage.readSync(path: testFile("correct_crop.png"));
    final NativeImage wrong = NativeImage.readSync(path: testFile("wrong_crop.png"));
    final NativeImage corAlpha = NativeImage.readSync(
      path: testFile("correct_crop_alpha.png"),
      type: NativeImageType.RGBA,
    );
    final NativeImage corAlpha2 = NativeImage.readSync(
      path: testFile("correct_crop_alpha_2.png"),
      type: NativeImageType.RGBA,
    );
    expect(NativeImage.cleanupCounter, cleanups, reason: "read should not change type");
    final NativeImage correctWA = NativeImage.readSync(path: testFile("correct_crop.png"), type: NativeImageType.RGBA);
    expect(NativeImage.cleanupCounter, cleanups + 1, reason: "but explicit type change should!");
    final NativeImage fullGray = NativeImage.readSync(path: testFile("full_crop.png"), type: NativeImageType.GRAY);
    expect(NativeImage.cleanupCounter, cleanups + 1, reason: "but not for gray!");
    final NativeImage part = full.getSubImage(48, 47, 5, 3);
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
    expect(corAlpha.colorAtPixel(2, 1)?.alphaI, 152, reason: "alpha value in alpha");
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
    expect(scaled1.colorAtPixel(7, 2)?.equals(const Color.fromARGB(255, 249, 141, 56)), true, reason: "scaled col");
    final NativeImage gray = await full.clone();
    gray.changeTypeSync(NativeImageType.GRAY);
    expect(gray.type == NativeImageType.GRAY && fullGray.type == gray.type, true, reason: "gray types");
    expect(gray.colorAtPixel(50, 50)?.gray, 118, reason: "gray col");
    expect(gray == fullGray, true, reason: "default equal matches gray");
    expect(gray.equals(fullGray, pixelValueThreshold: 0), false, reason: "with not 1 pxl offset its not equal tho!");
  });
  testO("testing special image type hsv", () async {
    final int cleanups = NativeImage.cleanupCounter;
    final NativeImage hsv = NativeImage.readSync(path: testFile("correct_crop_alpha.png"), type: NativeImageType.HSV);
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
    expect(rgba.colorAtPixel(2, 1)?.alphaI, 255, reason: "alpha after conversion should be max");
    expect(rgb == rgba, true, reason: "conversions should be equal");
    final NativeImage hsv2 = await rgb.clone();
    hsv2.changeTypeSync(NativeImageType.HSV);
    expect(hsv2.type, NativeImageType.HSV, reason: "back to hsv");
    expect(hsv == hsv2, true, reason: "back to default should still be equal");
    rgba.changeTypeSync(NativeImageType.HSV);
    expect(rgba.type, NativeImageType.HSV, reason: "but should convert rgba back to hsv");
    hsvC = rgba.colorAtPixel(2, 1);
    expect(hsvC?.h == 2 && hsvC?.s == 199 && hsvC?.v == 244, true, reason: "converted should still have correct hsv");
    final NativeImage gray = NativeImage.readSync(path: testFile("full_crop.png"), type: NativeImageType.GRAY);
    expect(() async {
      gray.changeTypeSync(NativeImageType.HSV); // also cant convert from gray to hsv
    }, throwsA(predicate((Object e) => e is ImageException)));
    expect(() async {
      hsv.changeTypeSync(NativeImageType.GRAY); // and cant convert from hsv to gray
    }, throwsA(predicate((Object e) => e is ImageException)));
  });
  testO("testing image compare functions", () async {
    final NativeImage img1 = NativeImage.readSync(path: testFile("apple1.png"));
    final NativeImage img2 = NativeImage.readSync(path: testFile("apple2.png"));
    final double histComp = await img1.pixelSimilarity(img2, comparePixelOverall: true);
    final double pixComp = await img1.pixelSimilarity(img2, comparePixelOverall: false);
    expect(histComp.isEqual(0.94073455), true, reason: "hist comp shows 94% similarity");
    expect(pixComp.isEqual(0.26637687), true, reason: "per pixel comp only shows 26%");
  });

  testO("getting images from window and comparing pixel", () async {
    Logger.warn("this test can fail if you un focus the window");
    expect(mWindow.updateAndGetOpen(), true, reason: "windows open");
    mWindow.updateAndGetFocus(); // focus and size do not really matter here
    mWindow.updateAndGetSize();
    final Bounds<int> bounds = mWindow.getWindowBounds();
    final int cleanups = NativeImage.cleanupCounter; // other tests could change this static val
    final NativeImage cropMiddle = await mWindow.getImage(582, 290, 100, 100);
    final NativeImage display = await GameWindow.getDisplayImage();
    expect(NativeImage.cleanupCounter, cleanups, reason: "cleanup still 0(can fail cause of other tests)");
    final NativeImage fullWin = await mWindow.getFullImage(type: NativeImageType.RGB);
    expect(NativeImage.cleanupCounter, cleanups + 1, reason: "cleanup still 0(can fail cause of other tests)");
    expect(cropMiddle.type, NativeImageType.RGBA, reason: "default rgba");
    expect(fullWin.type, NativeImageType.RGB, reason: "explicit rgb type");
    expect(TestMockNativeImageWrapper(cropMiddle).native, isNotNull, reason: "rgba has native data");
    expect(TestMockNativeImageWrapper(fullWin).native, null, reason: "rgb has no native data");

    expect(fullWin.width == appWidth && fullWin.height == appHeight, true, reason: "correct window dimensions");
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
    expect(fullWin.colorAtPixel(appWidth, appHeight)?.equals(Colors.purple), null, reason: "end of win pix");
    expect(fullWin.colorAtPixel(appWidth - 1, appHeight - 1)?.equals(Colors.purple), false, reason: "ROUND CORNER");
    expect(fullWin.colorAtPixel(appWidth - 3, appHeight - 3)?.equals(Colors.purple), true, reason: "last window pixel");
    expect(
      fullWin.colorAtPixel(appWidth - 100, appHeight - 100)?.equals(Colors.purple),
      true,
      reason: "from last calculating",
    );

    final Point<int> mid = mWindow.getMiddle();
    expect(fullWin.colorAtPixel(mid.x, mid.y)?.equals(Colors.red), true, reason: "win mid1");
    expect(fullWin.colorAtPixel(mid.x + 1, mid.y + 1)?.equals(Colors.yellow), true, reason: "win mid2");
    // now translate from window pos to display pos
    expect(
      display.colorAtPixel(8 + bounds.x, 31 + bounds.y)?.equals(Colors.blue),
      true,
      reason: "same first pixel on display (might fail)",
    );
    expect(
      display.colorAtPixel(1261 + bounds.x, 711 + bounds.y)?.equals(Colors.purple),
      true,
      reason: "same last pixel on display (might fail) 1 (win11 rounded corner)",
    );
    expect(
      display.colorAtPixel(1271 + bounds.x, 701 + bounds.y)?.equals(Colors.purple),
      true,
      reason: "same last pixel on display (might fail) 2 (win11 rounded corner)",
    );
    final NativeImage part = cropMiddle.getSubImage(48, 47, 5, 3);
    expect(part == NativeImage.readSync(path: testFile("correct_crop.png")), true, reason: "sub image comp equals");
    expect(part == NativeImage.readSync(path: testFile("wrong_crop.png")), false, reason: "wrong not equal");
  });
}

void _testInput() {
  testO("focus test (only working with Command Prompt) and interact tests(moving your mouse around / using "
      "clipboard and keyboard keys, etc!)\nIMPORTANT: DON'T use your mouse and keyboard during this test and keep the"
      " terminal in focus!!!", () async {
    await GameToolsLib.close();
    final GameWindow second = GameWindow(name: "Command Prompt");
    await TestHelper.initGameToolsLib("game_tools_lib_example", <GameWindow>[second]); // additional window to _window
    await MutableConfig.mutableConfig.alwaysMatchGameWindowNamesEqual.setValue(false); // needed for cmd find
    await Utils.delayMS(55); // wait for update

    unawaited(GameToolsLib.runLoop(app: null, appWasAlreadyStarted: true));
    Logger.warn("this test can fail if you un focus the window");
    Logger.warn(
      "Remember to start the tests from the terminal command prompt and not with the run configuration: "
      "\"cd example && flutter test integration_test/native_tests.dart\""
      "and also don't use your mouse and keyboard during the tests and keep the terminal in focus!!!",
    );
    await Utils.delayMS(55); // wait for first event loop
    expect(
      second.isOpen,
      true,
      reason:
          "IMPORTANT: you have to start the tests from the command prompt and keep it in focus (don't use mouse)!\n"
          "(first cd into example dir and then run \"flutter test integration_test/native_tests.dart\") so that the "
          "test can find a window called \"Command Prompt\"",
    );
    expect(mWindow.isOpen, true, reason: "first window should also be open from loop");
    expect(mWindow.hasFocus, true, reason: "first window should have focus from loop");
    expect(second.hasFocus, false, reason: "second should not have focus from loop");
    expect(tGm.updateCounter >= 1200 && tGm.updateCounter <= 1220, true, reason: "counter open 1+2, focus 1");

    await second.setWindowFocus();
    await Utils.delayMS(55); // wait for another event loop
    expect(mWindow.hasFocus, false, reason: "window should have no focus now");
    expect(second.hasFocus, true, reason: "because second has it now");
    expect(tGm.updateCounter >= 3200 && tGm.updateCounter <= 3220, true, reason: "counter focus 2, un focus 1");

    await mWindow.setWindowFocus(); // no more loop tests below
    expect(mWindow.updateAndGetFocus(), true, reason: "window should have focus after change");
    expect(second.updateAndGetFocus(), false, reason: "and second should not");
    await mWindow.moveMouse(80, 640, xRadius: 0, yRadius: 0);
    expect(mWindow.windowMousePos, const Point<int>(80, 640), reason: "first move mouse should match");
    await InputManager.leftClick();
    await Utils.delayMS(25);
    expect(find.text(TestColouredBoxes.afterButtonText), findsOneWidget, reason: "button should be clicked");
    await mWindow.moveMouse(1130, 50, xRadius: 0, yRadius: 0);
    expect(mWindow.windowMousePos, const Point<int>(1130, 50), reason: "second move mouse should match");
    await InputManager.leftClick();
    final String userClip = await InputManager.getClipboard();
    const String preClip = "_before_test_data";
    await InputManager.setClipboard(preClip);
    final String testData = await InputManager.getSelectedData(selectFirst: true);
    const String afterTestData = "_after_test_data_시험";
    await InputManager.pasteDataIntoSelected(afterTestData);
    final String shouldBePreAgain = await InputManager.getClipboard();
    await InputManager.setClipboard(userClip);
    expect(preClip, shouldBePreAgain, reason: "old clipboard should stay untouched (also restored user clip)");
    expect(testData, TestColouredBoxes.afterButtonText, reason: "copy selected data");
    await Utils.delayMS(25);
    expect(find.text(afterTestData), findsOneWidget, reason: "paste data into selected");
    Logger.info("Testing if a key is down is not done here, because it needs real user input");
  });
}
