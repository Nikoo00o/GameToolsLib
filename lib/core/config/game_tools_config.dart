part of 'package:game_tools_lib/game_tools_lib.dart';

/// Base class with getters for the [fixed] and [mutable] parts of the config. These should be overridden in sub
/// class to return new objects.
///
/// Sub classes should also use extend with the custom types for [FixedConfigType] and [MutableConfigType]
/// For an example look at [_ExampleGameToolsConfig]
///
/// Remember to call [GameToolsLib.initGameToolsLib] first with your config sub class!
base class GameToolsConfig<FixedConfigType extends FixedConfig, MutableConfigType extends MutableConfig> {
  /// Returns the fixed part of this config where all values are stored inside of the dart classes
  FixedConfigType get fixed => FixedConfig() as FixedConfigType;

  /// Returns the mutable part of this config where all values are stored inside of a local file
  MutableConfigType get mutable => MutableConfig() as MutableConfigType;

  static GameToolsConfig<FixedConfig, MutableConfig>? _instance;

  /// Returns the the [GameToolsConfig._instance] if already set, otherwise throws a [ConfigException]
  static T config<T extends GameToolsConfig<FixedConfig, MutableConfig>>() {
    if (_instance == null) {
      throw ConfigException(message: "GameToolsConfig.initConfig was not called yet");
    } else if (_instance is T) {
      return _instance as T;
    } else {
      throw ConfigException(message: "Wrong type $T for $_instance");
    }
  }

  /// The [config] as base [BaseGameToolsConfig]
  static BaseGameToolsConfig get baseConfig => config<BaseGameToolsConfig>();
}

/// Base Type
typedef BaseGameToolsConfig = GameToolsConfig<FixedConfig, MutableConfig>;

/// Overrides an existing member [logIntoStorage] to return [false] instead of [true]
final class _ExampleFixedConfig extends FixedConfig {
  @override
  bool get logIntoStorage => false;
}

/// Adds a new more complex member [somethingNew] by using a [ModelConfigOption] with a [ExampleModel] as the stored
/// object.
/// Also here the [logLevel] is only debug per default
final class _ExampleMutableConfig extends MutableConfig {
  /// The key of the config value is just the same as the member variable name
  ModelConfigOption<ExampleModel> get somethingNew => ModelConfigOption<ExampleModel>(
    key: "somethingNew",
    defaultValue: ExampleModel(someData: 5, modifiableData: <ExampleModel>[]),
    lazyLoaded: false,
    updateCallback: (ExampleModel? newModel) => Logger.verbose("got new model $newModel"),
    createNewModelInstance: ModelConfigOption.createNewExampleModelInstance,
  );

  @override
  LogLevelConfigOption get logLevel => LogLevelConfigOption(key: "logLevel", defaultValue: LogLevel.DEBUG);
}

/// Example on how to override [GameToolsConfig]. Returns newly created objects of the custom config types
/// Look at [GameToolsLibHelper.useExampleConfig] for usage
final class _ExampleGameToolsConfig extends GameToolsConfig<_ExampleFixedConfig, _ExampleMutableConfig> {
  /// Returns the fixed part of this config where all values are stored inside of the dart classes
  @override
  _ExampleFixedConfig get fixed => _ExampleFixedConfig();

  /// Returns the mutable part of this config where all values are stored inside of a local file
  @override
  _ExampleMutableConfig get mutable => _ExampleMutableConfig();
}
