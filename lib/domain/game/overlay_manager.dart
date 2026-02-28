part of 'package:game_tools_lib/game_tools_lib.dart';

/// This (or sub classes of this) is the interaction point between your data code layer and a transparent overlay
/// ([GTOverlay]) on top of your window (per default the [GameToolsLib.mainGameWindow]) where you can draw ui
/// [OverlayElement]'s (stored in [overlayElementSubFolder]) like for example also [CompareImage] which can be created
/// and used anywhere! For more info look at doc comments there! As a helper it also uses static functions of
/// [NativeOverlayWindow]. Some parts of this are also implemented in [DelayedOverlayChecks]!
///
/// Mostly you probably won't interact with this class that much except maybe using [changeMode].
///
/// The [overlayMode] can be used to access or modify the current mode (might also be used to render elements
/// conditionally)! Always use [changeMode] or [changeModeAsync] to modify the mode instead of doing it directly!
///
/// Otherwise this provides the helper methods [showToast], [showCustomDialog] and [scheduleUIWork].
///
/// The list of [overlayElements] is handled automatically and should not be modified directly. [windowToTrack]
/// returns the current window ref (main window per default).
///
/// The [overlayState] or [overlayContext] can be accessed for the [overlayReference] (also see [GTOverlay])!
///
/// Subclasses may override first [init], then [onCreate] after which [active] is true until [onDispose], but also
/// [onUpdate], [onOpenChange], [onFocusChange], [onWindowResize] and [onOverlayModeChanged] callbacks!
///
/// You may also override the [createOverlayToggleHotkey] to provide a different default hotkey for toggling the
/// overlay!
///
/// This also provides a way to get a screenshot of the window without the overlay obscuring it with
/// [getWindowImageWithoutOverlay], but that causes flickering by turning the overlay on and off!
base class OverlayManager<OverlayStateType extends GTOverlayState> with DelayedOverlayChecks<OverlayStateType> {
  /// Sub folder of [GameToolsConfig.dynamicDataFolder] where the [OverlayElement]'s are stored into simple json files!
  ///
  /// Can be overridden in sub classes.
  String get overlayElementSubFolder => "overlay";

  /// This is set optionally in the constructor while defaulting to [OverlayMode.APP_OPEN] and it is used to render
  /// the different overlay states depending on the mode! Provided to [GTOverlay] with a provider!
  ///
  /// You can modify this directly to change the overlay mode and changes will arrive in [onOverlayModeChanged] and
  /// in [GTOverlay]! Prefer to use [changeMode], or better [changeModeAsync] instead to change the overlay mode.
  final SimpleChangeNotifier<OverlayMode> overlayModeNotifier;

  /// Returns the value of [overlayModeNotifier] (see doc comments there)
  @override
  OverlayMode get overlayMode => overlayModeNotifier.value;

  /// Per default always [GameToolsLib.mainGameWindow] set in [init], but can be overridden in the constructor.
  ///
  /// In overlay mode this will be the target window that determines size and position of the overlay
  @override
  GameWindow get windowToTrack => _win!;

  /// set in [init] or constructor.
  GameWindow? _win;

  /// Internal debug check between [onCreate] and [onDispose] checked in [changeMode] first!
  bool _active = false;

  /// If this overlay manager is active and running (as in an app ui was created at all)! This is different from the
  /// [overlayMode]!
  @override
  bool get active => _active;

  /// This is used to get the [overlayState] and [overlayContext] from the the [GTOverlay]!
  final GlobalKey<OverlayStateType> overlayReference = GlobalKey<OverlayStateType>();

  /// Contains all the cached [OverlayElement]'s (see doc comments of [OverlayElementsList] ) and can be used to
  /// add/remove elements, or modify elements, or build them!
  final OverlayElementsList overlayElements;

  @override
  List<OverlayElement> get clickableElements => overlayElements.clickableElements;

  /// Awaited in [changeModeAsync] if not null!
  Future<void>? _pendingWindowChange;

  /// [windowToTrackOverride] can rarely be used to override [windowToTrack]
  OverlayManager([OverlayMode initialOverlayMode = OverlayMode.APP_OPEN, GameWindow? windowToTrackOverride])
    : overlayModeNotifier = SimpleChangeNotifier<OverlayMode>(initialOverlayMode),
      overlayElements = OverlayElementsList(),
      _win = windowToTrackOverride {
    _lastMode = initialOverlayMode;
    GameToolsLib.checkMultiInstance<OverlayManagerBaseType>(this);
  }

  /// This is called after running the flutter app in [GameToolsLib.runLoop] (before any [GameManager.onStart] is
  /// called) for stuff that needs to be initialized before [onCreate]. Don't do any UI work with [overlayReference]
  /// in here, because the second window is not open at this point!
  @mustCallSuper
  Future<bool> init() async {
    _win ??= GameToolsLib.mainGameWindow;
    final KeyInputListener? hotkey = createOverlayToggleHotkey(); // init hotkey here already so that it always shows
    if (hotkey != null) {
      GameToolsLib.gameManager().addInputListener(hotkey);
    }
    Logger.spam("init ", runtimeType, " for ", windowToTrack.name);
    // todo: MULTI-WINDOW IN THE FUTURE: create second overlay window (could also init here instead of in onCreate)
    return true;
  }

  /// This is used in [init] to create a hotkey that can be used to switch the overlay on and off by calling
  /// [hotkeyCallbackToSwitch] as its createEventCallback! Per default this will create a shortcut with the default
  /// key "f2", but of course this can also be overridden to return null so that no hotkey may be used for toggling
  /// the overlay, etc.
  ///
  /// If you change the default key for this, you should also change the translation string in the asset files:
  /// "page.home.overlay.toggle.description"
  @protected
  KeyInputListener? createOverlayToggleHotkey() => KeyInputListener(
    configLabel: const TS("page.overlay.toggle"),
    configLabelDescription: const TS("page.home.overlay.toggle.description"),
    createEventCallback: hotkeyCallbackToSwitch,
    alwaysCreateNewEvents: true,
    defaultKey: BoardKey.f2.restrictive,
  );

  /// Used as the callback for [createOverlayToggleHotkey] to switch the mode and return null!
  @protected
  static GameEvent? hotkeyCallbackToSwitch() {
    final OverlayManagerBaseType overlayManager = OverlayManager.overlayManager();
    // todo: MULTI-WINDOW IN THE FUTURE: change to hidden instead of app open!
    if (overlayManager.overlayMode == OverlayMode.VISIBLE) {
      overlayManager.changeMode(OverlayMode.APP_OPEN);
    } else if (overlayManager.overlayMode == OverlayMode.APP_OPEN) {
      overlayManager.changeMode(OverlayMode.VISIBLE);
    }
    return null;
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
    Logger.spam("onCreate ", runtimeType, " for ", windowToTrack.name);
    _active = true;
    overlayModeNotifier.addListener(_overlayModeListener);

    // todo: MULTI-WINDOW IN THE FUTURE: maximise and hide transparent overlay window (or is it started that way?)
  }

  /// This is called once when the ui closes when the [GTOverlayState] for the [GTOverlay] widget is disposed in
  /// [GTOverlayState.dispose]!
  ///
  /// Important: you can not use the [overlayState], or [overlayContext] here and the [context] cannot be used for
  /// [BuildContext.inheritFromWidgetOfExactType] here!
  @mustCallSuper
  void onDispose(BuildContext context) {
    Logger.spam("onDispose ", runtimeType, " for ", windowToTrack.name);
    _active = false;
    overlayModeNotifier.removeListener(_overlayModeListener);
  }

  /// Is called at the start of the internal game tools lib event loop [FixedConfig.updatesPerSecond] times per second,
  /// but it won't be awaited! Use it for game specific custom updates! Important: if you use multiple longish
  /// delays inside of this, then check [GameWindow.isOpen] and [GameWindow.hasFocus] after every delay, because it
  /// might have changed in the meantime (see [onFocusChange] and [onOpenChange])!
  /// This will be called before [GameManager] and [Module].
  ///
  /// This will call [executeDelayedUpdates] periodically (check doc comments there!)
  ///
  /// Subclasses that override this should also check [active] for additional work and maybe also the [overlayMode], etc
  @mustCallSuper
  Future<void> onUpdate() async {
    await executeDelayedUpdates();
  }

  /// Is called when the open status changes for [window]. This will also be called when it opens for the first time!
  /// Don't use any delays inside of this! This will be called before [GameManager] and [Module].
  ///
  /// Remember that this will be called for every window (so overrides should also check if [window] is [windowToTrack])
  @mustCallSuper
  Future<void> onOpenChange(GameWindow window) async {
    if (window != windowToTrack) {
      return; // skip other windows
    }
    if (window.isOpen == false && overlayMode != OverlayMode.APP_OPEN) {
      changeMode(OverlayMode.APP_OPEN);
    }
  }

  /// Is called when the focus changes for [window]. This will also be called when it receives focus for the first time!
  /// Don't use any delays inside of this! This will be called before [GameManager] and [Module].
  ///
  /// Remember that this will be called for every window (so overrides should also check if [window] is [windowToTrack])
  @mustCallSuper
  Future<void> onFocusChange(GameWindow window) async {
    if (window != windowToTrack) {
      return; // skip other windows
    }
  }

  Point<int>? _lastSize;

  static const Point<int> _zero = Point<int>(0, 0);

  /// This is called when the size of the [window] changes (for example when switching to full screen). This will
  /// also be called when the window opens for the first time with the initial size of it. And also when the window
  /// closes this will be called and the [GameWindow.size] will then be null! (the overlay ui elements will be
  /// rebuild automatically on size change, because they consume the window)
  ///
  /// Remember that this will be called for every window (so overrides should also check if [window] is [windowToTrack])
  ///
  /// Important: this will also automatically toggle the [overlayMode] to [OverlayMode.HIDDEN] when the size of the
  /// window changes to zero (and then enables it when it changes back)
  @mustCallSuper
  Future<void> onWindowResize(GameWindow window) async {
    if (window != windowToTrack) {
      return; // skip other windows
    }

    if (window.size == _zero && overlayMode != OverlayMode.APP_OPEN) {
      await changeModeAsync(OverlayMode.HIDDEN);
    } else if (_lastSize == _zero && overlayMode == OverlayMode.HIDDEN) {
      await changeModeAsync(OverlayMode.VISIBLE);
    }
    _lastSize = window.size;

    if (overlayMode != OverlayMode.APP_OPEN) {
      await NativeOverlayWindow.snapOverlay(window);
    }
  }

  /// Is called after the [overlayMode] was changed with the old value being [lastMode] (null the first time!).
  ///
  /// Important: if [changedBetweenHiddenAndVisible] is true, then a change happened exactly between
  /// [OverlayMode.HIDDEN] and [OverlayMode.VISIBLE] which may happen quite often and which will not trigger
  /// [GameEvent.onOverlayModeChanged] and also not [OverlayElement.saveToStorage]!
  ///
  /// In your subclass override of this be careful what you do without checking if [changedBetweenHiddenAndVisible]
  /// is true for performance reasons!
  ///
  /// [NativeOverlayWindow.deactivateOverlay], [NativeOverlayWindow.activateOverlay] and
  /// [NativeOverlayWindow.setMouseEvents] are not awaited here (only in [changeModeAsync])
  @mustCallSuper
  @protected
  void onOverlayModeChanged(OverlayMode? lastMode, {required bool changedBetweenHiddenAndVisible}) {
    if (changedBetweenHiddenAndVisible == false) {
      final OverlayMode newMode = overlayMode;
      Logger.verbose(
        "Switched Overlay from $lastMode to $newMode with ${overlayElements.countOfElements} overlay elements",
      );
      _GameToolsLibEventLoop._runForAllEvents((GameEvent event) {
        event.onOverlayModeChanged(lastMode, newMode);
      });
      overlayElements.doForAll((OverlayElement element) => element.saveToStorage());
      if (newMode == OverlayMode.APP_OPEN) {
        // todo: MULTI-WINDOW IN THE FUTURE: might be removed and overlay is perma active!
        _pendingWindowChange = NativeOverlayWindow.deactivateOverlay();
      } else if (lastMode == OverlayMode.APP_OPEN) {
        _pendingWindowChange = NativeOverlayWindow.activateOverlay(windowToTrack, newMode);
      } else {
        // todo: MULTI-WINDOW IN THE FUTURE: this will be the only thing to apply in the future
        if (newMode == OverlayMode.VISIBLE) {
          _pendingWindowChange = NativeOverlayWindow.setMouseEvents(ignore: true);
        } else if (newMode == OverlayMode.EDIT_COMP_IMAGES || newMode == OverlayMode.EDIT_UI) {
          _pendingWindowChange = NativeOverlayWindow.setMouseEvents(ignore: false);
        } else {
          _pendingWindowChange = null;
        }
      }
    }
  }

  /// Uses [GTOverlayState.showToast] to show a message on the bottom only if the overlay is currently active, but
  /// this uses a post frame callback for the call by using [scheduleUIWork] so that it will be called after the next
  /// build!
  ///
  /// Additionally this contains a [delay] param to wait until displaying the toast message.
  ///
  /// Otherwise nothing will be shown/done! This may not be called during build (use post frame callback)!
  ///
  /// Only await this if you want to wait for the next frame to render, otherwise call this unawaited!
  Future<void> showToast(
    TranslationString message, {
    Duration duration = const Duration(seconds: 4),
    Duration delay = Duration.zero,
  }) => scheduleUIWork(
    (BuildContext? context) => overlayReference.currentState?.showToastOverlay(message, duration),
    delay,
  );

  /// This can be used to build a (for example [AlertDialog]) inside of the [buildDialog] callback which will then be
  /// displayed after the next build method by using [scheduleUIWork].
  ///
  /// If you choose a specific [t] then your dialog can use specific data in its [Navigator.pop] which will be
  /// returned here! Returns null if you return nothing or if there is no build context available.
  ///
  /// This will block until your dialog returned something (or if the context was null).
  ///
  /// [blockTouches] can be used to block touches outside of the dialog!
  Future<t?> showCustomDialog<t>(
    Widget Function(BuildContext context) buildDialog, {
    bool blockTouches = false,
  }) async {
    final Completer<t?> completer = Completer<t?>();
    Future<void> callback(BuildContext? context) async {
      if (context == null) {
        completer.complete(null);
      } else {
        final t? result = await showDialog<t>(
          context: context,
          builder: buildDialog,
          barrierDismissible: !blockTouches,
        );
        completer.complete(result);
      }
    }

    unawaited(scheduleUIWork(callback));
    return completer.future;
  }

  /// Will execute [callback] after the current frame has been rendered (so every overlay ui element should be available
  /// at that point). The inner [BuildContext] context is not null if the [overlayContext] is mounted!
  ///
  /// Important: the [callback] should only modify UI stuff and will only be awaited after its done with its work!
  /// If you have inner awaits in your callback, then you should check the mounted status of the [BuildContext]
  /// afterwards.
  ///
  /// Only await the call to this if you really want to wait until the next frame is rendered, otherwise call this
  /// unawaited!
  ///
  /// Optionally a [delay] can also be used which is awaited before scheduling the work for the next frame.
  ///
  /// Uses [_OverlayLogger] for logging!
  @override
  Future<void> scheduleUIWork(
    FutureOr<void> Function(BuildContext? context) callback, [
    Duration delay = Duration.zero,
  ]) async {
    // todo: MULTI-WINDOW IN THE FUTURE: should be executed on overlay window
    // maybe also show toast then for overlay window? (needs scaffold and cant be used on big app). check active?
    if (_win == null) {
      await _OverlayLogger().log(
        "Trying to schedule ui work while overlay manager was not initialized",
        LogLevel.WARN,
        null,
        null,
      );
      return;
    }
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    bool done = false;
    try {
      SchedulerBinding.instance.addPostFrameCallback((Duration? timestamp) {
        try {
          final BuildContext? context = overlayContext;
          dynamic result;
          if (context?.mounted ?? false) {
            result = callback(context!);
          } else {
            result = callback(null);
          }
          if (result is Future<void>) {
            result.whenComplete(() => done = true);
          } else {
            done = false;
          }
        } catch (e, s) {
          _OverlayLogger().log("Schedule ui work error:", LogLevel.WARN, e, s);
          done = true;
          rethrow; // some ui error
        }
      });
      WidgetsBinding.instance.ensureVisualUpdate(); // otherwise no frame would be rebuild
    } catch (e, s) {
      await _OverlayLogger().log("Schedule ui work error:", LogLevel.WARN, e, s);
      done = true;
      // ui is not available yet, ignore errors which only happen on startup!
    }
    while (!done) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  /// Uses [overlayReference] to get the [GTOverlay]. This is not-null some time after [onCreate] is called
  BuildContext? get overlayContext => overlayReference.currentContext;

  /// Uses [overlayReference] to get the [GTOverlay]. This is not-null some time after [onCreate] is called.
  OverlayStateType? get overlayState => overlayReference.currentState;

  /// Changes the [overlayMode] to [newOverlayMode], but does not allow changes to the same exact mode.
  /// Of course this will also trigger [onOverlayModeChanged] and rebuild!
  ///
  /// This will only work after [onCreate] and before [onDispose] and otherwise do nothing!
  ///
  /// Important: prefer to use [changeModeAsync] instead if you need to wait for the window modifications after
  /// activating/deactivating the overlay!
  ///
  /// Don't manually use [setActive], it will only be used internally automatically as being false from change mod
  /// async!
  void changeMode(OverlayMode newOverlayMode, {bool setActive = true}) {
    if (setActive == true && !_active) {
      Logger.warn("Tried to call OverlayManager.changeMode while it was not active with $newOverlayMode");
      return;
    }
    if (setActive) {
      _active = false;
    }
    if (!windowToTrack.isOpen && _lastMode == OverlayMode.APP_OPEN) {
      // todo: MULTI-WINDOW IN THE FUTURE: might change
      Logger.warn("Tried to switch to overlay mode $newOverlayMode while the window ${windowToTrack.name} was closed");
      return;
    }

    if (newOverlayMode != overlayMode) {
      overlayModeNotifier.value = newOverlayMode;
    } else {
      Logger.warn("Tried to change to the same new overlay mode $newOverlayMode");
    }
    if (setActive) {
      _active = true;
    }
  }

  /// Same as [changeMode], but also waits for the window modifications after activating/deactivating the overlay!
  @override
  Future<void> changeModeAsync(OverlayMode newOverlayMode) async {
    if (!_active) {
      Logger.warn("Tried to call OverlayManager.changeModeAsync while it was not active with $newOverlayMode");
      return;
    }
    _active = false;
    changeMode(newOverlayMode, setActive: false);
    if (_pendingWindowChange != null) {
      await _pendingWindowChange;
    }
    _active = true;
  }

  /// Helper for [_overlayModeListener]
  static OverlayMode? _lastMode;

  /// Listener for changes to [overlayMode]
  static void _overlayModeListener() {
    final OverlayMode? newValue = _instance?.overlayMode;
    final bool hiddenVisibleChange =
        (_lastMode == OverlayMode.HIDDEN && newValue == OverlayMode.VISIBLE) ||
        (_lastMode == OverlayMode.VISIBLE && newValue == OverlayMode.HIDDEN);
    _instance?.onOverlayModeChanged(_lastMode, changedBetweenHiddenAndVisible: hiddenVisibleChange);
    _lastMode = newValue;
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

  /// If the overlay is capturing mouse events. This is automatically used in [MouseInputListener].
  bool get isOverlayFocused => NativeOverlayWindow.isOverlayFocused;
}

/// Typedef for base type
typedef OverlayManagerBaseType = OverlayManager<GTOverlayState>;

/// Used in [OverlayManager.scheduleUIWork] for logging to not cause stack overflow errors by preventing ui logging!
final class _OverlayLogger extends CustomLogger {
  /// Set in constructor and used in [logLevel] and mutable!
  LogLevel logLevelOverride;

  _OverlayLogger([this.logLevelOverride = LogLevel.SPAM]) : super(sensitiveDataToRemove: <String>[]);

  @override
  void logToConsole(String logMessage) {
    debugPrint(logMessage);
  }

  @override
  void logToUi(LogMessage logMessage) {}

  @override
  LogLevel get logLevel => logLevelOverride;
}
