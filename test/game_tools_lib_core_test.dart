import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/enums/log_level.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/domain/entities/base/model.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'helper/test_game_manager.dart';
import 'helper/test_helper.dart';

Future<void> main() async {
  // don't run tests asynchronous, but rather after another here, because they have to interact with the same static
  // variables!
  await TestHelper.runOrderedTests(
    parentDescription: "Game_Tools_Lib_Core_Tests",
    testGroups: <String, TestFunction>{
      "Initialization": _testInit,
      "Database+Config": _testConfigDB,
    },
  );
}

GameToolsConfigBaseType get _baseConfig =>
    GameToolsConfigBaseType(fixed: const FixedConfig(), mutable: MutableConfig());

void _testInit() {
  testO("initialize game tools lib with default example config", () async {
    final bool success = await initDefaultGameToolsLib();
    expect(success, true);
    expect(GameToolsLib.baseConfig.fixed.logIntoStorage, false, reason: "log into storage is false");
    expect(await GameToolsLib.baseConfig.mutable.logLevel.getValue(), LogLevel.SPAM, reason: "log level is spam");
    expect(GameToolsLib.database.basePath, HiveDatabaseMock.FLUTTER_TEST_PATH, reason: "database path is testing");
    expect(GameToolsLib.baseConfig.mutable.logLevel.titleKey, "config.example.logLevel", reason: "key is changed");
    expect(GameToolsLib.baseConfig.fixed.logPeriodicSpamDelayMS, 0, reason: "periodic spam delay always");
  }, initDefaultGameToolsLib: false);
  testO("initialize game tools lib with default base config", () async {
    final bool success = await GameToolsLib.initGameToolsLib(
      config: _baseConfig,
      gameManager: TestGameManager(),
      isCalledFromTesting: true,
      gameWindows: GameToolsLib.createDefaultWindowForInit("Not_Found"),
      gameLogWatcher: GameLogWatcher.empty(),
    );
    expect(success, true);
    expect(GameToolsLib.baseConfig.fixed.logIntoStorage, true, reason: "log into storage is true");
    expect(await GameToolsLib.baseConfig.mutable.logLevel.getValue(), LogLevel.SPAM, reason: "log level is spam");
    expect(GameToolsLib.baseConfig.fixed.logPeriodicSpamDelayMS, 150, reason: "periodic spam delay is max long delay");
  }, initDefaultGameToolsLib: false);
  testO("simulating database error in init should return false", () async {
    HiveDatabaseMock.throwExceptionInInit = true;
    expect(await initDefaultGameToolsLib(), false);
    HiveDatabaseMock.throwExceptionInInit = false;
  }, initDefaultGameToolsLib: false);
  testO("user initializing game tools lib twice should just return true", () async {
    final bool success = await initDefaultGameToolsLib();
    expect(success, true);
  });
  testO("user initializing game tools lib while there is already a config", () async {
    GameToolsLib.testResetInitialized();
    expect(() async {
      await initDefaultGameToolsLib();
    }, throwsA(predicate((Object e) => e is ConfigException)));
  });
  testO("user initializing game tools lib with empty window list should throw an exception", () async {
    expect(() async {
      await GameToolsLib.initGameToolsLib(
        config: _baseConfig,
        gameManager: TestGameManager(),
        isCalledFromTesting: true,
        gameWindows: <GameWindow>[],
        gameLogWatcher: GameLogWatcher.empty(),
      );
    }, throwsA(predicate((Object e) => e is ConfigException)));
  }, initDefaultGameToolsLib: false);
  testO("initialize game tools lib with multiple game windows should still work", () async {
    final bool success = await GameToolsLib.initGameToolsLib(
      config: _baseConfig,
      gameManager: TestGameManager(),
      isCalledFromTesting: true,
      gameWindows: <GameWindow>[
        GameWindow(name: "first"),
        GameWindow(name: "second"),
      ],
      gameLogWatcher: GameLogWatcher.empty(),
    );
    expect(success, true);
    expect(GameToolsLib.mainGameWindow.name, "first", reason: "first name should be correct");
    expect(GameToolsLib.gameWindows.elementAt(1).name, "second", reason: "second name should be correct");
  }, initDefaultGameToolsLib: false);
}

