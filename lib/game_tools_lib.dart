import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/enums/event/game_event_group.dart';
import 'package:game_tools_lib/core/enums/event/game_event_priority.dart';
import 'package:game_tools_lib/core/enums/event/game_event_status.dart';
import 'package:game_tools_lib/core/enums/input/input_enums.dart';
import 'package:game_tools_lib/core/enums/log_level.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/logger/custom_logger.dart';
import 'package:game_tools_lib/core/logger/log_color.dart';
import 'package:game_tools_lib/core/logger/log_message.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/data/native/ffi_loader.dart';
import 'package:game_tools_lib/data/native/native_image.dart';
import 'package:game_tools_lib/data/native/native_window.dart' show NativeWindow;
import 'package:game_tools_lib/domain/entities/base/model.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_config.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_event.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_game_manager.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_state.dart';
import 'package:game_tools_lib/domain/game/input/log_input_listener.dart';
import 'package:game_tools_lib/domain/game/states/child_game_state.dart';
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

part 'package:game_tools_lib/domain/game/game_log_watcher.dart';

part 'package:game_tools_lib/domain/game/helper/example/example_log_watcher.dart';

part 'package:game_tools_lib/domain/game/input/base_input_listener.dart';

part 'package:game_tools_lib/domain/game/input/key_input_listener.dart';

part 'package:game_tools_lib/domain/game/input/mouse_input_listener.dart';

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
/// You can manage events here with [addEvent], [getEventByType], [getEventByGroup], [events] but you can also use
/// [GameManager] for that.
///
/// Same for [GameState]'s with [currentState] and [changeState].
final class GameToolsLib extends _GameToolsLibHelper with _GameToolsLibEventLoop {
  /// Sets the [GameToolsConfig.config] at the beginning of the program to your subclass instance [config].
  ///
  /// This should be called by the user. Multiple calls will just return true. Read [GameToolsLib] Documentation!
  ///
  /// This will then block until the game tools lib is initialized and return true as soon as it is running (and
  /// otherwise false if an exception happened). And it will also initialize instances of native window, database,
  /// etc and also set the first state to [GameClosedState].
  ///
  /// [isCalledFromTesting] should only be set to true in tests to use mock classes instead of the default ones (so
  /// nothing is saved to local storage and is instead kept in memory. and other lib paths are used).
  ///
  /// Important: [gameWindows] is required to have a list of a number of objects of your sub classes of game window.
  /// This may not be empty. To use only one default window, use [createDefaultWindowForInit].
  /// If you only know the [GameWindow.name] later, then you can use [GameWindow.rename] at any point!
  ///
  /// You can optionally also use your own logger subclass and override the logging methods for [logger].
  ///
  /// For unknown dynamic errors, this just returns [false], but for known avoidable config errors, this can also
  /// throw a [ConfigException] (for example if you manually set a config instance before calling this, or if
  /// [gameWindows] is empty).
  ///
  /// You have to call [runLoop] afterwards with your ui (or none) to start the internal event loop of this!
  ///
  /// For unsupported platforms this also throws an [UnimplementedError]. Remember to also call [close] at the end of
  /// your program!
  ///
  /// [CF] is your own config subtype and [GM] is your own game manager subtype. For logger you can use a subtype
  /// extending [CustomLogger].[GameState] and [GameEvent] are mostly accessed with general types, so you would have
  /// to always cast them to your sub types.
  ///
  /// [gameLogWatcher] can be your custom subclass of [GameLogWatcher], or the default with your configuration related
  /// to the game log file, look at its documentation for more info! ([GameLogWatcher._init] will be called here and).
  /// In addition to the listeners in the constructor, you can also use [addLogInputListener], or
  /// [removeLogInputListener] later on. There you add your [LogInputListener] subclass objects.
  ///
  /// For the [BaseInputListener]: [MouseInputListener] and [KeyInputListener], look at [GameManager].
  ///
  /// This will also set some flutter error callbacks internally and call [MutableConfig.loadAllConfigurableOptions]!
  static Future<bool> initGameToolsLib<CF extends GameToolsConfigBaseType, GM extends GameManagerBaseType>({
    required CF config,
    required GM gameManager,
    CustomLogger? logger,
    bool isCalledFromTesting = false,
    required List<GameWindow> gameWindows,
    required GameLogWatcher gameLogWatcher,
  }) async {
    if (_GameToolsLibHelper._initialized) {
      Logger.verbose("Game Tools Lib is already initialized and not doing it again!");
      return true; // first check if already called
    }
    GameManager._instance = gameManager; // most important first signal that init was started
    _GameToolsLibHelper._initConfigAndLogger(config, logger, isCalledFromTesting: isCalledFromTesting); // first logger
    Logger.verbose("GameToolsLib.initGameToolsLib... (remember to call GameToolsLib.runLoop afterwards!)");
    if (Platform.isWindows == false) {
      throw UnimplementedError("This platform is currently not supported yet"); // then check platform support
    }
    if (gameWindows.isEmpty) {
      throw const ConfigException(message: "initGameToolsLib called with empty gameWindows list");
    } else {
      _gameWindows = gameWindows; // static instance variables that need to be assigned
    }
    // then init data base
    if (await _GameToolsLibHelper._initDatabase(isCalledFromTesting: isCalledFromTesting) == false) {
      return false;
    }
    // then init native code
    if (await _GameToolsLibHelper._initNativeCode(isCalledFromTesting: isCalledFromTesting) == false) {
      return false;
    }
    _GameToolsLibEventLoop._currentState = GameClosedState(); // also set the current state to closed here
    GameLogWatcher._instance = gameLogWatcher;
    await gameLogWatcher._init(); // also init log watcher
    _GameToolsLibHelper._initialized = true;
    await config.mutable.loadAllConfigurableOptions(); // and lastly load all mutable config options
    Logger.debug(
      "GameToolsLib.initGameToolsLib done with config ${config.runtimeType}, manager "
      "${gameManager.runtimeType}\nand windows $gameWindows",
    );
    return true; // done (onInit and then start loop at the end)
  }

