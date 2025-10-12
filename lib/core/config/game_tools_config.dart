part of 'package:game_tools_lib/game_tools_lib.dart';

/// Base class with getters for the [fixed] and [mutable] parts of the config. These should be overridden in sub
/// class to return new objects which store config variables that may change either at compile time, or run time.
///
/// Constant config values that are only unique per application and won't change can be stored inside of this (like
/// [appTitle]).
///
/// Sub classes should also use extend with the custom types for [FixedConfigType] and [MutableConfigType], but
/// sub classes of this should not have any dynamic member variables and the getters should always return const objects!
/// For an example look at [ExampleGameToolsConfig]
///
/// Remember to call [GameToolsLib.initGameToolsLib] first with your config sub class!
base class GameToolsConfig<FixedConfigType extends FixedConfig, MutableConfigType extends MutableConfig> {
  /// Returns the fixed part of this config where all values are stored inside of the dart classes
  final FixedConfigType fixed;

  /// Returns the mutable part of this config where all values are stored inside of a local file
  final MutableConfigType mutable;

  const GameToolsConfig({required this.fixed, required this.mutable});

  /// Absolute path to the folder from the working directory where all resource/assets/etc files for this are stored!
  /// When running from debugger in android studio, or from tests, this will point to "project_dir/data" and
  /// otherwise for a running app this points to "exe_dir/data"
  static final String resourceFolderPath = FileUtils.getLocalFilePath("data");

  /// You should override this to display the name of your tool in your app!
  String get appTitle => "GameToolsLib";

  /// Absolute path to the stored log files
  String get logFolder => FileUtils.combinePath(<String>[resourceFolderPath, "logs"]);

  /// Absolute path to the stored database files (for mutable config values) and other database files
  String get databaseFolder => FileUtils.combinePath(<String>[resourceFolderPath, "database"]);

  /// The name of the folder containing all locales in the assets directory which is the following:
  /// "data/flutter_assets/assets" for your application assets and "data/flutter_assets/packages/game_tools_lib/assets"
  /// for the library assets!
  ///
  /// Only the translation file "en.json" and "de.json" are bundled with this library and will be loaded before your
  /// "en.json" and "de.json" files, but your values may replace the old ones! (also locale files from other packages
  /// plugins will be loaded before your final application). Also see [FixedConfig.supportedLocales].
  ///
  /// Uses an internal cached [_localeFolders]!
  List<String> get localeFolders => _localeFolders;

  static final List<String> _localeFolders = FileUtils.getAssetFoldersFor("locales");

  static GameToolsConfigBaseType? _instance;

  /// Returns the the [GameToolsConfig._instance] if already set, otherwise throws a [ConfigException]
  static T config<T extends GameToolsConfigBaseType>() {
    if (_instance == null) {
      throw const ConfigException(message: "GameToolsConfig was not initialized yet!");
    } else if (_instance is T) {
      return _instance as T;
    } else {
      throw ConfigException(message: "Wrong type $T for $_instance");
    }
  }

  /// The [config] as base [GameToolsConfigBaseType]
  static GameToolsConfigBaseType get baseConfig => config<GameToolsConfigBaseType>();
}

/// Base Type of [GameToolsConfig] with [FixedConfig] and [MutableConfig]
typedef GameToolsConfigBaseType = GameToolsConfig<FixedConfig, MutableConfig>;
