import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/enums/game_event_group.dart';
import 'package:game_tools_lib/core/enums/game_event_priority.dart';
import 'package:game_tools_lib/core/enums/game_event_status.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/logger/custom_logger.dart';
import 'package:game_tools_lib/core/logger/log_color.dart';
import 'package:game_tools_lib/core/logger/log_level.dart';
import 'package:game_tools_lib/core/logger/log_message.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/data/native/ffi_loader.dart';
import 'package:game_tools_lib/data/native/native_image.dart';
import 'package:game_tools_lib/data/native/native_window.dart' show NativeWindow;
import 'package:game_tools_lib/domain/entities/model.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/domain/game/states/game_closed_state.dart';
import 'package:hive/hive.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:synchronized/synchronized.dart';

part 'package:game_tools_lib/core/config/game_tools_config.dart';

part 'package:game_tools_lib/core/logger/logger.dart';

part 'package:game_tools_lib/data/helper/game_tools_lib_platform.dart';

part 'package:game_tools_lib/data/native/hive_database.dart';

part 'package:game_tools_lib/data/native/hive_database_mock.dart';

part 'package:game_tools_lib/domain/game/game_manager.dart';

part 'package:game_tools_lib/data/helper/game_tools_lib_event_loop.dart';

part 'package:game_tools_lib/domain/game/events/game_event.dart';

part 'package:game_tools_lib/domain/game/states/game_state.dart';

/// This is the main class of the game tools lib and you should call [initGameToolsLib] at the beginning of your
/// program, then [runLoop] to start the internal update event loop and [close] at the end of it!
/// The following contains some information on how to use the library:
///
/// Your main interaction point will be the [GameManager] accessed in [gameManager], or [gm] with events to listen to
/// and getters for all instances of the following.
///
/// To Interact with the input like mouse and keyboard events, look at [InputManager] (only static access).
///
/// For Logging use static methods [Logger.error], [Logger.warn], [Logger.info], [Logger.debug], [Logger.verbose].
/// For other file, or data storage, use [HiveDatabase] with [database].
///
/// Config Values should be saved in a subclass of [GameToolsConfig] and can be used with the correct type in [config].
/// But you can also access this in [gameManager].
///
/// To Interact with the game window with its bounds and status and also images (see [NativeImage]), look at
/// [GameWindow] with [mainGameWindow], or [gameWindows] (but you can also access this in [gameManager]).
///
/// You can manage events here with [addEvent], [getEventByType], [getEventByGroup] but also use [GameManager] for that.
/// Same for [GameState]'s with [currentState] and [changeState].
///
final class GameToolsLib extends _GameToolsLibHelper with _GameToolsLibEventLoop {
  /// Sets the [GameToolsConfig.config] at the beginning of the program to your subclass instance [config].
  ///
  /// This should be called by the user. Multiple calls will just return true. Read [GameToolsLib] Documentation!
  ///
  /// This will then block until the game tools lib is initialized and return true as soon as it is running (and
  /// otherwise false if an exception happened)
  ///
  /// [isCalledFromTesting] should only be set to true in tests to use mock classes instead of the default ones (so
  /// nothing is saved to local storage and is instead kept in memory. and other lib paths are used)
  ///
  /// Important: [gameWindows] is required to have a list of a number of objects of your sub classes of game window.
  /// This may not be empty. To use only one default window, use [createDefaultWindowForInit].
  /// If you only know the [GameWindow.name] later, then you can use [GameWindow.rename] at any point!
  ///
  /// You can optionally also use your own logger subclass and override the logging methods for [logger],
  ///
  /// For unknown dynamic errors, this just returns [false], but for known avoidable config errors, this can also
  /// throw a [ConfigException] (for example if you manually set a config instance before calling this, or if
  /// [gameWindows] is empty)
  ///
  /// You have to call [runLoop] afterwards with your ui (or none) to start the internal event loop of this!
  ///
  /// For unsupported platforms this also throws an [UnimplementedError]. Remember to also call [close] at the end of
  /// your program!
  static Future<bool> initGameToolsLib<CF extends GameToolsConfigBaseType, GM extends GameManagerBaseType>({
    required CF config,
    required GM gameManager,
    CustomLogger? logger,
    bool isCalledFromTesting = false,
    required List<GameWindow> gameWindows,
  }) async {
    if (_GameToolsLibHelper._initialized) {
      return true; // first check if already called
    }
    if (Platform.isWindows == false) {
      throw UnimplementedError("This platform is currently not supported yet"); // then check platform support
    }
    if (gameWindows.isEmpty) {
      throw ConfigException(message: "initGameToolsLib called with empty gameWindows list");
    } else {
      _gameWindows = gameWindows; // static instance variables that need to be assigned
      GameManager._instance = gameManager;
    }
    // then set config and logger
    _GameToolsLibHelper._initConfigAndLogger(config, logger, isCalledFromTesting: isCalledFromTesting);
    // then init data base
    if (await _GameToolsLibHelper._initDatabase(isCalledFromTesting: isCalledFromTesting) == false) {
      return false;
    }
    // then init native code
    if (await _GameToolsLibHelper._initNativeCode(isCalledFromTesting: isCalledFromTesting) == false) {
      return false;
    }
    _GameToolsLibHelper._initialized = true;
    return true; // done (onInit and then start loop at the end)
  }

