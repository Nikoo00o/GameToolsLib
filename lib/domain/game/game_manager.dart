part of 'package:game_tools_lib/game_tools_lib.dart';

/// This is your main interaction point and you have to extend this with a custom sub class to handle all the events!
///
/// Has the following getters: [config], [gameWindows], [mainWindow], [database]
///
/// And the following only offers static access: [InputManager],
///
/// For an example look at [ExampleGameManager]
abstract base class GameManager<ConfigType extends GameToolsConfigBaseType> {
  /// Is called at the start of [GameToolsLib.runLoop] (so after [GameToolsLib.initGameToolsLib] of the program start)
  Future<void> onStart();

  /// Is called at the start of [GameToolsLib.close] when closing your program
  Future<void> onStop();

  /// Is called in the internal game tools lib event loop [FixedConfig.updatesPerSecond] times per second!
  Future<void> onUpdate();

  /// Returns a reference to [GameToolsLib.config] with the [ConfigType]
  ConfigType get config => GameToolsLib.config<ConfigType>();

  /// Returns the list of game windows as non modifiable list. Of course the individual game window objects can be modified!
  UnmodifiableListView<GameWindow> get gameWindows => GameToolsLib.gameWindows;

  /// The first and main game window to use.
  GameWindow get mainWindow => GameToolsLib._gameWindows!.first;

  /// The database for storage
  HiveDatabase get database => GameToolsLib.database;

  /// Returns the the [GameManager._instance] if already set, otherwise throws a [ConfigException]
  static T gameManager<T extends GameManagerBaseType>() {
    if (_instance == null) {
      throw ConfigException(message: "GameManager was not initialized yet ");
    } else if (_instance is T) {
      return _instance as T;
    } else {
      throw ConfigException(message: "Wrong type $T for $_instance");
    }
  }

  /// Concrete instance of this controlled by [GameToolsLib]
  static GameManagerBaseType? _instance;
}

/// Typedef for base type
typedef GameManagerBaseType = GameManager<GameToolsConfigBaseType>;

/// Example that uses [ExampleGameToolsConfig]
final class ExampleGameManager extends GameManager<ExampleGameToolsConfig> {
  @override
  Future<void> onStart() async {}

  @override
  Future<void> onStop() async {}

  @override
  Future<void> onUpdate() async {}
}
