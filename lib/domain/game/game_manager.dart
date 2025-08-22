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
/// You can also optionally retrieve the config values of the game directly with your custom sub class of
/// [GameConfigLoader] in [gameConfigLoader]! Same with the [OverlayManager] in [overlayManager] for ui stuff!
///
/// The [WebManager] for http requests can be retrieved with [webManager].
///
/// And in the same way you can manage your [BaseInputListener] like [MouseInputListener] and [KeyInputListener] in
/// the constructor, but also in [addInputListener] and [removeInputListener]. (can also optionally be added in
/// [Module.getAdditionalInputListener] instead).
///
/// You have to override [onStart], [onStop], [onUpdate], [onOpenChange], [onFocusChange], [onStateChange] to react
/// to changes! But you can also override [moduleConfiguration] to split the code into different [Module]'s that
/// instead react to those changes (look at the docs there for more info. They can also contain mutable config
/// options and input listener and are retrieved with [modules], or per name with [getModule]!).
///
/// Don't initialize anything in the constructor of your sub classes of this and everything else and instead use
/// something like [onStart] which is called after [GameToolsLib.initGameToolsLib] so that you can also access the
/// config, etc during your custom init!
///
/// For an example look at [ExampleGameManager].
abstract base class GameManager<ConfigType extends GameToolsConfigBaseType> {
  /// Internal list of [BaseInputListener]'s that will be updated by the event loop.
  final List<BaseInputListener<dynamic>> _inputListeners;

  /// List of modules that is only set once from [moduleConfiguration] at the end of the constructor and
  /// never changed!
  ///
  /// It is Used to retrieve all of the modules of [moduleConfiguration], individual modules should be retrieved with
  /// [getModule] instead!
  late final UnmodifiableListView<ModuleBaseType> modules;

  /// Used for performance reasons when updating [modules]
  late final bool _hasModules;

  /// [inputListeners] can be your list of subclasses of [BaseInputListener] like [MouseInputListener] and
  /// [KeyInputListener]. If null, then it will be empty for now, but you can use [addInputListener] later
  /// (subclass constructors can also directly pass something to this).
  /// Important: those do not include the [LogInputListener]!
  GameManager({
    required List<BaseInputListener<dynamic>>? inputListeners,
  }) : _inputListeners = inputListeners ?? <BaseInputListener<dynamic>>[] {
    modules = UnmodifiableListView<ModuleBaseType>(moduleConfiguration());
    _hasModules = modules.isNotEmpty;
  }

  /// Can be overridden to return a list of modules to organize some codes and split of logic into modules which have
  /// the same callbacks as this game manager and can also contain mutable config options and input listener!
  ///
  /// It is only used at the end of the constructor to init the [modules] for which access can also be done with the
  /// name by using [getModule]!
  ///
  /// Per default this returns just an empty list (sub classes should also add the modules of super classes by
  /// calling the super class method first when returning)
  @protected
  List<ModuleBaseType> moduleConfiguration() => <ModuleBaseType>[];

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

  /// Returns a list of all currently active [GameEvent]s that match the [EventType]
  List<GameEvent> getEventByType<EventType>() => GameToolsLib.getEventByType<EventType>();

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

  /// Returns the [currentState] as [StateType] (should be nullable type and checked afterwards)
  StateType getCurrentState<StateType>() => currentState as StateType;

  /// Adds a new [listener] to the internal list of input listeners (important: this does not include the
  /// [LogInputListener]!)
  void addInputListener(BaseInputListener<dynamic> listener) {
    _inputListeners.add(listener);
    Logger.verbose("Added input listener $listener");
  }

  /// Removes the [listener] from the internal list of input listeners (important: this does not include the
  /// [LogInputListener]!) and returns if it was successful.
  ///
  /// Important: the [listener] must be a reference to the same object that was added with [addInputListener]!
  /// This is rarely used, because you can also control the active status of a listener with
  /// [BaseInputListener.eventCreateCondition] instead!
  bool removeInputListener(BaseInputListener<dynamic> listener) {
    final bool removed = _inputListeners.remove(listener);
    if (removed) {
      Logger.verbose("Removed input listener $listener");
    } else {
      Logger.warn("Did not find input listener to remove $listener");
    }
    return removed;
  }

  /// Returns an unmodifiable list of the current input listeners
  UnmodifiableListView<BaseInputListener<dynamic>> getInputListeners() =>
      UnmodifiableListView<BaseInputListener<dynamic>>(_inputListeners);

  /// Adds a new [listener] to the internal list of log input listeners
  void addLogInputListener(LogInputListener listener) => GameToolsLib.addLogInputListener(listener);

  /// Removes the [listener] from the internal list of log input listeners
  void removeLogInputListener(LogInputListener listener) => GameToolsLib.removeLogInputListener(listener);

  /// Reference to the game config loader if it was used in [GameToolsLib.initGameToolsLib] (otherwise throws
  /// [ConfigException]!)
  T gameConfigLoader<T extends GameConfigLoader>() => GameToolsLib.gameConfigLoader<T>();

  /// Reference to [OverlayManager.overlayManager] for ui overlay displaying
  T overlayManager<T extends OverlayManagerBaseType>() => GameToolsLib.overlayManager<T>();

  /// Reference to [WebManager.webManager] for sending http requests
  T webManager<T extends WebManager>() => GameToolsLib.webManager<T>();

  /// Used to retrieve the module with the name [moduleName] of the [moduleConfiguration], or return null if that
  /// module was not found!
  ///
  /// Even better would be to use this to save final static instances in your subclass of [GameManager] instead to
  /// access the modules (which will then be late initialized when accessed. or the other way around, return static
  /// module instances in [moduleConfiguration]) like for example:
  ///
  /// `static final SomeModuleType someModule = GameManager.gameManager().getModule<SomeModuleType>(const TS("some.module"))!;`
  ///
  /// Or
  ///
  /// ```dart
  ///  static final Module<GameManagerBaseType> someModule = SomeModuleType(const TS("some.module"));
  ///
  ///   @override
  ///   @protected
  ///   List<Module<GameManagerBaseType>> moduleConfiguration() => <Module<GameManagerBaseType>>[someModule];
  /// ```
  ///
  T? getModule<T extends ModuleBaseType>(TranslationString moduleName) =>
      modules.firstWhereOrNull((ModuleBaseType module) => module.moduleName == moduleName) as T?;

  /// Returns the the [GameManager._instance] if already set, otherwise throws a [ConfigException]
  static T gameManager<T extends GameManagerBaseType>() {
    if (_instance == null) {
      throw const ConfigException(message: "GameManager was not initialized yet ");
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