  /// Remember to call [initGameToolsLib] before to initialize this, otherwise a [ConfigException] will be thrown!
  ///
  /// This will set the first state [GameClosedState], call [GameManager.onStart], start the internal event loop and
  /// wait and block until [close] is called (by stopping the lib)!
  ///
  /// [app] can also be null if you don't want any user interface (otherwise it is used with [runApp])
  static Future<void> runLoop({required Widget? app}) async {
    if (_GameToolsLibHelper._initialized == false) {
      throw ConfigException(message: "initGameToolsLib was not called before runLoop");
    }
    _GameToolsLibEventLoop._currentState = GameClosedState();
    if (app != null) {
      runApp(app);
    }
    await GameManager._instance!.onStart();
    await _GameToolsLibEventLoop._startLoop(baseConfig.fixed.updatesPerSecond);
  }

  /// Should be called at the end of your program (and otherwise is used for testing to cleanup all data)
  static Future<void> close() async {
    try {
      await _GameToolsLibEventLoop._stopLoop(); // wait for loop to stop
      final GameState gameClosed = GameClosedState();
      await _GameToolsLibEventLoop._currentState?.onStop(gameClosed);
      _GameToolsLibEventLoop._currentState = gameClosed;
      await GameManager._instance?.onStop();
      if (HiveDatabase._instance != null) {
        await database.closeHiveDatabases();
        HiveDatabase._instance = null;
      } else {
        // logger might not be initialized yet. also dont clean up logger itself!
        await StartupLogger().log("HiveDatabase was null while closing GameToolsLib", LogLevel.WARN, null, null);
      }
      NativeWindow.clearNativeWindowInstance();
      GameToolsConfig._instance = null;
      GameManager._instance = null;
      await Logger.waitForLoggingToBeDone(); // print last logs
      _GameToolsLibHelper._initialized = false; // cleanup done
    } catch (e, s) {
      await StartupLogger().log("Error closing Game Tools Lib", LogLevel.ERROR, e, s);
    }
  }

  /// Will be called automatically and Registers this class as the default instance of [GameToolsLibPlatform].
  /// Otherwise only prints an info after a while that the user should initialize the library if he did not do it.
  /// See [_GameToolsLibHelper._showStartupWarning]
  static void registerWith() {
    GameToolsLibPlatform.instance = GameToolsLib._();
    unawaited(_GameToolsLibHelper._showStartupWarning());
  }

  @visibleForTesting
  /// Only used in testing to reset flags
  static void testResetInitialized() => _GameToolsLibHelper._initialized = false;

