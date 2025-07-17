import 'dart:convert';
import 'dart:math' show Point;
import 'dart:ui' show Color;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tools_lib/core/logger/custom_logger.dart';
import 'package:game_tools_lib/core/logger/log_level.dart';
import 'package:game_tools_lib/core/utils/utils.dart';

/// Some logs may not be printed in tests if an expect fails, because the print was not flushed to the console yet!
void main() {
  group("GameToolsLib Utils Tests: ", () {
    setUp(() async {
      // no startup needed here
    });

    tearDown(() async {
      // no cleanup needed here
    });
    group("General Utils Tests: ", _testGeneral);
    group("Num Utils Tests: ", _testNum);
  });
}

Future<void> _test(String name, Future<void> Function() callback) async {
  test(name, () async {
    try {
      await callback.call();
    } catch (e, s) {
      await StartupLogger().log("Failed $name", LogLevel.ERROR, e, s);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      rethrow;
    }
  });
}

void _testGeneral() {
  _test("list equality", () async {
    final List<int> li1 = <int>[1, 2, 3];
    final List<int> li2 = <int>[1, 2, 3];
    final List<int> li3 = <int>[1, 4, 3];
    final List<int> li4 = <int>[1, 2];
    expect(li1.equals(li2), true, reason: "equal lists");
    expect(li1.equals(li3), false, reason: "not equal");
    expect(li4.equals(li1), false, reason: "different sizes");
    expect((li1 == li1) == (li1.equals(li1)), true, reason: "same as identity");
    expect(ListUtils.equals(li1, <String>["1", "2"]), false, reason: "no exception with different lists");
  });
  _test("color equality", () async {
    final Color c1 = Color.fromARGB(125, 125, 125, 125);
    final Color c2 = Color.fromARGB(125, 125, 125, 125);
    final Color c3 = Color.fromARGB(123, 125, 125, 125);
    final Color c4 = Color.fromARGB(125, 123, 125, 125);
    final Color c5 = Color.fromARGB(125, 126, 125, 125);
    expect(c1.equals(c2, skipAlpha: false), true, reason: "same color match");
    expect(c1.equals(c3, skipAlpha: false), false, reason: "alpha diff");
    expect(c1.equals(c3), true, reason: "alpha ignored");
    expect(c1.equals(c4, skipAlpha: false), false, reason: "green diff");
    expect(c1.equals(c5), true, reason: "not enough diff");
    expect(c1.equals(c5, pixelValueThreshold: 0), false, reason: "now diff is enough");
  });
  _test("periodic execute sync and async correctly", () async {
    int syncCounter = 0;
    int asyncCounter = 0;
    void syncCallback() {
      syncCounter++;
    }

    Future<void> asyncCallback() async {
      asyncCounter++;
    }

    const Duration delay = Duration(milliseconds: 15);
    for (int i = 0; i < 7; ++i) {
      Utils.executePeriodicSync(delay: delay * 2, callback: syncCallback);
      await Utils.executePeriodicAsync(delay: delay * 2, callback: asyncCallback);
      await Utils.delay(delay);
    }
    expect(syncCounter, 4, reason: "sync counter should be half");
    expect(asyncCounter, 4, reason: "async counter should be half");
  });
  _test("periodic execute only count once with delays", () async {
    const Duration delay = Duration(milliseconds: 50);
    int counter = 0;
    Future<void> callback() async {
      counter -= 1;
    }

    for (int i = 0; i < 25; ++i) {
      await Utils.executePeriodicAsync(delay: delay, callback: callback);
    }
    expect(counter, -1, reason: "sync counter only counted once");
  });
  _test("periodic execute all times with no delay", () async {
    int counter = 0;
    Future<void> callback() async {
      counter -= 1;
    }

    for (int i = 0; i < 25; ++i) {
      await Utils.executePeriodicAsync(delay: Duration.zero, callback: callback);
    }
    expect(counter, -25, reason: "sync counter only counted once");
  });

  _test("periodic execute error with unnamed lambda function", () async {
    int counter = 0;
    expect(() async {
      for (int i = 0; i < 11000; ++i) {
        Utils.executePeriodicSync(delay: Duration.zero, callback: () => counter += 100);
      }
    }, throwsAssertionError);
  });

  _test("bounds ", () async {
    final Bounds<int> b1 = Bounds<int>(x: 3, y: 5, width: 13, height: 15);
    final Bounds<double> b2 = Bounds<double>.sides(left: 3.0, top: 5.0, right: 16.0, bottom: 20.0);
    expect(b1 == b2, true, reason: "different constructors and types should match!");
    expect(b1.middlePos, Point<int>(9, 12), reason: "int middle pos");
    expect(b2.middlePos, Point<double>(9.5, 12.5), reason: "double middle pos");
    expect(b1.move(3, 4), Bounds<int>(x: 6, y: 9, width: 13, height: 15), reason: "move check");
    expect(
      b1 + Bounds<int>(x: 1, y: 2, width: 3, height: 4),
      Bounds<int>(x: 4, y: 7, width: 16, height: 19),
      reason: "+ check",
    );
    expect(
      b1 - Bounds<int>(x: 1, y: 2, width: 3, height: 4),
      Bounds<int>(x: 2, y: 3, width: 10, height: 11),
      reason: "- check",
    );
    expect(b1.scale(0.5, 1.5), Bounds<int>(x: 1, y: 7, width: 6, height: 22), reason: "scale int");
    expect(b2.scale(0.5, 1.5), Bounds<double>(x: 1.5, y: 7.5, width: 6.5, height: 22.5), reason: "scale double");
    expect(b1.contains(b1.middlePos), true, reason: "int middle contains");
    expect(b2.contains(b2.middlePos), true, reason: "double middle contains");
    expect(b2.contains(Point<double>(3.0, 5.0)), true, reason: "contain top left corner");
    expect(b2.contains(Point<double>(16.0, 20.0)), true, reason: "contain bot right corner");
    expect(b1.contains(Point<int>(2, 10)), false, reason: "not contain left out");
    expect(b1.contains(Point<int>(10, 4)), false, reason: "not contain top out");
    expect(b1.contains(Point<int>(17, 10)), false, reason: "not contain right out");
    expect(b1.contains(Point<int>(10, 21)), false, reason: "not contain bottom out");

    final String modelJson =
        "{\"JSON_POS\":{\"JSON_X\":3.0,\"JSON_Y\":5.0},\"JSON_SIZE\":{\"JSON_X\":13.0,\"JSON_Y\":15.0}}";
    expect(jsonEncode(b2), modelJson, reason: "bounds model should match");
    expect(
      Bounds<double>.fromJson(jsonDecode(modelJson) as Map<String, dynamic>),
      b2,
      reason: "new object from json should be equal",
    );
  });
}