void _testConfigDB() {
  testO("testing database cache", () async {
    LogLevelConfigOption logLevel = LogLevelConfigOption(titleKey: "logLevel", defaultValue: LogLevel.VERBOSE);
    expect(logLevel.cachedValue(), LogLevel.VERBOSE, reason: "cache is initially set to default");
    await logLevel.setValue(LogLevel.INFO);
    expect(logLevel.cachedValue(), LogLevel.INFO, reason: "cache is updated after set");
    logLevel.onlyUpdateCachedValue(null);
    await logLevel.getValue();
    expect(logLevel.cachedValue(), LogLevel.INFO, reason: "cache is updated after get");
    await logLevel.deleteValue();
    expect(logLevel.cachedValue(), LogLevel.VERBOSE, reason: "after delete cache is back to default");
    logLevel = LogLevelConfigOption(titleKey: "logLevel");
    expect(logLevel.cachedValue(), null, reason: "with no default, cache is initially null");
    logLevel = LogLevelConfigOption(titleKey: "logLevel", defaultValue: LogLevel.DEBUG);
    await logLevel.setValue(null);
    expect(logLevel.cachedValue(), LogLevel.DEBUG, reason: "set to null not best behaviour still return default");
    expect(await logLevel.getValue(), null, reason: "but normal get correctly returns null");
  });

  testO("testing database get/set", () async {
    LogLevelConfigOption logLevel = LogLevelConfigOption(titleKey: "logLevel", defaultValue: LogLevel.VERBOSE);
    expect(await logLevel.getValue(), LogLevel.VERBOSE, reason: "return default with null");
    await logLevel.setValue(LogLevel.INFO);
    expect(await logLevel.getValue(), LogLevel.INFO, reason: "return updated after set");
    logLevel.onlyUpdateCachedValue(null);
    expect(await logLevel.getValue(), LogLevel.INFO, reason: "still return updated after clearing cache");
    await logLevel.deleteValue();
    expect(await logLevel.getValue(), LogLevel.VERBOSE, reason: "return default after delete");
    await logLevel.setValue(null);
    expect(await logLevel.getValue(), null, reason: "return null after explicit set to null");
    logLevel = LogLevelConfigOption(titleKey: "logLevel");
    expect(await logLevel.getValue(), null, reason: "return null with no default");
    await logLevel.setValue(LogLevel.INFO);
    await logLevel.deleteValue();
    expect(await logLevel.getValue(), null, reason: "still return null after set and delete");
  });

  testO("testing config update callback and null cases", () async {
    bool called = false;
    LogLevelConfigOption logLevel = LogLevelConfigOption(
      titleKey: "logLevel",
      defaultValue: LogLevel.VERBOSE,
      updateCallback: (_) async {
        await Utils.delay(const Duration(milliseconds: 25));
        called = true;
      },
    );
    LogLevel? value = await logLevel.getValue();
    expect(called, false, reason: "no call at first if null and returning default (not saved in db)");
    expect(logLevel.cachedValue(), LogLevel.VERBOSE, reason: "cache returns default value at first");
    expect(value, LogLevel.VERBOSE, reason: "and real get would also return default");
    await logLevel.setValue(LogLevel.INFO);
    expect(called, true, reason: "call after set");
    called = false;
    expect(logLevel.cachedValue(), LogLevel.INFO, reason: "info after set");
    value = await logLevel.getValue();
    expect(value, LogLevel.INFO, reason: "and real also info after set");
    expect(called, false, reason: "no call after get when already has same value");
    logLevel.onlyUpdateCachedValue(null);
    await Utils.delay(const Duration(milliseconds: 50)); // longer wait than the callback takes!
    expect(called, true, reason: "async call after update cached value only with delay");
    logLevel = LogLevelConfigOption(
      titleKey: "logLevel",
      defaultValue: LogLevel.VERBOSE,
      updateCallback: (_) => called = true,
    );
    called = false;
    logLevel.onlyUpdateCachedValue(null);
    expect(called, false, reason: "don't call callback with same value");
    expect(logLevel.cachedValue(), LogLevel.VERBOSE, reason: "cache is now default");
    expect(await logLevel.getValue(), LogLevel.INFO, reason: "and real still returns correct one");

    await logLevel.setValue(null);
    called = false;
    value = await logLevel.getValue();
    expect(called, false, reason: "no getValue call with explicit set to null");
    expect(logLevel.cachedValue(), LogLevel.VERBOSE, reason: "cache again default");
    expect(value, null, reason: "but real is now explicit null");
    called = false;

    await logLevel.setValue(LogLevel.VERBOSE);
    logLevel.onlyUpdateCachedValue(null);
    called = false;
    await logLevel.getValue();
    expect(called, true, reason: "but then getting new value again if cache is null and real data different");
    called = false;
    await logLevel.getValue();
    expect(called, false, reason: "next no call with same value get");
    expect(logLevel.cachedValue(), LogLevel.VERBOSE, reason: "and also correct value at the end");
  });

  final ExampleModel someModel = ExampleModel(
    someData: 10,
    modifiableData: <ExampleModel>[
      ExampleModel(
        someData: 20,
        modifiableData: <ExampleModel>[ExampleModel(someData: null, modifiableData: <ExampleModel>[])],
      ),
    ],
  );
  const String modelJson =
      "{\"JSON_SOME_DATA\":10,\"JSON_MODIFIABLE_DATA\":[{\"JSON_SOME_DATA\":20,\"JSON_MODIFIABLE_DATA\":"
      "[{\"JSON_SOME_DATA\":null,\"JSON_MODIFIABLE_DATA\":[]}]}]}";

  testO("testing database with complex model", () async {
    expect(jsonEncode(someModel), modelJson, reason: "model should be correct json text");
    expect(
      ExampleModel.fromJson(jsonDecode(modelJson) as Map<String, dynamic>),
      someModel,
      reason: "new object from json should be equal",
    );

    final ModelConfigOption<ExampleModel> option = ModelConfigOption<ExampleModel>(
      titleKey: "somethingNew",
      lazyLoaded: false,
      createNewModelInstance: ModelConfigOption.createNewExampleModelInstance,
      createModelBuilder: null,
    );
    expect(await option.getValue(), null, reason: "first null with no value");
    await option.setValue(someModel);
    option.onlyUpdateCachedValue(null);
    expect(await option.getValue(), someModel, reason: "now should be the specific model");
  });
}
