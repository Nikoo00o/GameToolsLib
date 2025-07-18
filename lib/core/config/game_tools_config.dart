part of 'package:game_tools_lib/game_tools_lib.dart';

/// Base class with getters for the [fixed] and [mutable] parts of the config. These should be overridden in sub
/// class to return new objects.
///
/// Sub classes should also use extend with the custom types for [FixedConfigType] and [MutableConfigType]
/// For an example look at [ExampleGameToolsConfig]
///
/// Remember to call [GameToolsLib.initGameToolsLib] first with your config sub class!
base class GameToolsConfig<FixedConfigType extends FixedConfig, MutableConfigType extends MutableConfig> {
  /// Returns the fixed part of this config where all values are stored inside of the dart classes
  FixedConfigType get fixed => FixedConfig() as FixedConfigType;

  /// Returns the mutable part of this config where all values are stored inside of a local file
  MutableConfigType get mutable => MutableConfig() as MutableConfigType;

  static GameToolsConfigBaseType? _instance;

  /// Returns the the [GameToolsConfig._instance] if already set, otherwise throws a [ConfigException]
  static T config<T extends GameToolsConfigBaseType>() {
    if (_instance == null) {
      throw ConfigException(message: "GameToolsConfig was not initialized yet!");
    } else if (_instance is T) {
      return _instance as T;
    } else {
      throw ConfigException(message: "Wrong type $T for $_instance");
    }
  }

  /// The [config] as base [GameToolsConfigBaseType]
  static GameToolsConfigBaseType get baseConfig => config<GameToolsConfigBaseType>();
}

/// Base Type
typedef GameToolsConfigBaseType = GameToolsConfig<FixedConfig, MutableConfig>;

/// Overrides an existing member [logIntoStorage] to return [false] instead of [true]
final class ExampleFixedConfig extends FixedConfig {
  @override
  bool get logIntoStorage => false;

  /// Of course you could also override and redirect config options from fixed to mutable if you want the user to be
  /// able to modify something
  @override
  int get logPeriodicSpamDelayMS =>
      (MutableConfig.mutableConfig as ExampleMutableConfig).mutableDelay.cachedValueNotNull();
}

/// Adds a new more complex member [somethingNew] by using a [ModelConfigOption] with a [ExampleModel] as the stored
/// object.
/// Also here the [logLevel] is overridden with a different key, but the same default value spam
final class ExampleMutableConfig extends MutableConfig {
  /// The key of the config value is just the same as the member variable name
  ModelConfigOption<ExampleModel> get somethingNew => ModelConfigOption<ExampleModel>(
    key: "somethingNew",
    defaultValue: ExampleModel(someData: 5, modifiableData: <ExampleModel>[]),
    lazyLoaded: false,
    updateCallback: (ExampleModel? newModel) => Logger.verbose("got new model $newModel"),
    createNewModelInstance: ModelConfigOption.createNewExampleModelInstance,
  );

  @override
  LogLevelConfigOption get logLevel => LogLevelConfigOption(key: "Example Log Level", defaultValue: LogLevel.SPAM);

  /// New option used above in [ExampleFixedConfig] to override the long periodic spam delay and set it to 0 per
  /// default (so all periodic spamm logs are always logged)
  IntConfigOption get mutableDelay => IntConfigOption(key: "Mutable Delay", defaultValue: 0);
}

/// Example on how to override [GameToolsConfig]. Returns newly created objects of the custom config types
/// Look at [GameToolsLib.useExampleConfig] for usage
final class ExampleGameToolsConfig extends GameToolsConfig<ExampleFixedConfig, ExampleMutableConfig> {
  /// Returns the fixed part of this config where all values are stored inside of the dart classes
  @override
  ExampleFixedConfig get fixed => ExampleFixedConfig();

  /// Returns the mutable part of this config where all values are stored inside of a local file
  @override
  ExampleMutableConfig get mutable => ExampleMutableConfig();
}
