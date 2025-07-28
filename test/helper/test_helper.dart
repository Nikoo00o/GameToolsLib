import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/logger/custom_logger.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_config.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_game_manager.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_state.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:integration_test/integration_test.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import 'test_widgets.dart';

/// This just calls [TestHelper.testDefault] and should be used with [TestHelper.runDefaultTests]!
void testD(String name, Future<void> Function() callback) => TestHelper.testDefault(name, callback);

/// This just calls [TestHelper.testOrdered] and should be used with [TestHelper.runOrderedTests]
void testO(
  String name,
  InnerTestCallback callback, {
  bool initDefaultGameToolsLib = true,
}) => TestHelper.testOrdered(
  name,
  callback,
  initDefaultGameToolsLib: initDefaultGameToolsLib,
);

/// Rarely used in tests manually to init lib with example config. For more params, use [TestHelper.initGameToolsLib]
Future<bool> initDefaultGameToolsLib() async =>
    GameToolsLib.useExampleConfig(isCalledFromTesting: true, windowName: "Not_Found");

String get testFolder => TestHelper.testFolder;

String testFile(String fileName) => TestHelper.testFile(fileName);

/// If widget test of started app
WidgetTester get widgetTester => TestHelper.widgetTester;

/// If widget test of started app
int get appWidth => TestHelper.appWidth;

/// If widget test of started app
int get appHeight => TestHelper.appHeight;

/// Returns the main window
GameWindow get mWindow => GameToolsLib.mainGameWindow;

/// Test game manager
ExampleGameManager get tGm => GameToolsLib.gameManager<ExampleGameManager>();

/// Example state (can also throw exception if not correct type)
ExampleState get eState => tGm.getCurrentState();

/// Used to provide commonly used methods for testing
abstract final class TestHelper {
  /// Used to create groups with functions that call default tests [testD] / [testDefault]
  static Future<void> runDefaultTests({
    Future<void> Function()? beforeAllTests,
    Future<void> Function()? beforeTest,
    Future<void> Function()? afterTest,
    required Map<String, TestFunction> testGroups,
  }) async {
    Logger.initLoggerInstance(StartupLogger()); // first prepare logger for tests
    await beforeAllTests?.call();
    setUp(() async => beforeTest?.call());
    tearDown(() async => afterTest?.call());
    for (final MapEntry<String, TestFunction> g in testGroups.entries) {
      group(g.key, g.value); // name : test function
    }
    await Logger.waitForLoggingToBeDone();
  }

  /// Test multiple tests at the same time, but additionally also awaits the logger (used with [runDefaultTests])
  static void testDefault(String name, InnerTestCallback callback) {
    test(name, () async {
      try {
        await callback.call();
        await Logger.waitForLoggingToBeDone();
      } catch (e, s) {
        Logger.error("Failed $name", e, s);
        await Logger.waitForLoggingToBeDone();
        rethrow;
      }
    });
  }

  /// Returns path to the folder "project/test/test_data"
  static String get testFolder => FileUtils.combinePath(<String>[FileUtils.getLocalFilePath("test"), "test_data"]);

  /// Returns the path to a testfile with the name [fileName] in the folder "project/test/test_data"
  static String testFile(String fileName) => FileUtils.combinePath(<String>[testFolder, fileName]);

  /// Can be accessed for widget tests started with [runOrderedTests]
  static WidgetTester get widgetTester => _tester!;

  /// See [runOrderedTests]
  static String get defaultAppTitle => "game_tools_lib_example";

  /// See [runOrderedTests]
  static Widget get defaultAppBody => TestColouredBoxes();

  /// Used to create groups with functions that call ordered tests [testO] / [testOrdered].
  ///
  /// If [appTitle] and [appBody] are not null, then this will be run as a widget test and also open an app!
  /// The [appTitle] would also be used to init the for the tests where [_Test.initLib] is true, otherwise "Not_Found"
  /// is used! Use default values [defaultAppTitle] and [defaultAppBody] in most widget tests!
  static Future<void> runOrderedTests({
    required String parentDescription,
    Future<void> Function()? beforeAllTests,
    Future<void> Function()? beforeTest,
    Future<void> Function()? afterTest,
    required Map<String, void Function()> testGroups,
    String? appTitle,
    Widget? appBody,
  }) async {
    Logger.initLoggerInstance(StartupLogger()); // first prepare logger for tests
    if (_groups.isNotEmpty) {
      Logger.warn("Running tests $parentDescription when runOrderedTests was already called is dangerous!");
      _groups.clear();
      _errors.clear();
    }
    _mainWindowTitle = appTitle ?? "Not_Found";
    if (appTitle != null && appBody != null) {
      final IntegrationTestWidgetsFlutterBinding binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
      binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
      binding.shouldPropagateDevicePointerEvents = true; // otherwise we could not interact with the test app
      WidgetsFlutterBinding.ensureInitialized();
    }

    await beforeAllTests?.call();
    for (final MapEntry<String, TestFunction> g in testGroups.entries) {
      _groups.add(_TestGroup(g.key));
      g.value.call();
    }

    if (appTitle != null && appBody != null) {
      testWidgets(parentDescription, (WidgetTester tester) async {
        _tester = tester;
        await tester.pumpWidget(TestApp(title: appTitle, child: appBody));
        await tester.pumpAndSettle(const Duration(milliseconds: 25));
        final Size size = tester.view.physicalSize;
        appWidth = size.width.round();
        appHeight = size.height.round();
        await Utils.delay(const Duration(milliseconds: 75)); // small delay until window is open
        await _runOrdered(beforeTest, afterTest);
      });
    } else {
      test(parentDescription, () async => _runOrdered(beforeTest, afterTest));
    }
  }

