part of 'package:game_tools_lib/game_tools_lib.dart';

/// Helper Methods For GameToolsLib
sealed class GameToolsLibHelper extends GameToolsLibPlatform {
  /// controls the status
  static bool _initialized = false;

  /// Used in [GameToolsLib.initGameToolsLib] at the start to init the config
  static void _initConfigAndLogger(
    GameToolsConfig<FixedConfig, MutableConfig> config,
    CustomLogger? logger, {
    required bool isCalledFromTesting,
  }) {
    if (GameToolsConfig._instance != null) {
      throw ConfigException(message: "Cant set $config, instance was already set to ${GameToolsConfig._instance}");
    }
    GameToolsConfig._instance = config;
    Logger._initLogger(logger ?? CustomLogger());
    if (isCalledFromTesting) {
      Logger._instance!._isTesting = true;
      Logger.debug("Setting Logger To Testing mode so it does not write to storage");
    }
  }

  /// This is called from [GameToolsLib.initGameToolsLib] after setting the important base classes to init local storage
  static Future<bool> _initDatabase({required bool isCalledFromTesting}) async {
    try {
      if (isCalledFromTesting) {
        HiveDatabase._instance = HiveDatabaseMock._();
      } else {
        HiveDatabase._instance = HiveDatabase._();
      }
      final HiveDatabase database = GameToolsLib.database;
      await database._init();
      await GameToolsLib.baseConfig.mutable.logLevel.getValue(); // important: cache data once so that logger gets
      // correct log level!
      Logger.verbose(
        "Initialized GameToolsLib DataBase from path ${database.basePath}, Logger ${Logger._instance.runtimeType} "
        "with LogLevel ${Logger.currentLogLevel} and config ${GameToolsConfig.config().runtimeType}",
      );
      return true;
    } catch (e, s) {
      Logger.error("Error initializing Database of GameToolsLib", e, s);
      return false;
    }
  }

  static Future<bool> _initNativeCode({required bool isCalledFromTesting}) async {
    try {
      final bool unChanged = await NativeWindow.initNativeWindow(); // first init native window
      if (unChanged == false) {
        Logger.error("Error, copy new Native C/C++ library file to ${FileUtils.absolutePath(FFILoader.apiPath)}");
        return false;
      }
      for (final GameWindow gameWindow in GameToolsLib.gameWindows) {
        // now init all game windows by calling init on them once
        unawaited(gameWindow.rename(gameWindow.name)); // dont need to await delay in first init
      }
      Logger.verbose("Native C/C++ Part of GameToolsLib loaded from ${FileUtils.absolutePath(FFILoader.apiPath)}");

      // next opencv
      const String opencvVar = "DARTCV_LIB_PATH";
      final String openCVPath = Platform.environment[opencvVar] ?? "";
      if (isCalledFromTesting) {
        // special case for testing
        String exceptionText = ""; // special case for testing to find opencv lib
        if (openCVPath.isEmpty) {
          exceptionText = "Environment var not set";
        } else if (FileUtils.fileExists(openCVPath) == false) {
          exceptionText = "OpenCV Lib $openCVPath does not exist";
        }
        if (exceptionText.isNotEmpty) {
          final String msg =
              "$exceptionText. You have to set the $opencvVar environment variable to a place where you put "
              "the OpenCV library, for example "
              "${FileUtils.absolutePathP(<String>[FileUtils.parentPath(FFILoader.apiPath), _openCvName])} "
              "and copy it the same way as you did with the ${FileUtils.getFileName(FFILoader.apiPath)}\n"
              "But you also have to copy all lib dependencies required by OpenCV there ($_openCvDeps)";
          final TestException exception = TestException(message: msg);
          Logger.error("Init Native Code Error:", exception, StackTrace.current);
          throw exception;
        } else {
          Logger.debug("Loading OpenCV for testing from $openCVPath");
          final Directory old = Directory.current;
          Directory.current = FileUtils.getDirectoryForPath(openCVPath);
          try {
            // first usage of opencv to load lib dependencies
            Logger.verbose("OpenCV Version: ${NativeWindow.openCvVersion}");
          } catch (_) {
            final String msg = "The OpenCV lib dependencies are missing from ${Directory.current.path}: $_openCvDeps";
            final TestException exception = TestException(message: msg);
            Logger.error("Init Native Code Error:", exception, StackTrace.current);
            throw exception; // throw more precise exception here
          } finally {
            Directory.current = old; // always only reset directory here
          }
        }
      } else {
        // not testing
        if (openCVPath.isNotEmpty) {
          if (FileUtils.fileExists(openCVPath) == false) {
            Logger.error(
              "You have the OpenCV environment variable $opencvVar set to $openCVPath But no $_openCvName "
              "lib file exists there",
            );
            return false;
          } else {
            Logger.verbose("Loading OpenCV from environment variable path $openCVPath");
          }
        } else {
          Logger.verbose("Loading OpenCV from $_openCvName");
        }
        // first usage of opencv to load lib dependencies
        Logger.verbose("OpenCV Version: ${NativeWindow.openCvVersion}");
      }
      return true;
    } on TestException {
      rethrow; // don't handle test exception
    } catch (e, s) {
      Logger.error("Error initializing Native Code of GameToolsLib", e, s);
      return false;
    }
  }

