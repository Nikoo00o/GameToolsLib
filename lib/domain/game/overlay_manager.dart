part of 'package:game_tools_lib/game_tools_lib.dart';

// todo: doc comments
/// This (or sub classes of this) is the interaction point between your data code layer and a transparent overlay
/// ([GTOverlay]) on top of your window (per default the [GameToolsLib.mainGameWindow]) where you can draw ui
/// elements (todo: reference) and also modify them!
base class OverlayManager<OverlayStateType extends GTOverlayState> {
  /// This is used to get the [overlayState] and [overlayContext] from the the [GTOverlay]!
  final GlobalKey<OverlayStateType> overlayReference = GlobalKey<OverlayStateType>();

  /// This is called after running the flutter app in [GameToolsLib.runLoop] (before any [GameManager.onStart] is
  /// called) for stuff that needs to be initialized before [onCreate]. Don't do any UI work with [overlayReference]
  /// in here, because the second window is not open at this point!
  @mustCallSuper
  Future<bool> init() async {
    // todo: create second window with new flutter api. maybe also maximise and hide transparent, etc instead of in
    // onCreate below?
    return true;
  }

  /// This is called once when the ui gets build for the first time when the [GTOverlayState] for the [GTOverlay].
  /// widget is created in [GTOverlayState.initState]!
  ///
  /// Important: you can not use the [overlayState], or [overlayContext] here and the [context] cannot be used for
  /// [BuildContext.inheritFromWidgetOfExactType] here! For UI work use [scheduleUIWork] instead!
  ///
  /// If you need stuff to be available earlier, or init async code, use [init] instead!
  @mustCallSuper
  void onCreate(BuildContext context) {
    Logger.info("test create");
    // todo: switch to overlay mode for this window by calling maximise and hide transparent, etc
  }

  /// This is called once when the ui closes when the [GTOverlayState] for the [GTOverlay] widget is disposed in
  /// [GTOverlayState.dispose]!
  ///
  /// Important: you can not use the [overlayState], or [overlayContext] here and the [context] cannot be used for
  /// [BuildContext.inheritFromWidgetOfExactType] here!
  @mustCallSuper
  void onDispose(BuildContext context) {
    Logger.info("test dispose");
  }

  /// Is called at the start of the internal game tools lib event loop [FixedConfig.updatesPerSecond] times per second,
  /// but it won't be awaited! Use it for game specific custom updates! Important: if you use multiple longish
  /// delays inside of this, then check [GameWindow.isOpen] and [GameWindow.hasFocus] after every delay, because it
  /// might have changed in the meantime (see [onFocusChange] and [onOpenChange])!
  /// This will be called before [GameManager] and [Module].
  @mustCallSuper
  Future<void> onUpdate() async {}

  /// Is called when the open status changes for [window]. This will also be called when it opens for the first time!
  /// Don't use any delays inside of this! This will be called before [GameManager] and [Module].
  @mustCallSuper
  Future<void> onOpenChange(GameWindow window) async {
    Logger.info("test open");
  }

  /// Is called when the focus changes for [window]. This will also be called when it receives focus for the first time!
  /// Don't use any delays inside of this! This will be called before [GameManager] and [Module].
  @mustCallSuper
  Future<void> onFocusChange(GameWindow window) async {
    Logger.info("test focus");
  }

  void showDialog() {
    // todo: use scheduleUIwork aber mit completer und await here!
  }

  /// Will execute [callback] after the current frame has been rendered (so every ui element should be available at that
  /// point). The inner [BuildContext] context is not null if the [overlayContext] is mounted!
  ///
  /// Important: the [callback] will not be awaited here and should only modify UI stuff! If you have inner awaits in
  /// your callback, then you should check the mounted status of the [BuildContext] afterwards.
  ///
  /// Optionally a [delay] can also be used which is awaited before scheduling the work for the next frame.
  Future<void> scheduleUIWork(
    FutureOr<void> Function(BuildContext? context) callback, [
    Duration delay = Duration.zero,
  ]) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    SchedulerBinding.instance.addPostFrameCallback((Duration? timestamp) {
      final BuildContext? context = overlayContext;
      if (context?.mounted ?? false) {
        callback(context!);
      } else {
        callback(null);
      }
    });
  }

  /// Uses [overlayReference] to get the [GTOverlay]. This is not-null some time after [onCreate] is called
  BuildContext? get overlayContext => overlayReference.currentContext;

  /// Uses [overlayReference] to get the [GTOverlay]. This is not-null some time after [onCreate] is called.
  OverlayStateType? get overlayState => overlayReference.currentState;

  /// Returns the the [GameLogWatcher._instance] if already set, otherwise throws a [ConfigException]
  static T overlayManager<T extends OverlayManagerBaseType>() {
    if (_instance == null) {
      throw const ConfigException(message: "OverlayManager was not initialized yet ");
    } else if (_instance is T) {
      return _instance as T;
    } else {
      throw ConfigException(message: "Wrong type $T for $_instance");
    }
  }

  /// Concrete instance of this controlled by [GameToolsLib]
  static OverlayManagerBaseType? _instance;
}

/// Typedef for base type
typedef OverlayManagerBaseType = OverlayManager<GTOverlayState>;