  /// Test multiple tests in order one after another (used with [runOrderedTests]) where [callback] is the test to be
  /// run.
  /// If [initDefaultGameToolsLib] is true, then init and close will be called with a small delay!
  static void testOrdered(
    String name,
    InnerTestCallback callback, {
    required bool initDefaultGameToolsLib,
  }) {
    _groups.last.tests.add(_Test(name, callback, initLib: initDefaultGameToolsLib));
  }

  /// Initializes [GameToolsLib] with a default [ExampleGameToolsConfig] for testing, creating a game window for the
  /// [searchName], but can also add the [moreWindows]. For less params, use [initDefaultGameToolsLib]
  static Future<void> initGameToolsLib(String searchName, [List<GameWindow> moreWindows = const <GameWindow>[]]) async {
    final bool result = await GameToolsLib.initGameToolsLib(
      config: ExampleGameToolsConfig(),
      gameManager: ExampleGameManager(inputListeners: null),
      isCalledFromTesting: true,
      gameWindows: GameToolsLib.createDefaultWindowForInit(searchName)..addAll(moreWindows),
      gameLogWatcher: GameLogWatcher.empty(),
    );
    if (result == false) {
      throw const TestException(message: "TestHelper.initGameToolsLib failed");
    }
  }

  static Future<void> _runOrdered(Future<void> Function()? beforeTest, Future<void> Function()? afterTest) async {
    int testCount = 0;
    for (final _TestGroup group in _groups) {
      testCount += group.tests.length;
    }
    int counter = 0;
    for (final _TestGroup group in _groups) {
      for (final _Test test in group.tests) {
        final String step = "${counter + 1}/$testCount";
        final String testName = "${group.name}--${test.name}";
        Logger.info("$step Running Test $testName");
        try {
          await Logger.waitForLoggingToBeDone();
          if (test.initLib) {
            await initGameToolsLib(_mainWindowTitle);
            HiveDatabaseMock.throwExceptionInInit = false;
            await Future<void>.delayed(const Duration(milliseconds: 5));
            await Logger.waitForLoggingToBeDone();
          }
          await beforeTest?.call();
          await test.callback.call();
          counter++;
        } catch (e, s) {
          Logger.error("$step Error in Test $testName, see below");
          _errors.add(("Failed Test $step $testName with exception: ", e, s));
        }
        await afterTest?.call();
        if (GameToolsLib.wasInitStarted) {
          await Logger.waitForLoggingToBeDone();
          await GameToolsLib.close();
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        await Logger.waitForLoggingToBeDone();
      }
    }
    for (final (String log, Object? e, StackTrace? s) in _errors) {
      Logger.error(log, e, s);
    }
    Logger.info("Completed $counter/$testCount tests successfully!");
    await Logger.waitForLoggingToBeDone();
    if (_errors.isNotEmpty) {
      throw TestFailure("Some tests failed! See above!");
    }
  }

  static final List<_TestGroup> _groups = <_TestGroup>[];
  static final List<_ErrorGroup> _errors = <_ErrorGroup>[];
  static WidgetTester? _tester;
  static String _mainWindowTitle = "";

  /// Will be set to the title of the started app when testing something with widgets!
  static String get mainWindowTitle => _mainWindowTitle;

  /// Only used for widget tests
  static int appWidth = 1264;

  /// Only used for widget tests
  static int appHeight = 681;
}

class _TestGroup {
  final String name;
  List<_Test> tests = <_Test>[];

  _TestGroup(this.name);
}

class _Test {
  final String name;
  final InnerTestCallback callback;
  final bool initLib;

  _Test(this.name, this.callback, {required this.initLib});
}

typedef TestFunction = void Function();
typedef InnerTestCallback = Future<void> Function();
typedef _ErrorGroup = (String, Object?, StackTrace?);

void testOpenCv() {
  test("external testing raw opencv functions when including the lib", () async {
    final String ver = cv.openCvVersion();
    expect(ver.isNotEmpty, true, reason: "has version");
    final cv.Mat mat = cv.Mat.empty();
    expect(mat.channels, 1, reason: "empty mat channel 1");
    expect(mat.clone().isEmpty, true, reason: "clone still empty");
  });
}