void _testNum() {
  _test("primitive extensions", () async {
    expect(2.scale(2.6), 5, reason: "int scale");
    expect(1.0.isEqual(1.000001), true, reason: "double equal");
    expect(1.0.isEqual(1.1), false, reason: "double not equal");
    expect(0.000001.isZero(), true, reason: "double zero");
    expect(0.01.isZero(), false, reason: "double not zero");
    expect(1.01.isLessThan(1.02), true, reason: "double less");
    expect(1.02.isMoreThan(1.01), true, reason: "double more");
    expect(1.0000001.isLessThan(1.0000009) || 1.0000009.isMoreThan(1.0000001), false, reason: "not less and not more");
  });
  _test("point functions ", () async {
    expect(Point<int>(1, -1).equals(Point<int>(1, -1)), true, reason: "int comp");
    expect(Point<double>(1.01, -1.01).equals(Point<double>(1.01, -1.01)), true, reason: "double comp");
    expect(Point<double>(3.2, 4.2).equals(Point<int>(3, 4)), false, reason: "double int comp");
    expect(Point<double>(3, 4).equals(Point<int>(3, 4)), true, reason: "double int comp true");
    expect(Point<int>(0, -1).abs(), Point<int>(0, 1), reason: "int abs");
    expect(Point<double>(-10, 0.0).abs(), Point<double>(10, 0.0), reason: "double abs");
    expect(Point<int>(0, 0).abs(higherThanZero: true), Point<int>(1, 1), reason: "int abs 0");
    expect(Point<double>(0.0, 0.0).abs(higherThanZero: true), Point<double>(0.0001, 0.0001), reason: "double abs 0");
    expect(Point<int>(4, 5).raiseTo(6), Point<int>(6, 7), reason: "int raise");
    expect(Point<double>(4.0, 5.0).raiseTo(6.0), Point<double>(6.0, 7.5), reason: "double raise");
    expect(Point<double>(39, 78).normalize().equals(Point<double>(0.4472135, 0.8944271)), true, reason: "normalize");
  });
  _test("random functions", () async {
    bool was1 = false;
    bool was2 = false;
    bool was3 = false;
    bool was0 = false;
    for (int i = 0; i < 2000; ++i) {
      final int rand = NumUtils.getRandomNumber(1, 2);
      switch (rand) {
        case 1:
          was1 = true;
        case 2:
          was2 = true;
        case 3:
          was3 = true;
        default:
          was0 = true;
      }
    }
    expect(was1 && was2 && !was3 && !was0, true, reason: "rand should only produce number range");
    expect(NumUtils.gcd(48, 57), 3, reason: "test gcd");
    expect(NumUtils.gcd(148, 157), 1, reason: "also test gcd 1");
  });
}