  /// Remember to call [initGameToolsLib] before to initialize this, otherwise a [ConfigException] will be thrown!
  ///
  /// This will call first [GameManager.onStart], then [GameLogWatcher._handleOldLastLines], start the internal event loop
  /// and wait and block until [close] is called (by stopping the lib)!
  ///
  /// [app] can also be null if you don't want any user interface (otherwise it is used with [runApp])
  static Future<void> runLoop({required Widget? app}) async {
    if (_GameToolsLibHelper._initialized == false) {
      throw const ConfigException(message: "initGameToolsLib was not called before runLoop");
    }
    if (app != null) {
      runApp(app);
    } else {
      Logger.verbose("Displaying no app user interface for GameToolsLib (is this intended?)");
    }
    Logger.spam("calling GameManager.onStart and then GameLogWatcher._handleOldLastLines before starting loop");
    await GameManager._instance!.onStart();
    await GameLogWatcher._instance!._handleOldLastLines();
    _GameToolsLibHelper._printRunningLog();
    await _GameToolsLibEventLoop._startLoop(baseConfig.fixed.updatesPerSecond);
  }

  /// Should be called at the end of your program (and otherwise is used for testing to cleanup all data)
  static Future<void> close() async {
    try {
      if (wasInitStarted == false) {
        _gameWindows = null;
        return; // skipping close, because nothing to do
      }
      if (Logger._instance != null) {
        Logger.verbose("Closing Game Tools Lib... ${_GameToolsLibHelper._initialized}");
      }
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
      _gameWindows = null;
      GameManager._instance = null;
      GameLogWatcher._instance = null;
      await Logger.waitForLoggingToBeDone(); // print last logs,
      Logger._instance = StartupLogger(); // reset logger to startup
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
      gameManager: ExampleGameManager(inputListeners: null),
      isCalledFromTesting: isCalledFromTesting,
      gameWindows: GameToolsLib.createDefaultWindowForInit(windowName),
      gameLogWatcher: GameLogWatcher.empty(),
    ); // first init game tools lib with sub config type
    if (init == false) {
      return false;
    }
    final ExampleFixedConfig fixedConfig = GameToolsLib.config<ExampleGameToolsConfig>().fixed; // using sub types
    final ExampleMutableConfig mutableConfig = GameToolsLib.config<ExampleGameToolsConfig>().mutable;
    final GameToolsConfigBaseType baseAccess = GameToolsLib.baseConfig; // using base type
    final ExampleModel? newValue = await mutableConfig.somethingNew.valueNotNull();
    return !fixedConfig.logIntoStorage && (newValue?.someData ?? 1) >= 0 && !baseAccess.fixed.logIntoStorage;
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

  /// Returns an unmodifiable reference to the event queue (list of all current events)
  static UnmodifiableListView<GameEvent> get events =>
      UnmodifiableListView<GameEvent>(_GameToolsLibEventLoop._eventQueue);

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

  /// Adds a new [listener] to the internal list of log input listeners
  static void addLogInputListener(LogInputListener listener) => GameLogWatcher._instance!.addListener(listener);

  /// Removes the [listener] from the internal list of log input listeners
  static void removeLogInputListener(LogInputListener listener) => GameLogWatcher._instance!.removeListener(listener);

  /// Used in [close] to not close this multiple times
  static bool get wasInitStarted => GameManager._instance != null;
}

/// Returns your subclass of type [T] extending [GameManager] from [GameToolsLib.gameManager]
T gm<T extends GameManagerBaseType>() => GameToolsLib.gameManager<T>();
