part of 'package:game_tools_lib/game_tools_lib.dart';

/// This is the shared base class for [KeyInputListener] and [MouseInputListener] (see docs of those for more info),
/// but not [LogInputListener]! Also look at docs of [configLabel], [createEventCallback] with [eventCreateCondition],
/// [alwaysCreateNewEvents], [defaultKey] and [currentKey].
///
/// The current hotkey can also be loaded from storage (which will also be done automatically) with [loadKey]. And
/// you can always change the hotkey with [storeKey], or reset it to default with [deleteKey]. To retrieve the hotkey
/// its better to use the sync [currentKey] from the outside!
///
/// Remember that as long as no data is saved to the database, the default key will be returned.
/// And if that one is null, this hotkey is in the "not set" state. Also the data saved to the database can also be
/// null to always return the "not set state" (until delete key is called)
///
/// Subclasses of this are used to add configurable input (mouse/key) listeners that add [GameEvent]'s when the input
/// was received. They can be added in the constructor of [GameToolsLib], or [GameToolsLib.addLogInputListener].
///
/// Important: these listeners only trigger once per press/click (holding down for a while and then releasing)! But
/// they already trigger when it is pressed/clicked down and not only when its up again!
///
/// This is updated automatically at the end of the event loop of [GameToolsLib]! You can also toggle the listening
/// of this with [isActive]
abstract base class BaseInputListener<DataType> {
  /// If this is empty, then this listener will not get any ui build to be able to modify it! Otherwise it should
  /// display a info label text (or translation key), but it will also be used as the database storage key (for the
  /// editable stored [_key]). Also look at [configGroupLabel] if you want to group up some listeners. See
  /// [isConfigurable]. You can explicitly set this to empty with [TranslationString.empty] (or just use an empty
  /// string)!
  final TranslationString configLabel;

  /// Optional additional smaller text for the ui in addition to [configLabel] (null by default).
  final TranslationString? configLabelDescription;

  /// This will be called before to only execute [createEventCallback] if this returns true!
  /// The default is [onlyWhenMainWindowHasFocus] to only create events when the main window is open and has focus!
  final bool Function() eventCreateCondition;

  /// This is the function called internally when this listener is activated to create a new object of any
  /// [GameEvent] subclass (which will then be added to the internal event queue) only if [eventCreateCondition]
  /// returns true!
  final GameEvent Function() createEventCallback;

  /// If [alwaysCreateNewEvents] is false, then this will cache the [createEventCallback]
  GameEvent? _cachedEvent;

  /// If this is true, then [createEventCallback] will be called each time this listener is activated to create a new
  /// event instance which will be added to the internal event queue if its not a subclass of [GameEvent] that has
  /// the operator== overridden for equality instead of identity! If this is false, only one event object will be
  /// cached and only added to the queue if its currently not in it! (because per default events are only added when
  /// they are not already contained and they are compared per pointer identity)
  final bool alwaysCreateNewEvents;

  /// This is the default hotkey for the input listener used for the internal [_key] if its not saved in storage.
  /// Its used until the first [storeKey] (which may of course also be called in an earlier execution and then loaded
  /// in [loadKey]) or again after [deleteKey]. Remember storing a key with [null] will also prevent the default from
  /// being returned
  final DataType? defaultKey;

  /// If the [configLabel] is not empty, then this may also be set to group up multiple input listeners in
  /// config groups by matching the group labels! In the config menu the labels will also be translated.
  /// But this is optional and null by default!
  final TranslationString? configGroupLabel;

  /// This can be toggled to control if this listener should currently be listening and adding events, or not, per
  /// default it's true!
  bool isActive;

  /// The current hotkey which is loaded/saved in storage, but initially null (and default is used before)
  DataType? _key;

  /// Initially null until the first [_update] call from the event loop. returns if the key is saved on storage.
  bool? _existsOnStorage;

  /// Stores the last internal key state queried by this
  bool _isKeyDown = false;

  /// used after key change in [_resetLoopState] and [_update]
  static final Duration _delay = Duration(milliseconds: (1000 / FixedConfig.fixedConfig.updatesPerSecond * 5).toInt());

  /// used after key change in [_resetLoopState] and [_update]
  static bool _canUpdate = true;

  /// Added to the [configLabel] internally in the storage
  static const String KEY_PREFIX = "LISTENER_";

  String get _transformedKey => "$KEY_PREFIX${configLabel.identifier}";

  BaseInputListener({
    required this.configLabel,
    this.configLabelDescription,
    this.eventCreateCondition = onlyWhenMainWindowHasFocus,
    required this.createEventCallback,
    required this.alwaysCreateNewEvents,
    required this.defaultKey,
    this.configGroupLabel,
    required this.isActive,
  }) {
    if (isConfigurable == false && configGroupLabel != null) {
      throw ConfigException(
        message: "Used config group label $configGroupLabel when configLabel was null for default key $defaultKey",
      );
    }
  }

  void _addEvent() {
    if (eventCreateCondition.call()) {
      if (alwaysCreateNewEvents) {
        GameToolsLib.addEvent(createEventCallback.call());
      } else {
        _cachedEvent ??= createEventCallback.call();
        GameToolsLib.addEvent(_cachedEvent!);
      }
    } else {
      Logger.spamPeriodic(_addSkipLog, "skipped adding new event from ", this);
    }
  }

  /// If this has something saved in the database, it returns that stored data [_key] (null can also be saved to always
  /// return a "not set" state)
  ///
  /// Otherwise it returns the [defaultKey] (which can also be null and in the "not set" state!)
  ///
  /// But in the [_getNewKeyState] in subclasses during the event update loop this will never be null (because the
  /// method would not be called in that case)! Important: before the first event update loop, this will always
  /// return the [defaultKey] if accessed!
  DataType? get currentKey {
    if (_existsOnStorage == true) {
      return _key;
    }
    return defaultKey;
  }

  /// If this is modifiable in the ui
  bool get isConfigurable => configLabel.identifier.isNotEmpty;

  /// This is called internally in [_update] only once at the first event loop run, so from the outside the sync
  /// [currentKey] access can always be used!
  ///
  /// This it loads the key from storage and caches it if [_existsOnStorage] is true and then it just returns
  /// [currentKey]. And it also sets the exists on storage flag internally
  Future<DataType?> _loadKey() async {
    if (_key != null) {
      Logger.warn("The key of $this was already set which should not happen");
    }
    _existsOnStorage = await GameToolsLib.database.existsInHive(
      key: _transformedKey,
      databaseKey: HiveDatabase.INSTANT_DATABASE,
    );
    if (_existsOnStorage!) {
      final String? data = await GameToolsLib.database.readFromHive(
        key: _transformedKey,
        databaseKey: HiveDatabase.INSTANT_DATABASE,
      );
      _key = _stringToKey(data);
      Logger.verbose("Loaded hotkey for the first time from storage: $this");
    } else {
      Logger.verbose("Loaded hotkey for the first time from default: $this ");
    }
    return currentKey;
  }

  /// Stores the hotkey [newKey] in the storage and also overrides the cached [_key].
  ///
  /// If [newKey] is null, then this will mark this hotkey as being unset / not set and after this [currentKey] will
  /// return null as well!
  Future<void> storeKey(DataType? newKey) async {
    Logger.verbose("Storing new hotkey $newKey for $this");
    _key = newKey;
    _existsOnStorage = true;
    _resetLoopState();
    return GameToolsLib.database.writeToHive(
      key: _transformedKey,
      value: _keyToString(newKey),
      databaseKey: HiveDatabase.INSTANT_DATABASE,
    );
  }

  /// Deletes the current hotkey back to the default value and also clears the [_key].
  /// So after this [currentKey] will return [defaultKey]
  Future<void> deleteKey() async {
    final DataType? oldKey = _key;
    _key = null;
    _existsOnStorage = false;
    Logger.verbose("Deleted old hotkey $oldKey from $this");
    _resetLoopState();
    return GameToolsLib.database.deleteFromHive(
      key: _transformedKey,
      databaseKey: HiveDatabase.INSTANT_DATABASE,
    );
  }

  @override
  String toString() {
    return "$runtimeType($configLabel: $currentKey)";
  }

  static bool onlyWhenMainWindowHasFocus() => GameToolsLib.mainGameWindow.hasFocus;

  /// Needs to be overridden in the sub classes for keyboard vs mouse to store the [DataType]
  String? _keyToString(DataType? data);

  /// Needs to be overridden in the sub classes for keyboard vs mouse to load the [DataType]
  DataType? _stringToKey(String? str);

  /// Needs to be overridden in the sub classes for keyboard vs mouse and return the current state.
  ///
  /// Remember the [currentKey] will never be null if this is called, because it will not be called if its null!
  bool _getNewKeyState();

  /// Called in [storeKey] and [deleteKey] automatically to prevent other listeners from firing their events when
  /// keys are modified
  static void _resetLoopState() {
    if (_canUpdate) {
      _canUpdate = false;
      Future<void>.delayed(_delay).then((_) => _canUpdate = true);
    }
  }

  /// Called periodically from the internal event loop
  Future<void> _update() async {
    if (isActive == false) {
      if (_isKeyDown) {
        _isKeyDown = false;
      }
      return; // don't update if not active!
    }
    if (_existsOnStorage == null) {
      await _loadKey();
    }
    if (currentKey != null && _canUpdate) {
      final bool newKeyDown = _getNewKeyState();
      if (_isKeyDown == false && newKeyDown) {
        _addEvent();
      }
      _isKeyDown = newKeyDown;
    } else {
      _isKeyDown = false;
    }
  }

  static final SpamIdentifier _addSkipLog = SpamIdentifier(
    Duration(milliseconds: FixedConfig.fixedConfig.logPeriodicSpamDelayMS),
  );
}
