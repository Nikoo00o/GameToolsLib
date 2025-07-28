import 'dart:convert';
import 'dart:io';
import 'dart:math' show Point;
import 'dart:typed_data';

import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:game_tools_lib/core/encoding/utf16.dart';
import 'package:game_tools_lib/core/utils/utils.dart';

import 'helper/test_helper.dart';

//ignore_for_file: avoid_print
//ignore_for_file: prefer_const_constructors

/// Some logs may not be printed in tests if an expect fails, because the print was not flushed to the console yet!
Future<void> main() async {
  _debugTest();
  await TestHelper.runDefaultTests(
    testGroups: <String, TestFunction>{
      "General Utils": _testGeneral,
      "File Utils": _testFiles,
      "Num Utils": _testNum,
    },
  );
}

// used for debugging some times
void _debugTest() {
  test("debug test", () async {
    print("Was run from tests: ${FileUtils.wasRunFromTests}");
  });
}

void _testGeneral() {
  testD("list equality", () async {
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
  testD("color equality", () async {
    const Color c1 = Color.fromARGB(125, 125, 125, 125);
    const Color c2 = Color.fromARGB(125, 125, 125, 125);
    const Color c3 = Color.fromARGB(123, 125, 125, 125);
    const Color c4 = Color.fromARGB(125, 123, 125, 125);
    const Color c5 = Color.fromARGB(125, 126, 125, 125);
    expect(c1.equals(c2, skipAlpha: false), true, reason: "same color match");
    expect(c1.equals(c3, skipAlpha: false), false, reason: "alpha diff");
    expect(c1.equals(c3), true, reason: "alpha ignored");
    expect(c1.equals(c4, skipAlpha: false), false, reason: "green diff");
    expect(c1.equals(c5), true, reason: "not enough diff");
    expect(c1.equals(c5, pixelValueThreshold: 0), false, reason: "now diff is enough");
  });
  testD("periodic execute sync and async correctly", () async {
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
  testD("periodic execute only count once with delays", () async {
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
  testD("periodic execute all times with no delay", () async {
    int counter = 0;
    Future<void> callback() async {
      counter -= 1;
    }

    for (int i = 0; i < 25; ++i) {
      await Utils.executePeriodicAsync(delay: Duration.zero, callback: callback);
    }
    expect(counter, -25, reason: "sync counter only counted once");
  });

  testD("periodic execute error with unnamed lambda function", () async {
    int counter = 0;
    expect(() async {
      for (int i = 0; i < 11000; ++i) {
        Utils.executePeriodicSync(delay: Duration.zero, callback: () => counter += 100);
      }
    }, throwsAssertionError);
  });

  testD("bounds ", () async {
    final Bounds<int> b1 = Bounds<int>(x: 3, y: 5, width: 13, height: 15);
    final Bounds<double> b2 = Bounds<double>.sides(left: 3.0, top: 5.0, right: 16.0, bottom: 20.0);
    expect(b1 == b2, true, reason: "different constructors and types should match!");
    expect(b1.middlePos, const Point<int>(10, 13), reason: "int middle pos rounded up");
    expect(b2.middlePos, const Point<double>(9.5, 12.5), reason: "double middle pos");
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
    expect(b1.scale(0.5, 1.5), Bounds<int>(x: 2, y: 8, width: 7, height: 23), reason: "scale int up");
    expect(b1.scale(0.49, 1.49), Bounds<int>(x: 1, y: 7, width: 6, height: 22), reason: "scale int down");
    expect(b2.scale(0.5, 1.5), Bounds<double>(x: 1.5, y: 7.5, width: 6.5, height: 22.5), reason: "scale double");
    expect(b1.contains(b1.middlePos), true, reason: "int middle contains");
    expect(b2.contains(b2.middlePos), true, reason: "double middle contains");
    expect(b2.contains(const Point<double>(3.0, 5.0)), true, reason: "contain top left corner");
    expect(b2.contains(const Point<double>(16.0, 20.0)), true, reason: "contain bot right corner");
    expect(b1.contains(const Point<int>(2, 10)), false, reason: "not contain left out");
    expect(b1.contains(const Point<int>(10, 4)), false, reason: "not contain top out");
    expect(b1.contains(const Point<int>(17, 10)), false, reason: "not contain right out");
    expect(b1.contains(const Point<int>(10, 21)), false, reason: "not contain bottom out");

    const String modelJson =
        "{\"JSON_POS\":{\"JSON_X\":3.0,\"JSON_Y\":5.0},\"JSON_SIZE\":{\"JSON_X\":13.0,\"JSON_Y\":15.0}}";
    expect(jsonEncode(b2), modelJson, reason: "bounds model should match");
    expect(
      Bounds<double>.fromJson(jsonDecode(modelJson) as Map<String, dynamic>),
      b2,
      reason: "new object from json should be equal",
    );
  });
}

void _testFiles() {
  const String cmp1 = "2test1\r\nöäü\r\n시험\r\n1\r\n2\r\n3\r\n4\r\n";
  testD("String split to lines", () async {
    const String d1 = "one\ntwo";
    const String d2 = "one\r\ntwo";
    const String d3 = "one\r\ntwo\nthree\n";
    final List<String> l1 = StringUtils.splitIntoLines(d1);
    final List<String> l2 = StringUtils.splitIntoLines(d2);
    final List<String> l3 = StringUtils.splitIntoLines(d3);
    expect(l1.length, 2, reason: "l1 length");
    expect(l2.length, 2, reason: "l2 length");
    expect(l3.length, 4, reason: "l3 length");
    expect(l1[0].length == 3 && l1[1].length == 3, true, reason: "l1 element");
    expect(l2[0].length == 3 && l2[1].length == 3, true, reason: "l2 element");
    expect(l3[0].length == 3 && l3[3].isEmpty, true, reason: "l3 element");
  });

  testD("Reading Utf files", () async {
    const String cmp2 = "2test1\nöäü\n시험\n1\n2\n3\n4\n";
    final String text8as8 = await FileUtils.readFile(testFile("utf8.txt"), encoding: utf8);
    final String text8as16 = await FileUtils.readFile(testFile("utf8.txt"), encoding: utf16);
    final String text16as16Be = await FileUtils.readFile(testFile("be_utf16.txt"), encoding: utf16);
    final String text16as16Le = await FileUtils.readFile(testFile("le_utf16.txt"), encoding: utf16);
    expect(() async {
      await FileUtils.readFile(testFile("be_utf16.txt"), encoding: utf8); // reading utf16 file as utf 8
    }, throwsA(predicate((Object e) => e is FileSystemException)));
    expect(text8as8, cmp1, reason: "correct utf8 data");
    expect(text8as16, "㉴敳琱ഊ쎶쎤쎼ഊ鳭鞘ഊㄍਲഊ㌍਴ഊ", reason: "wrong encoding read");
    expect(text16as16Be, cmp1, reason: "correct utf16-be data");
    expect(text16as16Le, cmp2, reason: "correct utf16-le data");
    final Uint8List? beBytes = await FileUtils.readFileAsBytes(testFile("be_utf16.txt"));
    final Uint8List? leBytes = await FileUtils.readFileAsBytes(testFile("le_utf16.txt"));
    expect(beBytes?.length, 60, reason: "be bytes correctly saved");
    expect(leBytes?.length, 46, reason: "wrong line breaks");

    final String writePath = testFile("write_test.txt");
    await FileUtils.deleteFile(writePath);
    await FileUtils.writeFile(writePath, text16as16Be, encoding: utf16);
    await FileUtils.addToFile(writePath, "1", encoding: utf16);
    expect(() async {
      await FileUtils.readFile(writePath, encoding: utf8); // reading utf16 file as utf 8
    }, throwsA(predicate((Object e) => e is FileSystemException)));
    final String writtenStr = await FileUtils.readFile(writePath, encoding: utf16);
    final Uint8List? writtenAsBytes = await FileUtils.readFileAsBytes(writePath);
    expect(writtenStr.startsWith(text16as16Be) && writtenStr.endsWith("1"), true, reason: "resave should be correct");
    expect(writtenAsBytes?.length, 64, reason: "resave should be correct bytes as well");
    await FileUtils.deleteFile(writePath);
  });

  testD("Reading Utf8 file at positions", () async {
    final File file = File(testFile("utf8.txt"));
    final String p1 = await FileUtils.readFileAtPos(file: file, pos: 0, size: 5);
    final String p2 = await FileUtils.readFileAtPos(file: file, pos: 16, size: 6);
    final String p3 = await FileUtils.readFileAtPos(file: file, pos: 24);
    final String n = await FileUtils.readFileAtPos(file: file, pos: 35);
    final List<String> lines = await FileUtils.readFileAtPosInLines(file: file, pos: 6);
    expect(p1, "2test", reason: "first part of file");
    expect(p2, "시험", reason: "special char part");
    expect(p3, "1\r\n2\r\n3\r\n4\r\n", reason: "last part of file");
    expect(n, "\n", reason: "last \n");
    expect(lines.length, 8, reason: "8 lines");
    expect(lines[0].isEmpty && lines[7].isEmpty, true, reason: "first and last empty");
    expect(lines[1], "öäü", reason: "second line correct");
    expect(lines[2], "시험", reason: "third line correct");
    expect(lines[3], "1", reason: "fourth line correct");
  });
}

void _testNum() {
  testD("primitive extensions", () async {
    expect(2.scale(2.6), 5, reason: "int scale");
    expect(1.0.isEqual(1.000001), true, reason: "double equal");
    expect(1.0.isEqual(1.1), false, reason: "double not equal");
    expect(0.000001.isZero(), true, reason: "double zero");
    expect(0.01.isZero(), false, reason: "double not zero");
    expect(1.01.isLessThan(1.02), true, reason: "double less");
    expect(1.02.isMoreThan(1.01), true, reason: "double more");
    expect(1.0000001.isLessThan(1.0000009) || 1.0000009.isMoreThan(1.0000001), false, reason: "not less and not more");
  });
  testD("point functions ", () async {
    expect(Point<int>(1, -1).equals(Point<int>(1, -1)), true, reason: "int comp");
    expect(Point<double>(1.01, -1.01).equals(Point<double>(1.01, -1.01)), true, reason: "double comp");
    expect(Point<double>(3.2, 4.2).equals(Point<int>(3, 4)), false, reason: "double int comp");
    expect(Point<double>(3, 4).equals(Point<int>(3, 4)), true, reason: "double int comp true");
    expect(Point<int>(0, -1).abs(), Point<int>(0, 1), reason: "int abs");
    expect(Point<double>(-10, 0.0).abs(), Point<double>(10, 0.0), reason: "double abs");
    expect(Point<int>(0, 0).abs(higherThanZero: true), Point<int>(1, 1), reason: "int abs 0");
    expect(Point<double>(0.0, 0.0).abs(higherThanZero: true), Point<double>(0.0001, 0.0001), reason: "double abs 0");
    expect(Point<int>(4, 5).raiseTo(6), Point<int>(6, 8), reason: "int raise round up");
    expect(Point<int>(4, 5).raiseTo(5), Point<int>(5, 6), reason: "int raise round down");
    expect(Point<double>(4.0, 5.0).raiseTo(6.0), Point<double>(6.0, 7.5), reason: "double raise");
    expect(Point<double>(39, 78).normalize().equals(Point<double>(0.4472135, 0.8944271)), true, reason: "normalize");
  });
  testD("random functions", () async {
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
