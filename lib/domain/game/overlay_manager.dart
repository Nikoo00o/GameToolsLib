part of 'package:game_tools_lib/game_tools_lib.dart';

// todo: doc comments
/// This (or sub classes of this) is the interaction point between your data code layer and a transparent overlay
/// ([GTOverlay]) on top of your window (per default the [GameToolsLib.mainGameWindow]) where you can draw ui
/// [OverlayElement]'s like for example also [CompareImage] which can be created and used anywhere! For more info
/// look at doc comments there!
///
/// The [overlayMode] can be used to access or modify the current mode (might also be used to render elements
/// conditionally)! Always use [changeMode] or [changeModeAsync] to modify the mode instead of doing it directly!
///
/// todo: reference what to override of this
base class OverlayManager<OverlayStateType extends GTOverlayState> {
  /// This is used to get the [overlayState] and [overlayContext] from the the [GTOverlay]!
  final GlobalKey<OverlayStateType> overlayReference = GlobalKey<OverlayStateType>();

  /// This is set optionally in the constructor while defaulting to [OverlayMode.APP_OPEN] and it is used to render
  /// the different overlay states depending on the mode!
  ///
  /// You can modify this directly to change the overlay mode and changes will arrive in [onOverlayModeChanged] and
  /// in [GTOverlay]! Prefer to use [changeMode], or better [changeModeAsync] instead to change the overlay mode.
  final SimpleChangeNotifier<OverlayMode> overlayMode;

  /// Contains all the cached [OverlayElement]'s (see doc comments of [OverlayElementsList] ) and can be used to
  /// add/remove elements, or modify elements, or build them!
  final OverlayElementsList overlayElements;

  /// Sub folder of [GameToolsConfig.dynamicData] where the [OverlayElement]'s are stored into simple json files!
  ///
  /// Can be overridden in sub classes.
  String get overlayElementSubFolder => "overlay";

  /// Per default always [GameToolsLib.mainGameWindow] set in [init], but can be overridden in the constructor.
  ///
  /// In overlay mode this will be the target window that determines size and position of the overlay
  GameWindow get windowToTrack => _win!;

  /// set in [init] or constructor.
  GameWindow? _win;

  /// Internal debug check between [onCreate] and [onDispose] checked in [changeMode] first!
  bool _active = false;

  /// Awaited in [changeModeAsync] if not null!
  Future<void>? _pendingWindowChange;

  /// used in [_checkWindowPosition]
  Point<int>? _lastWindowPos;

  /// The delay for the calls to [_checkMouseForClickableOverlayElements] from [onUpdate] which is a bit slower for
  /// better performance. But this can be overridden in sub classes because it might miss a fast mouse click on an
  /// [OverlayElement] with a long delay! If this returns null, then it is called every [onUpdate]!
  Duration? get clickableMouseCheckDelay => const Duration(milliseconds: 100);

  /// [windowToTrackOverride] can rarely be used to override [windowToTrack]
  OverlayManager([OverlayMode initialOverlayMode = OverlayMode.APP_OPEN, GameWindow? windowToTrackOverride])
    : overlayMode = SimpleChangeNotifier<OverlayMode>(initialOverlayMode),
      overlayElements = OverlayElementsList(),
      _win = windowToTrackOverride {
    _lastMode = initialOverlayMode;
  }

  /// This is called after running the flutter app in [GameToolsLib.runLoop] (before any [GameManager.onStart] is
  /// called) for stuff that needs to be initialized before [onCreate]. Don't do any UI work with [overlayReference]
  /// in here, because the second window is not open at this point!
  @mustCallSuper
  Future<bool> init() async {
    _win ??= GameToolsLib.mainGameWindow;
    Logger.spam("init ", runtimeType, " for ", windowToTrack.name);
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
    Logger.spam("onCreate ", runtimeType, " for ", windowToTrack.name);
    _active = true;
    overlayMode.addListener(_overlayModeListener);
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
    overlayMode.removeListener(_overlayModeListener);
  }

  /// Is called at the start of the internal game tools lib event loop [FixedConfig.updatesPerSecond] times per second,
  /// but it won't be awaited! Use it for game specific custom updates! Important: if you use multiple longish
  /// delays inside of this, then check [GameWindow.isOpen] and [GameWindow.hasFocus] after every delay, because it
  /// might have changed in the meantime (see [onFocusChange] and [onOpenChange])!
  /// This will be called before [GameManager] and [Module].
  ///
  /// Calls [_checkMouseForClickableOverlayElements] periodically with [clickableMouseCheckDelay].
  @mustCallSuper
  Future<void> onUpdate() async {
    if (clickableMouseCheckDelay != null) {
      await Utils.executePeriodicAsync(
        delay: clickableMouseCheckDelay!,
        callback: _checkMouseForClickableOverlayElements,
      );
    } else {
      await _checkMouseForClickableOverlayElements();
    }
  }

  /// Used to call [OverlayElement.onMouseLeave] in [_checkMouseForClickableOverlayElements]
  OverlayElement? _mouseFocused;

  /// This is called periodically from [onUpdate] with [clickableMouseCheckDelay] for the [OverlayElement]'s with
  /// [OverlayElement.clickable] being true (and them being [OverlayElement.visible]) to call
  /// [NativeOverlayWindow.setMouseEvents] depending on the mouse  position!
  /// Only checks when [windowToTrack.isOpen] and [overlayMode] is [OverlayMode.VISIBLE]!
  ///
  /// This also checks the [GtSettingsButton] separately! And this checks [OverlayElement.onMouseEnter] first before
  /// accepting mouse focus and then if it was true, then [OverlayElement.onMouseLeave] after the mouse left the area!
  ///
  /// And this will also call [_checkWindowPosition] first at the start if [OverlayMode.VISIBLE], but also for
  /// [OverlayMode.EDIT_UI] and [OverlayMode.EDIT_COMP_IMAGES]!
  Future<void> _checkMouseForClickableOverlayElements() async {
    if (windowToTrack.isOpen && overlayMode.value == OverlayMode.VISIBLE) {
      final bool change = await _checkWindowPosition();
      if (change) {
        return; // skip one turn if position changed
      }
      final Point<double>? mousePos = windowToTrack.windowMousePos?.toDoublePoint();
      if (mousePos != null) {
        for (final OverlayElement element in overlayElements.clickableElements) {
          if (element.visible) {
            if (element.displayDimension?.contains(mousePos) ?? false) {
              if (element.onMouseEnter(mousePos)) {
                if (_mouseFocused != element) {
                  _mouseFocused?.onMouseLeave(); // check old element
                  _mouseFocused = element;
                }
                await NativeOverlayWindow.setMouseEvents(ignore: false);
                return; // found a clickable region, so skip until next try
              }
            }
          }
        }
        if (_mouseFocused != null) {
          _mouseFocused!.onMouseLeave(); // check old element
          _mouseFocused = null;
        }
        // now also check the settings button
        if (mousePos.y <= GtSettingsButton.sizeForClicks &&
            mousePos.x >= windowToTrack.width - GtSettingsButton.sizeForClicks) {
          await NativeOverlayWindow.setMouseEvents(ignore: false); // found click region
        } else {
          await NativeOverlayWindow.setMouseEvents(ignore: true); // no click region found, so ignore
        }
      } else {
        // mouse out of window, or top bar
        await NativeOverlayWindow.setMouseEvents(ignore: true); // no click region found, so ignore
      }
    } else if (overlayMode.value == OverlayMode.EDIT_UI || overlayMode.value == OverlayMode.EDIT_COMP_IMAGES) {
      await _checkWindowPosition();
    }
  }

  /// Used in [_checkMouseForClickableOverlayElements] to reposition the overlay if the window changed. returns true
  /// if something changed
  Future<bool> _checkWindowPosition() async {
    final Point<int> pos = windowToTrack.getWindowBounds().pos;
    if (pos != _lastWindowPos) {
      _lastWindowPos = pos;
      await NativeOverlayWindow.snapOverlay(windowToTrack);
      return true;
    }
    return false;
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
    if (window.isOpen == false && overlayMode.value != OverlayMode.APP_OPEN) {
      changeMode(OverlayMode.APP_OPEN);
    }

    Logger.info("test open"); // todo: remove after min and maximize test
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
    Logger.info("test focus $window"); // todo: remove after min and maximize test
  }

  /// This is called when the size of the [window] changes (for example when switching to full screen). This will
  /// also be called when the window opens for the first time with the initial size of it. And also when the window
  /// closes this will be called and the [GameWindow.size] will then be null! (the overlay ui elements will be
  /// rebuild automatically on size change, because they consume the window)
  ///
  /// Remember that this will be called for every window (so overrides should also check if [window] is [windowToTrack])
  @mustCallSuper
  Future<void> onWindowResize(GameWindow window) async {
    if (window != windowToTrack) {
      return; // skip other windows
    }

    if (overlayMode.value != OverlayMode.APP_OPEN) {
      await NativeOverlayWindow.snapOverlay(window);
    }

    // todo: remove after min and maximize test
    if (window.size != null) {
      Logger.info("test resize ${window.size} related to bounds ${window.getWindowBounds()}");
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
      final OverlayMode newMode = overlayMode.value;
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

  /// Will execute [callback] after the current frame has been rendered (so every overlay ui element should be available
  /// at that point). The inner [BuildContext] context is not null if the [overlayContext] is mounted!
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
    try {
      SchedulerBinding.instance.addPostFrameCallback((Duration? timestamp) {
        final BuildContext? context = overlayContext;
        if (context?.mounted ?? false) {
          callback(context!);
        } else {
          callback(null);
        }
      });
    } catch (_) {
      // ui is not available yet, ignore errors which only happen on startup!
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
  void changeMode(OverlayMode newOverlayMode) {
    if (!_active) {
      Logger.warn("Tried to call OverlayManager.changeMode while it was not active with $newOverlayMode");
      return;
    }
    if (!windowToTrack.isOpen && _lastMode == OverlayMode.APP_OPEN) {
      // todo: MULTI-WINDOW IN THE FUTURE: might change
      Logger.warn("Tried to switch to overlay mode $newOverlayMode while the window ${windowToTrack.name} was closed");
      return;
    }

    if (newOverlayMode != overlayMode.value) {
      overlayMode.value = newOverlayMode;
    } else {
      Logger.warn("Tried to change to the same new overlay mode $newOverlayMode");
    }
  }

  /// Same as [changeMode], but also waits for the window modifications after activating/deactivating the overlay!
  Future<void> changeModeAsync(OverlayMode newOverlayMode) async {
    changeMode(newOverlayMode);
    if (_pendingWindowChange != null) {
      await _pendingWindowChange;
    }
  }

  /// Helper for [_overlayModeListener]
  static OverlayMode? _lastMode;

  /// Listener for changes to [overlayMode]
  static void _overlayModeListener() {
    final OverlayMode? newValue = _instance?.overlayMode.value;
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
}

/// Typedef for base type
typedef OverlayManagerBaseType = OverlayManager<GTOverlayState>;
