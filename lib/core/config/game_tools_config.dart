part of 'package:game_tools_lib/game_tools_lib.dart';

/// Base class with getters for the [fixed] and [mutable] parts of the config. These should be overridden in sub
/// class to return new objects which store config variables that may change either at compile time, or run time.
///
/// Constant config values that are only unique per application and won't change can be stored inside of this (like
/// [appTitle]). For example this also contains many paths where different files are stored like the [logFolder].
/// Here the [dynamicDataFolder] is used for user modifiable data generated during runtime and the [staticAssetFolders]
/// is used for static assets shipped with the application during compile time (from source code)!
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
  /// When running from debugger in android studio, or from tests, this will point to "project_dir/data" (of course
  /// without the assets being in there) and  otherwise for a running app this points to "exe_dir/data".
  /// This folder path should only be used for dynamic files you save yourself during runtime and not the static
  /// asset files! For example used in [logFolder]. Static asset files should use [staticAssetFolders] instead!
  static final String resourceFolderPath = FileUtils.getLocalFilePath("data");

  /// You should override this to display the name of your tool in your app!
  String get appTitle => "GameToolsLib";

  /// Absolute path to the stored log files
  String get logFolder => FileUtils.combinePath(<String>[resourceFolderPath, "logs"]);

  /// Absolute path to the stored database files (for mutable config values) and other database files
  String get databaseFolder => FileUtils.combinePath(<String>[resourceFolderPath, "database"]);

  /// Absolute path to the dynamic data folder where there are sub folders for different json files that the user may
  /// edit like for example [OverlayElement], or directly json modifiable mutable config values!
  ///
  /// The subfolders and files will only be created at runtime!
  String get dynamicDataFolder => FileUtils.combinePath(<String>[resourceFolderPath, "dynamic_data"]);

  /// Caches and returns all possible static asset folders for the current app and all packages, so the local paths
  /// relative to execution: "data/flutter_assets/assets" and multiple "data/flutter_assets/packages/PACKAGE_NAME/assets"
  /// if this was compiled into a program!
  ///
  /// The first entry of the list will always be the asset folder of the game_tools_lib package and the last entry
  /// will always be the asset folder of your application!
  ///
  /// If this is run for debugging from the IDE, or is run from tests, the last part of the application will point to
  /// the project asset folder instead and the other package paths may be in the build directory!
  ///
  /// Of course all returned paths will always be absolute file paths (and only if the "assets" folder exists!)! This
  /// is mostly used in [GTAsset]'s!
  ///
  /// Important: your packages pubspec.yaml must include under its "assets:" section: first "assets/" in general and
  /// then the sub folders "assets/locales/" used for [LocaleAsset] and "assets/images/" used for [ImageAsset], but
  /// also any custom folders used for [JsonAsset]. Look at the doc comments of those classes for usage of this!
  ///
  /// This uses [FileUtils.getAssetFolders] and will not return any plugin packages with are inside of the
  /// [FileUtils.assetFoldersBlacklist] like for example the useless "cupertino_icons" package!
  List<String> get staticAssetFolders => _assetFolders;

  static final List<String> _assetFolders = FileUtils.getAssetFolders();

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
