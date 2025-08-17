part of 'package:game_tools_lib/game_tools_lib.dart';

/// Subclasses of this are used in [GameManager.moduleConfiguration] to split of code/logic to handle:
///
/// 1. the callbacks [onStart], [onStop], [onUpdate], [onOpenChange], [onFocusChange], [onStateChange] which can
/// optionally be overridden like in the [GameManager] subclass itself (important: these callbacks of the module will
/// always be called after those of the game manager!),
///
/// 2. additional [MutableConfigOption] similar to [MutableConfig.getConfigurableOptions] but without any
/// groups and instead grouped together with the [moduleName] which will be loaded once with
/// [loadAllConfigurableOptions] and can then be retrieved in [configurableOptions]. The config options should of
/// course also be final member variables here as well! And of course you could also use fixed config options as getters
/// here instead of in [FixedConfig].
///
/// 3. additional [MouseInputListener] or [KeyInputListener] in [getAdditionalInputListener] which are grouped by
/// [moduleName] in addition to the constructor of [GameManager] which will automatically be added to the game manager
/// in [_addInputListeners]!
///
/// 4. additional [LogInputListener] in [getAdditionalLogInputListener] in addition to the constructor of
/// [GameLogWatcher] which will automatically be added to it and initialized.
///
/// The [GameManagerType] is only optionally used to retrieve the correct type in [gameManager].
abstract base class Module<GameManagerType extends GameManagerBaseType> {
  /// The name of this module which will also be used to display the hotkey and settings group labels (menu entries)
  /// and is used to identify this module. This has to be overridden in sub classes (can also return a cached member
  /// variable for performance reasons)!
  TranslationString get moduleName;

  /// Cache for [getConfigurableOptions]
  MutableConfigOptionGroup? _configurableOptions;

  /// Is called at the start of [GameToolsLib.runLoop] (so after [GameToolsLib.initGameToolsLib] of the program start).
  /// Use it for game specific custom init! (at this point the ui is already visible, because [runApp] has been called.
  Future<void> onStart() async {}

  /// Is called at the start of [GameToolsLib.close] when closing your program. Use it for game specific custom cleanup!
  Future<void> onStop() async {}

  /// Is called at the start of the internal game tools lib event loop [FixedConfig.updatesPerSecond] times per second,
  /// but it won't be awaited! Use it for game specific custom updates! Important: if you use multiple longish
  /// delays inside of this, then check [GameWindow.isOpen] and [GameWindow.hasFocus] after every delay, because it
  /// might have changed in the meantime (see [onFocusChange] and [onOpenChange])!
  Future<void> onUpdate() async {}

  /// Is called when the open status changes for [window]. This will also be called when it opens for the first time!
  /// Don't use any delays inside of this!
  Future<void> onOpenChange(GameWindow window) async {}

  /// Is called when the focus changes for [window]. This will also be called when it receives focus for the first time!
  /// Don't use any delays inside of this!
  Future<void> onFocusChange(GameWindow window) async {}

  /// Is called after the state is changed from [oldState] to [newState] with [GameManager.changeState].
  /// Don't use any delays inside of this! Important: the first and last state on start and end will always be
  /// [GameClosedState]!
  Future<void> onStateChange(GameState oldState, GameState newState) async {}

  /// Should be overridden to provide additional [LogInputListener] in addition to the ones in the constructor of
  /// [GameLogWatcher] and [GameLogWatcher.additionalListeners]. Those additional ones will also be initialized in
  /// [GameToolsLib.initGameToolsLib] with [GameLogWatcher._init]
  List<LogInputListener> getAdditionalLogInputListener() => <LogInputListener>[];

  /// Should be overridden to provide additional [MouseInputListener] or [KeyInputListener] in addition to the
  /// constructor of [GameManager] which will automatically be added in [_addInputListeners].
  ///
  /// Important: all of those listeners will have their [BaseInputListener.configGroupLabel] set to the [moduleName]!
  List<BaseInputListener<dynamic>> getAdditionalInputListener() => <BaseInputListener<dynamic>>[];

  /// Called automatically in [GameToolsLib.initGameToolsLib] to add the [getAdditionalInputListener] to the
  /// [GameManager] and also set the [BaseInputListener.configGroupLabel] to the [moduleName] for them
  void _addInputListeners(int logListenerLength) {
    final List<BaseInputListener<dynamic>> listeners = getAdditionalInputListener();
    for (final BaseInputListener<dynamic> listener in listeners) {
      listener.configGroupLabel = moduleName;
    }
    GameManager._instance!._inputListeners.addAll(listeners);
    final String msg =
        "$runtimeType provided ${listeners.length} additional input listener and $logListenerLength "
        "additional log listener";
    Logger.verbose(msg);
  }

  /// Similar to [MutableConfig.getConfigurableOptions] this can be overridden to provide additional
  /// [MutableConfigOption]'s, but you may not use any [MutableConfigOptionGroup] inside of this, because one will be
  /// created automatically with the [moduleName] to group those together!
  List<MutableConfigOption<dynamic>> getConfigurableOptions() => <MutableConfigOption<dynamic>>[];

  /// Used to return the cached [getConfigurableOptions] wrapped with the [moduleName] as a [MutableConfigOptionGroup]
  MutableConfigOptionGroup get configurableOptions {
    _configurableOptions ??= MutableConfigOptionGroup(title: moduleName, configOptions: getConfigurableOptions());
    return _configurableOptions!;
  }

  /// This will be called automatically at the end of [GameToolsLib.initGameToolsLib] to load all
  /// [getConfigurableOptions] by loading their values without updating listeners and calling [MutableConfigOption.onInit]
  /// on them similar to [MutableConfig.loadAllConfigurableOptions]
  Future<void> loadAllConfigurableOptions() async {
    if (configurableOptions.cachedValueNotNull().isNotEmpty) {
      await configurableOptions.getValue(updateListeners: false);
      await configurableOptions.onInit();
      Logger.verbose("Loaded $runtimeType configurable option $configurableOptions");
    } else {
      Logger.spam("$runtimeType did not contain any configurable options");
    }
  }

  /// Returns the correct subclass type of the [GameManager] for [GameManagerType]
  GameManagerType gameManager() => GameToolsLib.gameManager<GameManagerType>();
}

/// Typedef for base type
typedef ModuleBaseType = Module<GameManagerBaseType>;
