part of 'package:game_tools_lib/game_tools_lib.dart';

/// This is the shared base class for [KeyInputListener] and [MouseInputListener] (see docs of those for more info),
/// but not [LogInputListener]! Also look at docs of [configLabel], [createEventCallback] with [eventCreateCondition],
/// [alwaysCreateNewEvents], [defaultKey] and [currentKey].
///
/// The current hotkey can also be loaded from storage (which will also be done automatically) with [loadKey]. And
/// you can always change the hotkey with [storeKey], or reset it to default with [deleteKey].
///
/// Subclasses of this are used to add configurable input (mouse/key) listeners that add [GameEvent]'s when the input
/// was received. They can be added in the constructor of [GameToolsLib], or [GameToolsLib.addLogInputListener].
///
/// Important: these listeners only trigger once per press/click (holding down for a while and then releasing)! But
/// they already trigger when it is pressed/clicked down and not only when its up again!
///
/// This is updated automatically at the end of the event loop of [GameToolsLib]!
abstract base class BaseInputListener<DataType> {
  /// If this is empty, then this listener will not get any ui build to be able to modify it! Otherwise it should
  /// display a info label text (or translation key), but it will also be used as the database storage key (for the
  /// editable stored [_key])
  final String configLabel;

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
  /// cached and only added to the queue if its currently not in it!
  final bool alwaysCreateNewEvents;

  /// This is the default hotkey for the input listener used for the internal [_key]
  final DataType defaultKey;

  /// The current hotkey which is loaded/saved, but initially null
  DataType? _key;

  /// Stores the last internal key state queried by this
  bool _isKeyDown = false;

  /// Added to the [configLabel] internally in the storage
  static const String KEY_PREFIX = "LISTENER_";

  String get _transformedKey => "$KEY_PREFIX$configLabel";

  BaseInputListener({
    required this.configLabel,
    this.eventCreateCondition = onlyWhenMainWindowHasFocus,
    required this.createEventCallback,
    required this.alwaysCreateNewEvents,
    required this.defaultKey,
  });

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

  /// Returns the current cached (loaded/stored) hotkey [_key] after the first [_update] call if its not null.
  /// Before it always returns the [defaultKey]
  DataType get currentKey => _key ?? defaultKey;

  /// If this is modifiable in the ui
  bool get isConfigurable => configLabel.isNotEmpty;

  /// Loads the hotkey from storage and also caches it in [_key]. If its null, it returns [defaultKey].
  Future<DataType?> loadKey() async {
    if (_key != null) {
      return _key!;
    }
    final String? data = await GameToolsLib.database.readFromHive(
      key: _transformedKey,
      databaseKey: HiveDatabase.INSTANT_DATABASE,
    );
    _key = _stringToKey(data);
    if (_key != null) {
      Logger.verbose("Loaded key for $this");
    }
    return currentKey;
  }

  /// Stores the hotkey [newKey] in the storage and also overrides the cached [_key].
  Future<void> storeKey(DataType newKey) async {
    _key = newKey;
    Logger.verbose("Stored new key for $this");
    return GameToolsLib.database.writeToHive(
      key: _transformedKey,
      value: _keyToString(newKey),
      databaseKey: HiveDatabase.INSTANT_DATABASE,
    );
  }

  /// Deletes the current hotkey back to the default value and also clears the [_key]
  Future<void> deleteKey() async {
    Logger.verbose("Deleting key from $this");
    _key = null;
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

  /// Needs to be overridden in the sub classes for keyboard vs mouse and return the current state
  bool _getNewKeyState();

  /// Called periodically from the internal event loop
  Future<void> _update() async {
    _key ??= await loadKey(); // will set key to the default key
    final bool newKeyDown = _getNewKeyState();
    if (_isKeyDown == false && newKeyDown) {
      _addEvent();
    }
    _isKeyDown = newKeyDown;
  }

  static final SpamIdentifier _addSkipLog = SpamIdentifier(
    Duration(milliseconds: FixedConfig.fixedConfig.logPeriodicSpamDelayMS),
  );
}
