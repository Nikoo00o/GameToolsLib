import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/enums/log_level.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/domain/entities/base/model.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

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
/// object which can be modified.
/// Also here an example is given how to override default values for members of the super class like here [logLevel]
/// with a different key, but the same default value spam
final class ExampleMutableConfig extends MutableConfig {
  /// For showcase this does not use a translation key here!
  final ModelConfigOption<ExampleModel?> somethingNew = ModelConfigOption<ExampleModel?>(
    title: TS.raw("Example Model"),
    description: TS.raw("some longer description....some longer description....some longer description...."),
    defaultValue: ExampleModel(someData: 5, modifiableData: <ExampleModel>[]),
    lazyLoaded: false,
    updateCallback: (ExampleModel? newModel) => Logger.verbose("got new model $newModel"),
    createNewModelInstance: ModelConfigOption.createNewExampleModelInstance,
    createModelBuilder: ModelConfigOption.createExampleModelBuilder,
  );

  /// Private member instance is needed to supply different value to the overridden getter below!
  /// This translation key is only for showcase and not contained in the translation files!
  final LogLevelConfigOption _logLevelInstance = LogLevelConfigOption(
    title: TS.raw("config.example.logLevel"),
    defaultValue: LogLevel.SPAM,
  );

  /// Override getter and return cached instance!
  @override
  LogLevelConfigOption get logLevel => _logLevelInstance;

  /// New option used above in [ExampleFixedConfig] to override the long periodic spam delay and set it to 0 per
  /// default (so all periodic spam logs are always logged)
  IntConfigOption get mutableDelay => IntConfigOption(title: TS.raw("Mutable Delay"), defaultValue: 0);

  /// Important: also pass all new config options to the ui! (no translation key used for the group in this example
  /// and the last log level instance config option will be duplicated and put in the "other" group as well to test it)
  @override
  getConfigurableOptions() => <MutableConfigOption<dynamic>>[
    ...super.getConfigurableOptions(),
    MutableConfigOptionGroup(
      title: TS.raw("Example Group"),
      configOptions: <MutableConfigOption<dynamic>>[mutableDelay],
    ),
    somethingNew,
    logLevel,
  ];
}

/// Example on how to override [GameToolsConfig]. Returns newly created objects of the custom config types
/// Look at [GameToolsLib.useExampleConfig] for usage.
///
/// Also directly overrides [appTitle] for the example and for testing!
final class ExampleGameToolsConfig extends GameToolsConfig<ExampleFixedConfig, ExampleMutableConfig> {
  ExampleGameToolsConfig() : super(fixed: ExampleFixedConfig(), mutable: ExampleMutableConfig());

  @override
  String get appTitle => "GameToolsLib Example";
}
