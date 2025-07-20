part of 'package:game_tools_lib/game_tools_lib.dart';

/// This is your main interaction point and you have to extend this with a custom sub class to handle all the events!
///
/// The [ConfigType] must be your [GameToolsConfig] subclass type subclass type for easier access!
///
/// Has the following getters: [config] for your subclass of [GameToolsConfig], [gameWindows], [mainWindow] for
/// [GameWindow], [database].
///
/// And the following only offers static access: [InputManager], [GameToolsLib].
///
/// You can also manage events here with [addEvent], [getEventByType], [getEventByGroup], or [events] to work with your
/// subclass of the [GameEvent]s!
///
/// And your subclass [GameState]'s are accessed with [currentState], [getCurrentState] and [changeState]. The state
/// starts with [GameClosedState], but of course you can directly change it in [onStart]!
///
/// You can also manage your [LogInputListener] of your subclass of [GameLogWatcher] with [addLogInputListener] and
/// [removeLogInputListener].
///
/// And in the same way you can manage your [BaseInputListener] like [MouseInputListener] and [KeyInputListener] in
/// the constructor, but also in [addInputListener] and [removeInputListener].
///
/// You have to override [onStart], [onStop], [onUpdate], [onOpenChange], [onFocusChange], [onStateChange]!
///
/// For an example look at [ExampleGameManager].
abstract base class GameManager<ConfigType extends GameToolsConfigBaseType> {
  /// Internal list of [BaseInputListener]'s that will be updated by the event loop.
  final List<BaseInputListener<dynamic>> _inputListeners;

  /// [inputListeners] can be your list of subclasses of [BaseInputListener] like [MouseInputListener] and
  /// [KeyInputListener]. If null, then it will be empty for now, but you can use [addInputListener] later
  /// (subclass constructors can also directly pass something to this).
  /// Important: those do not include the [LogInputListener]!
  GameManager({
    required List<BaseInputListener<dynamic>>? inputListeners,
  }) : _inputListeners = inputListeners ?? <BaseInputListener<dynamic>>[];

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

  /// Is called when the open status changes for [window]. This will also be called when it opens for the first time!
  /// Don't use any delays inside of this!
  Future<void> onOpenChange(GameWindow window);

  /// Is called when the focus changes for [window]. This will also be called when it receives focus for the first time!
  /// Don't use any delays inside of this!
  Future<void> onFocusChange(GameWindow window);

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
  /// You have to cast this to your event subclass manually if you need specific access!
  List<GameEvent> getEventByGroup(GameEventGroup group) => GameToolsLib.getEventByGroup(group);

  /// Returns an unmodifiable reference to the event queue (list of all current events) from [GameToolsLib.events].
  /// You have to cast this to your event subclass manually if you need specific access!
  UnmodifiableListView<GameEvent> get events => GameToolsLib.events;

  /// Replaces the [currentState] with [newState] if its not already the same object by calling
  /// [GameToolsLib.changeState], but first calls [GameState.onStop] on the old state and at the end also calls
  /// [GameState.onStart] on the new state and [GameManager.onStateChange] and [GameEvent.onStateChange]!
  Future<void> changeState(GameState newState) async => GameToolsLib.changeState(newState);

  /// Returns the current active state from [GameToolsLib.currentState]. To directly cast to your sub type,
  /// use [getCurrentState]!
  GameState get currentState => GameToolsLib.currentState;

  /// Returns the [currentState] as [StateType]
  StateType getCurrentState<StateType>() => currentState as StateType;

  /// Adds a new [listener] to the internal list of input listeners (important: this does not include the
  /// [LogInputListener]!)
  void addInputListener(BaseInputListener<dynamic> listener) {
    _inputListeners.add(listener);
    Logger.verbose("Added $listener");
  }

  /// Removes the [listener] from the internal list of input listeners (important: this does not include the
  /// [LogInputListener]!)
  void removeInputListener(BaseInputListener<dynamic> listener) {
    _inputListeners.remove(listener);
    Logger.verbose("Removed $listener");
  }

  /// Adds a new [listener] to the internal list of log input listeners
  void addLogInputListener(LogInputListener listener) => GameToolsLib.addLogInputListener(listener);

  /// Removes the [listener] from the internal list of log input listeners
  void removeLogInputListener(LogInputListener listener) => GameToolsLib.removeLogInputListener(listener);

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