  /// Initializes the library with the [ExampleGameToolsConfig] and also uses it similar to a default call to
  /// [GameToolsLib.initGameToolsLib] with a few changes. Optional [windowName] can also be set.
  /// [isCalledFromTesting] should only be set to true in tests to use mock classes instead of the default ones (so
  /// nothing is saved to local storage and is instead kept in memory. and other lib paths are used).
  ///
  /// Important: this is only an example for testing and should not be used in production code!
  static Future<bool> useExampleConfig({bool isCalledFromTesting = false, String windowName = "Not_Found"}) async {
    final bool init = await GameToolsLib.initGameToolsLib(
      config: ExampleGameToolsConfig(),
      gameManager: ExampleGameManager(),
      isCalledFromTesting: isCalledFromTesting,
      gameWindows: GameToolsLib.createDefaultWindowForInit(windowName),
    ); // first init game tools lib with sub config type
    if (init == false) {
      return false;
    }
    final ExampleFixedConfig fixedConfig = GameToolsLib.config<ExampleGameToolsConfig>().fixed; // using sub types
    final ExampleMutableConfig mutableConfig = GameToolsLib.config<ExampleGameToolsConfig>().mutable;
    final GameToolsConfigBaseType baseAccess = GameToolsLib.baseConfig; // using base type
    final ExampleModel newValue = await mutableConfig.somethingNew.valueNotNull();
    return !fixedConfig.logIntoStorage && newValue.someData == 5 && !baseAccess.fixed.logIntoStorage;
  }

  GameToolsLib._();

  /// Returns your subclass of type [T] extending [GameManager]. You can also use the global method [gm] instead.
  static T gameManager<T extends GameManagerBaseType>() => GameManager.gameManager<T>();

  /// Creates one [GameWindow] object with [windowName] to use in [initGameToolsLib]
  static List<GameWindow> createDefaultWindowForInit(String windowName) => <GameWindow>[GameWindow(name: windowName)];

  /// Returns the list of game windows as non modifiable list. Only able to access after [initGameToolsLib].
  /// Of course the individual game window objects can be modified!
  static UnmodifiableListView<GameWindow> get gameWindows => UnmodifiableListView<GameWindow>(_gameWindows!);

  /// internal list
  static List<GameWindow>? _gameWindows;

  /// The first and main game window to use. Only able to access after [initGameToolsLib]
  static GameWindow get mainGameWindow => _gameWindows!.first;

  /// Reference to the config after [initGameToolsLib] was successful
  static T config<T extends GameToolsConfigBaseType>() => GameToolsConfig.config<T>();

  /// The [config] as base [GameToolsConfigBaseType]
  static GameToolsConfigBaseType get baseConfig => config<GameToolsConfigBaseType>();

  /// the database for storage
  static HiveDatabase get database => HiveDatabase.database;

  /// Adds any event to the internal event queue if the same event is not already in it. See [GameEvent] for
  /// documentation! To remove/delete an event, use [GameEvent.remove]!
  static void addEvent(GameEvent event) => _GameToolsLibEventLoop._addEventInternal(event);

  /// Returns a list of all currently active [GameEvent]s that match the [Type]
  static List<GameEvent> getEventByType<Type>() {
    final List<GameEvent> events = <GameEvent>[];
    _GameToolsLibEventLoop._runForAllEvents((GameEvent event) {
      if (event is Type) {
        events.add(event);
      }
    });
    return events;
  }

  /// Returns a list of all currently active [GameEvent]s that are in the group [group].
  static List<GameEvent> getEventByGroup(GameEventGroup group) {
    final List<GameEvent> events = <GameEvent>[];
    _GameToolsLibEventLoop._runForAllEvents((GameEvent event) {
      if (event.isInGroup(group)) {
        events.add(event);
      }
    });
    return events;
  }

  /// Replaces the [currentState] with [newState] if its not already the same object, but first calls [GameState.onStop]
  /// on the old state and at the end also calls [GameState.onStart] on the new state and [GameManager.onStateChange]
  /// and [GameEvent.onStateChange]!
  static Future<void> changeState(GameState newState) async {
    final GameState? oldState = _GameToolsLibEventLoop._currentState;
    if (oldState == newState) {
      Logger.warn("Could not change to $newState, because it was already the current state");
      return;
    }
    Logger.verbose("Changing state from $oldState to $newState");
    await oldState?.onStop(newState);
    _GameToolsLibEventLoop._currentState = newState;
    await newState.onStart(oldState!);
    await GameManager._instance?.onStateChange(oldState, newState);
    await _GameToolsLibEventLoop._runForAllEventsAsync(
      (GameEvent event) async => event.onStateChange(oldState, newState),
    );
  }

  /// Returns the current active state
  static GameState get currentState => _GameToolsLibEventLoop._currentState!;
}

/// Returns your subclass of type [T] extending [GameManager] from [GameToolsLib.gameManager]
T gm<T extends GameManagerBaseType>() => GameToolsLib.gameManager<T>();
