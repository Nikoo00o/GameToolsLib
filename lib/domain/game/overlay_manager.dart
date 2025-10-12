part of 'package:game_tools_lib/game_tools_lib.dart';

// todo: doc comments
/// This (or sub classes of this) is the interaction point between your data code layer and a transparent overlay
/// ([GTOverlay]) on top of your window (per default the [GameToolsLib.mainGameWindow]) where you can draw ui
/// elements (todo: reference) and also modify them!
///
/// The [overlayMode] can be used to access or modify the current mode (might also be used to render elements
/// conditionally)!
///
/// todo: reference what to override of this
base class OverlayManager<OverlayStateType extends GTOverlayState> {
  /// This is used to get the [overlayState] and [overlayContext] from the the [GTOverlay]!
  final GlobalKey<OverlayStateType> overlayReference = GlobalKey<OverlayStateType>();

  /// This is set optionally in the constructor while defaulting to [OverlayMode.APP_OPEN] and it is used to render
  /// the different overlay states depending on the mode!
  ///
  /// You can modify this directly to change the overlay mode and changes will arrive in [onOverlayModeChanged] and
  /// in [GTOverlay]! Prefer to use [changeMode] instead to change the overlay mode.
  final SimpleChangeNotifier<OverlayMode> overlayMode;

  OverlayManager([OverlayMode initialOverlayMode = OverlayMode.APP_OPEN])
    : overlayMode = SimpleChangeNotifier<OverlayMode>(initialOverlayMode) {
    overlayMode.addListener(_overlayModeListener);
  }

  /// This is called after running the flutter app in [GameToolsLib.runLoop] (before any [GameManager.onStart] is
  /// called) for stuff that needs to be initialized before [onCreate]. Don't do any UI work with [overlayReference]
  /// in here, because the second window is not open at this point!
  @mustCallSuper
  Future<bool> init() async {
    // todo: MULTI-WINDOW IN THE FUTURE: create second overlay window (could also init here instead of in onCreate)
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
    // todo: MULTI-WINDOW IN THE FUTURE: maximise and hide transparent overlay window (or is it started that way?)
  }

  /// This is called once when the ui closes when the [GTOverlayState] for the [GTOverlay] widget is disposed in
  /// [GTOverlayState.dispose]!
  ///
  /// Important: you can not use the [overlayState], or [overlayContext] here and the [context] cannot be used for
  /// [BuildContext.inheritFromWidgetOfExactType] here!
  @mustCallSuper
  void onDispose(BuildContext context) {
    overlayMode.removeListener(_overlayModeListener);
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
    if (window.isOpen == false && overlayMode.value != OverlayMode.APP_OPEN) {
      changeMode(OverlayMode.APP_OPEN);
    }

    Logger.info("test open"); // todo: remove after min and maximize test
  }

  /// Is called when the focus changes for [window]. This will also be called when it receives focus for the first time!
  /// Don't use any delays inside of this! This will be called before [GameManager] and [Module].
  @mustCallSuper
  Future<void> onFocusChange(GameWindow window) async {
    Logger.info("test focus $window"); // todo: remove after min and maximize test
  }

  /// This is called when the size of the [window] changes (for example when switching to full screen). This will
  /// also be called when the window opens for the first time with the initial size of it. And also when the window
  /// closes this will be called and the [GameWindow.size] will then be null!
  @mustCallSuper
  Future<void> onWindowResize(GameWindow window) async {
    if (overlayMode.value != OverlayMode.APP_OPEN) {}

    // todo: remove after min and maximize test
    if (window.size != null) {
      Logger.info("test resize ${window.size} related to bounds ${window.getWindowBounds()}");
    }
  }

  /// Is called after the [overlayMode] was changed with the old value being [lastMode] (null the first time!).
  @mustCallSuper
  void onOverlayModeChanged(OverlayMode? lastMode) {
    Logger.verbose("Switched Overlay from $lastMode to ${overlayMode.value}");
    _GameToolsLibEventLoop._runForAllEvents((GameEvent event) {
      event.onOverlayModeChanged(lastMode, overlayMode.value);
    });
  }

  /// Uses [GTOverlayState.showToast] to show a message on the bottom only if the overlay is currently active, but
  /// this uses a post frame callback for the call by using [scheduleUIWork] so that it will be called after the next
  /// build!
  ///
  /// Additionally this contains a [delay] param to wait until displaying the toast message.
  ///
  /// Otherwise nothing will be shown/done! This may not be called during build (use post frame callback)!
  Future<void> showToast(
    TranslationString message, {
    Duration duration = const Duration(seconds: 4),
    Duration delay = Duration.zero,
  }) => scheduleUIWork((BuildContext? context) => overlayReference.currentState?.showToast(message, duration), delay);

  /// This can be used to build a (for example [AlertDialog]) inside of the [buildDialog] callback which will then be
  /// displayed after the next build method by using [scheduleUIWork].
  ///
  /// If you choose a specific [t] then your dialog can use specific data in its [Navigator.pop] which will be
  /// returned here! Returns null if you return nothing or if there is no build context available.
  Future<t?> showCustomDialog<t>(Widget Function(BuildContext context) buildDialog) async {
    final Completer<t?> completer = Completer<t?>();
    await scheduleUIWork((BuildContext? context) async {
      if (context == null) {
        completer.complete(null);
      } else {
        final t? result = await showDialog<t>(context: context, builder: buildDialog);
        completer.complete(result);
      }
    });
    return completer.future;
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
    // todo: MULTI-WINDOW IN THE FUTURE: should be executed on overlay window
    // maybe also show toast then for overlay window? (needs scaffold and cant be used on big app)
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

  /// Changes the [overlayMode] to [newOverlayMode], but does not allow changes to the same exact mode.
  /// Of course this will also trigger [onOverlayModeChanged]!
  void changeMode(OverlayMode newOverlayMode) {
    if (newOverlayMode != overlayMode.value) {
      overlayMode.value = newOverlayMode;
    } else {
      Logger.warn("Tried to change to the same new overlay mode $newOverlayMode");
    }
  }

  /// Helper for [_overlayModeListener]
  static OverlayMode? _lastMode;

  /// Listener for changes to [overlayMode]
  static void _overlayModeListener() {
    _instance?.onOverlayModeChanged(_lastMode);
    _lastMode = _instance?.overlayMode.value;
  }

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
