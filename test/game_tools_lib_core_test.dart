import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/logger/log_level.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/data/game/game_window.dart';
import 'package:game_tools_lib/domain/entities/model.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

void main() {
  setUp(() async {
    // default init call for testing
    final bool init = await _initGameToolsLib();
    await Utils.delay(Duration(milliseconds: 5)); // get last log out of test
    if (init == false) {
      throw TestException(message: "default test init game tools lib failed");
    }
  });

  tearDown(() async {
    await GameToolsLib.close(); // cleanup static references
    await Utils.delay(Duration(milliseconds: 5)); // get last log out of test
  });

  group("GameToolsLib Core Tests: ", () {
    group("Initialization Tests: ", _testInit);
  });
}

Future<bool> _initGameToolsLib() async {
  final bool result = await GameToolsLib.initGameToolsLib(
    config: BaseGameToolsConfig(),
    isCalledFromTesting: true,
    gameWindows: GameToolsLib.createDefaultWindowForInit("Not_Found"),
  );
  return result;
}

void _testInit() {
  test("initialize game tools lib with base config", () async {
    await GameToolsLib.close();
    final bool success = await _initGameToolsLib();
    expect(success, true);
    expect(GameToolsLib.baseConfig.fixed.logIntoStorage, true, reason: "log into storage is true");
    expect(await GameToolsLib.baseConfig.mutable.logLevel.getValue(), LogLevel.SPAM, reason: "log level is spam");
    expect(GameToolsLib.database.basePath, HiveDatabaseMock.FLUTTER_TEST_PATH, reason: "database path is testing");
  });
  test("initialize game tools lib with example config", () async {
    await GameToolsLib.close();
    final bool success = await GameToolsLibHelper.useExampleConfig(isCalledFromTesting: true);
    expect(success, true);
    expect(GameToolsLib.baseConfig.fixed.logIntoStorage, false, reason: "log into storage is false");
    expect(await GameToolsLib.baseConfig.mutable.logLevel.getValue(), LogLevel.VERBOSE, reason: "log level is verbose");
  });
  test("simulating database error in init should return false", () async {
    await GameToolsLib.close();
    HiveDatabaseMock.throwExceptionInInit = true;
    expect(await _initGameToolsLib(), false);
    HiveDatabaseMock.throwExceptionInInit = false;
  });
  test("user initializing game tools lib twice should just return true", () async {
    final bool success = await _initGameToolsLib();
    expect(success, true);
  });
  test("user initializing game tools lib while there is already a config", () async {
    GameToolsLibHelper.testResetInitialized();
    expect(() async {
      await _initGameToolsLib();
    }, throwsA(predicate((Object e) => e is ConfigException)));
  });
  test("user initializing game tools lib with empty window list should throw an exception", () async {
    await GameToolsLib.close();
    expect(() async {
      await GameToolsLib.initGameToolsLib(
        config: BaseGameToolsConfig(),
        isCalledFromTesting: true,
        gameWindows: <GameWindow>[],
      );
    }, throwsA(predicate((Object e) => e is ConfigException)));
  });
  test("initialize game tools lib with multiple game windows should still work", () async {
    await GameToolsLib.close();
    final bool success = await GameToolsLib.initGameToolsLib(
      config: BaseGameToolsConfig(),
      isCalledFromTesting: true,
      gameWindows: <GameWindow>[
        GameWindow(name: "first"),
        GameWindow(name: "second"),
      ],
    );
    expect(success, true);
    expect(GameToolsLib.mainGameWindow.name, "first", reason: "first name should be correct");
    expect(GameToolsLib.gameWindows.elementAt(1).name, "second", reason: "second name should be correct");
  });
  test("testing database cache", () async {
    LogLevelConfigOption logLevel = LogLevelConfigOption(key: "logLevel", defaultValue: LogLevel.VERBOSE);
    expect(logLevel.cachedValue(), LogLevel.VERBOSE, reason: "cache is initially set to default");
    await logLevel.setValue(LogLevel.INFO);
    expect(logLevel.cachedValue(), LogLevel.INFO, reason: "cache is updated after set");
    logLevel.onlyUpdateCachedValue(null);
    await logLevel.getValue();
    expect(logLevel.cachedValue(), LogLevel.INFO, reason: "cache is updated after get");
    await logLevel.deleteValue();
    expect(logLevel.cachedValue(), LogLevel.VERBOSE, reason: "after delete cache is back to default");
    logLevel = LogLevelConfigOption(key: "logLevel");
    expect(logLevel.cachedValue(), null, reason: "with no default, cache is initially null");
    logLevel = LogLevelConfigOption(key: "logLevel", defaultValue: LogLevel.DEBUG);
    await logLevel.setValue(null);
    expect(logLevel.cachedValue(), LogLevel.DEBUG, reason: "set to null not best behaviour still return default");
    expect(await logLevel.getValue(), null, reason: "but normal get correctly returns null");
  });

  test("testing database get/set", () async {
    LogLevelConfigOption logLevel = LogLevelConfigOption(key: "logLevel", defaultValue: LogLevel.VERBOSE);
    expect(await logLevel.getValue(), LogLevel.VERBOSE, reason: "return default with null");
    await logLevel.setValue(LogLevel.INFO);
    expect(await logLevel.getValue(), LogLevel.INFO, reason: "return updated after set");
    logLevel.onlyUpdateCachedValue(null);
    expect(await logLevel.getValue(), LogLevel.INFO, reason: "still return updated after clearing cache");
    await logLevel.deleteValue();
    expect(await logLevel.getValue(), LogLevel.VERBOSE, reason: "return default after delete");
    await logLevel.setValue(null);
    expect(await logLevel.getValue(), null, reason: "return null after explicit set to null");
    logLevel = LogLevelConfigOption(key: "logLevel");
    expect(await logLevel.getValue(), null, reason: "return null with no default");
    await logLevel.setValue(LogLevel.INFO);
    await logLevel.deleteValue();
    expect(await logLevel.getValue(), null, reason: "still return null after set and delete");
  });

  test("testing config update callback", () async {
    bool called = false;
    LogLevelConfigOption logLevel = LogLevelConfigOption(
      key: "logLevel",
      defaultValue: LogLevel.VERBOSE,
      updateCallback: (_) async {
        await Utils.delay(Duration(milliseconds: 25));
        called = true;
      },
    );
    await logLevel.getValue();
    expect(called, false, reason: "no call on returning default");
    await logLevel.setValue(LogLevel.INFO);
    expect(called, true, reason: "call after set");
    called = false;
    await logLevel.getValue();
    expect(called, false, reason: "no call after get");
    logLevel.onlyUpdateCachedValue(null);
    await Utils.delay(Duration(milliseconds: 50)); // longer wait than the callback takes!
    expect(called, true, reason: "async call after update cached value only with delay");
    logLevel = LogLevelConfigOption(
      key: "logLevel",
      defaultValue: LogLevel.VERBOSE,
      updateCallback: (_) => called = true,
    );
    called = false;
    logLevel.onlyUpdateCachedValue(null);
    expect(called, true, reason: "non async callback called directly after update cache");
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
  final String modelJson =
      "{\"JSON_SOME_DATA\":10,\"JSON_MODIFIABLE_DATA\":[{\"JSON_SOME_DATA\":20,\"JSON_MODIFIABLE_DATA\":"
      "[{\"JSON_SOME_DATA\":null,\"JSON_MODIFIABLE_DATA\":[]}]}]}";

  test("testing database with complex model", () async {
    expect(jsonEncode(someModel), modelJson, reason: "model should be correct json text");
    expect(
      ExampleModel.fromJson(jsonDecode(modelJson) as Map<String, dynamic>),
      someModel,
      reason: "new object from json should be equal",
    );

    final ModelConfigOption<ExampleModel> option = ModelConfigOption<ExampleModel>(
      key: "somethingNew",
      lazyLoaded: false,
      createNewModelInstance: ModelConfigOption.createNewExampleModelInstance,
    );
    expect(await option.getValue(), null, reason: "first null with no value");
    await option.setValue(someModel);
    option.onlyUpdateCachedValue(null);
    expect(await option.getValue(), someModel, reason: "now should be the specific model");
  });
}
