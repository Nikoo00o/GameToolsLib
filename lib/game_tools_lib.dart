import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/logger/custom_logger.dart';
import 'package:game_tools_lib/core/logger/log_color.dart';
import 'package:game_tools_lib/core/logger/log_level.dart';
import 'package:game_tools_lib/core/logger/log_message.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/data/game/game_window.dart';
import 'package:game_tools_lib/data/native/ffi_loader.dart';
import 'package:game_tools_lib/data/native/native_image.dart';
import 'package:game_tools_lib/data/native/native_window.dart' show NativeWindow;
import 'package:game_tools_lib/domain/entities/model.dart';
import 'package:hive/hive.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:synchronized/synchronized.dart';

part 'package:game_tools_lib/core/config/game_tools_config.dart';

part 'package:game_tools_lib/core/logger/logger.dart';

part 'package:game_tools_lib/data/native/game_tools_lib_platform.dart';

part 'package:game_tools_lib/data/native/hive_database.dart';

part 'package:game_tools_lib/data/native/hive_database_mock.dart';

/// This is the main class of the game tools lib and you should call [initGameToolsLib] at the beginning of your
/// program! The following contains some information on how to use the library:
///
/// For Logging use static methods [Logger.error], [Logger.warn], [Logger.info], [Logger.debug], [Logger.verbose].
/// Config Values should be saved in a subclass of [GameToolsConfig] and can be used with [config].
/// For other file, or data storage, use [HiveDatabase] with [database]
///
/// To Interact with the game window with its bounds and status and also images (see [NativeImage]), look at
/// [GameWindow] with [mainGameWindow]
///
/// To Interact with the input like mouse and keyboard events, look at [InputManager] (only static access)
final class GameToolsLib extends GameToolsLibHelper {
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
  /// You can optionally also override more base classes with your custom sub classes:
  /// [logger],
  ///
  /// For unknown dynamic errors, this just returns [false], but for known avoidable config errors, this can also
  /// throw a [ConfigException] (for example if you manually set a config instance before calling this, or if
  /// [gameWindows] is empty)
  ///
  /// For unsupported platforms this also throws an [UnimplementedError]
  static Future<bool> initGameToolsLib({
    required GameToolsConfig<FixedConfig, MutableConfig> config,
    CustomLogger? logger,
    bool isCalledFromTesting = false,
    required List<GameWindow> gameWindows,
  }) async {
    if (GameToolsLibHelper._initialized) {
      return true; // first check if already called
    }
    if (Platform.isWindows == false) {
      throw UnimplementedError("This platform is currently not supported yet"); // then check platform support
    }
    if (gameWindows.isEmpty) {
      throw ConfigException(message: "initGameToolsLib called with empty gameWindows list");
    } else {
      _gameWindows = gameWindows;
    }
    // then set config and logger
    GameToolsLibHelper._initConfigAndLogger(config, logger, isCalledFromTesting: isCalledFromTesting);
    // then init data base
    if (await GameToolsLibHelper._initDatabase(isCalledFromTesting: isCalledFromTesting) == false) {
      return false;
    }
    // then init native code
    if (await GameToolsLibHelper._initNativeCode(isCalledFromTesting: isCalledFromTesting) == false) {
      return false;
    }

    return GameToolsLibHelper._initialized = true; // done
  }

  /// Should only be used for testing, because it resets all static references and stops the GameToolsLib
  static Future<void> close() async {
    GameToolsConfig._instance = null;
    if (HiveDatabase._instance != null) {
      await database.closeHiveDatabases();
      HiveDatabase._instance = null;
    } else {
      // logger might not be initialized yet. also dont clean up logger itself!
      await StartupLogger().log("HiveDatabase was null while closing GameToolsLib", LogLevel.WARN, null, null);
    }
    NativeWindow.clearNativeWindowInstance();
    await Logger.waitForLoggingToBeDone(); // print last logs
    GameToolsLibHelper._initialized = false; // cleanup done
  }

  /// Will be called automatically and Registers this class as the default instance of [GameToolsLibPlatform].
  /// Otherwise only prints an info after a while that the user should initialize the library if he did not do it.
  /// See [GameToolsLibHelper._showStartupWarning]
  static void registerWith() {
    GameToolsLibPlatform.instance = GameToolsLib._();
    unawaited(GameToolsLibHelper._showStartupWarning());
  }

  GameToolsLib._();

  /// Creates one [GameWindow] object with [windowName] to use in [initGameToolsLib]
  static List<GameWindow> createDefaultWindowForInit(String windowName) => <GameWindow>[GameWindow(name: windowName)];

  /// internal list
  static List<GameWindow>? _gameWindows;

  /// Reference to the config after [initGameToolsLib] was successful
  static T config<T extends GameToolsConfig<FixedConfig, MutableConfig>>() => GameToolsConfig.config<T>();

  /// The [config] as base [BaseGameToolsConfig]
  static BaseGameToolsConfig get baseConfig => config<BaseGameToolsConfig>();

  /// the database for storage
  static HiveDatabase get database => HiveDatabase.database;

  /// The first and main game window to use. Only able to access after [initGameToolsLib]
  static GameWindow get mainGameWindow => _gameWindows!.first;

  /// Returns the list of game windows as non modifiable list. Only able to access after [initGameToolsLib].
  /// Of course the individual game window objects can be modified!
  static UnmodifiableListView<GameWindow> get gameWindows => UnmodifiableListView<GameWindow>(_gameWindows!);
}
