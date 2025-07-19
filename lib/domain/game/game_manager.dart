part of 'package:game_tools_lib/game_tools_lib.dart';

/// This is your main interaction point and you have to extend this with a custom sub class to handle all the events!
///
/// Has the following getters: [config] for [GameToolsConfig], [gameWindows], [mainWindow] for [GameWindow], [database]
///
/// And the following only offers static access: [InputManager], [GameToolsLib]
///
/// You can also manage events here with [addEvent], [getEventByType], [getEventByGroup] to work with the [GameEvent]s!
///
/// And the [GameState]'s are accessed with [currentState] and [changeState]. The state starts with [OutOfGameState],
/// but of course you can directly change it in [onStart]!
///
/// You have to override [onStart], [onStop], [onUpdate], [onFocusChange], [onStateChange]
///
/// For an example look at [ExampleGameManager]
abstract base class GameManager<ConfigType extends GameToolsConfigBaseType> {
  /// Is called at the start of [GameToolsLib.runLoop] (so after [GameToolsLib.initGameToolsLib] of the program start).
  /// Use it for game specific custom init! (at this point the ui is already visible, because [runApp] has been called.
  Future<void> onStart();

  /// Is called at the start of [GameToolsLib.close] when closing your program. Use it for game specific custom cleanup!
  Future<void> onStop();

  /// Is called at the start of the internal game tools lib event loop [FixedConfig.updatesPerSecond] times per second,
  /// but it won't be awaited! Use it for game specific custom updates! Important: if you use multiple longish
  /// delays inside of this, then check [GameWindow.isOpen] and [GameWindow.hasFocus] after every delay, because it
  /// might have changed in the meantime (see [onFocusChange] and [onOpenChange])!
  Future<void> onUpdate();

  /// Is called when the focus changes for [window]. This will also be called when it receives focus for the first time!
  /// Don't use any delays inside of this!
  Future<void> onFocusChange(GameWindow window);

  /// Is called when the open status changes for [window]. This will also be called when it opens for the first time!
  /// Don't use any delays inside of this!
  Future<void> onOpenChange(GameWindow window);

  /// Is called after the state is changed from [oldState] to [newState] with [changeState].
  /// Don't use any delays inside of this! Important: the first and last state on start and end will always be
  /// [GameClosedState]!
  Future<void> onStateChange(GameState oldState, GameState newState);

  /// Returns a reference to [GameToolsLib.config] with the [ConfigType]
  ConfigType get config => GameToolsLib.config<ConfigType>();

  /// Returns the list of game windows as non modifiable list. Of course the individual game window objects can be modified!
  UnmodifiableListView<GameWindow> get gameWindows => GameToolsLib.gameWindows;

  /// The first and main game window to use.
  GameWindow get mainWindow => GameToolsLib._gameWindows!.first;

  /// The database for storage
  HiveDatabase get database => GameToolsLib.database;

  /// Adds any event to the internal event queue if the same event is not already in it. See [GameEvent] for
  /// documentation! To remove/delete an event, use [GameEvent.remove]!
  void addEvent(GameEvent event) => GameToolsLib.addEvent(event);

  /// Returns a list of all currently active [GameEvent]s that match the [Type]
  List<GameEvent> getEventByType<Type>() => GameToolsLib.getEventByType<Type>();

  /// Returns a list of all currently active [GameEvent]s that are in the group [group].
  List<GameEvent> getEventByGroup(GameEventGroup group) => GameToolsLib.getEventByGroup(group);

  /// Replaces the [currentState] with [newState] if its not already the same object by calling
  /// [GameToolsLib.changeState], but first calls [GameState.onStop] on the old state and at the end also calls
  /// [GameState.onStart] on the new state and [GameManager.onStateChange] and [GameEvent.onStateChange]!
  Future<void> changeState(GameState newState) async => GameToolsLib.changeState(newState);

  /// Returns the current active state from [GameToolsLib.currentState]
  GameState get currentState => GameToolsLib.currentState;

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

  @override
  Future<void> onFocusChange(GameWindow window) async {}

  @override
  Future<void> onOpenChange(GameWindow window) async {}

  @override
  Future<void> onStateChange(GameState oldState, GameState newState) async {}
}