  /// native lib dependencies of opencv
  static String get _openCvDeps =>
      "avcodec-61, avdevice-61, avfilter-10, avformat-61, avutil-59, swresample-5, swscale-8";

  /// platform specific name of the opencv native lib
  static String get _openCvName => switch (Platform.operatingSystem) {
    "windows" => "dartcv.dll",
    "linux" || "android" || "fuchsia" => "libdartcv.so",
    "macos" => "libdartcv.dylib",
    _ => throw UnsupportedError("Platform ${Platform.operatingSystem} not supported"),
  };

  /// shows a warning after a delay of 30 seconds if the library was not initialized by then
  static Future<void> _showStartupWarning() async {
    await Utils.delay(const Duration(seconds: 30));
    if (_initialized == false) {
      await StartupLogger().log(
        "GameToolsLib is not initialized! Remember to call GameToolsLib.initGameToolsLib at the start of your program",
        LogLevel.WARN,
        null,
        null,
      );
    }
  }

  @visibleForTesting
  static void testResetInitialized() => _initialized = false;

  /// Initializes the library with the [ExampleGameToolsConfig] and also uses it similar to a default call to
  /// [GameToolsLib.initGameToolsLib] with a few changes. Optional [windowName] can also be set.
  /// [isCalledFromTesting] should only be set to true in tests to use mock classes instead of the default ones (so
  /// nothing is saved to local storage and is instead kept in memory. and other lib paths are used).
  ///
  /// Important: this is only an example for testing and should not be used in production code!
  static Future<bool> useExampleConfig({bool isCalledFromTesting = false, String windowName = "Not_Found"}) async {
    final bool init = await GameToolsLib.initGameToolsLib(
      config: ExampleGameToolsConfig(),
      isCalledFromTesting: isCalledFromTesting,
      gameWindows: GameToolsLib.createDefaultWindowForInit(windowName),
    ); // first init game tools lib with sub config type
    if (init == false) {
      return false;
    }
    final ExampleFixedConfig fixedConfig = GameToolsLib.config<ExampleGameToolsConfig>().fixed; // using sub types
    final ExampleMutableConfig mutableConfig = GameToolsLib.config<ExampleGameToolsConfig>().mutable;
    final BaseGameToolsConfig baseAccess = GameToolsLib.baseConfig; // using base type
    final ExampleModel newValue = await mutableConfig.somethingNew.valueNotNull();
    return !fixedConfig.logIntoStorage && newValue.someData == 5 && !baseAccess.fixed.logIntoStorage;
  }
}

/// Currently no platform specific code with method channel, so everything is done in pure dart with ffi and native
/// c/c++ code!
sealed class GameToolsLibPlatform extends PlatformInterface {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('game_tools_lib');

  /// Constructs a GameToolsLibPlatform with some instance token
  GameToolsLibPlatform() : super(token: _token);

  static final Object _token = Object();

  static GameToolsLibPlatform _instance = GameToolsLib._();

  /// The default instance of [GameToolsLibPlatform] to use.
  static GameToolsLibPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own platform-specific class that extends
  /// [GameToolsLibPlatform] when they register themselves.
  static set instance(GameToolsLibPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// unused method for now
  Future<String?> getPlatformVersion() async {
    // this would be the way to invoke method channel platform specific code
    return methodChannel.invokeMethod<String>('getPlatformVersion');
  }
}
