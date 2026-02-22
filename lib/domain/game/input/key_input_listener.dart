part of 'package:game_tools_lib/game_tools_lib.dart';

/// You can either use this directly, or use your own subclass of this to add events on key presses!
///
/// Important: look at the docs of [BaseInputListener]! This only overrides the methods [_keyToString], [_stringToKey],
/// [_getNewKeyState].
///
/// This also overrides [_addEvent] to check for [resetKeysAfter]!
base class KeyInputListener extends BaseInputListener<BoardKey> {
  /// If this is true [per default] it will call [InputManager.resetKeys] before creating the event, or
  /// performing the action to reset any modifier keys that would have been pressed for this hotkey to prevent side
  /// effects.
  final bool resetKeysAfter;

  /// Optionally you can also use the [KeyInputListener.instant] constructor instead!
  KeyInputListener({
    required super.configLabel,
    super.configLabelDescription,
    super.eventCreateCondition,
    required super.createEventCallback,
    required super.alwaysCreateNewEvents,
    required super.defaultKey,
    super.configGroupLabel,
    super.isActive = true,
    this.resetKeysAfter = true,
  });

  /// Here there is no [GameEvent] to be created and instead [quickAction] will be called which should only be used for
  /// very quick non-async actions instead of using [GameEvent] with [GameEventPriority.INSTANT]!
  KeyInputListener.instant({
    required super.configLabel,
    super.configLabelDescription,
    super.eventCreateCondition,
    required void Function() quickAction,
    required super.defaultKey,
    super.configGroupLabel,
    super.isActive = true,
    this.resetKeysAfter = true,
  }) : super(
         createEventCallback: () {
           Logger.spamPeriodic(_instantLog, "KeyInputListener quick action called for ", configLabel);
           quickAction.call();
           return null;
         },
         alwaysCreateNewEvents: true,
       );

  static final SpamIdentifier _instantLog = SpamIdentifier();

  @override
  String? _keyToString(BoardKey? data) {
    if (data == null) {
      return null;
    }
    return jsonEncode(data.toJson());
  }

  @override
  BoardKey? _stringToKey(String? str) {
    if (str == null) {
      return null;
    }
    final Map<String, dynamic>? json = jsonDecode(str) as Map<String, dynamic>?;
    if (json == null) {
      return null;
    }
    return BoardKey.fromJson(json);
  }

  @override
  Future<void> _addEvent() async {
    if (resetKeysAfter) {
      InputManager.resetKeys(currentKey!);
    }
    await super._addEvent();
  }

  @override
  Future<int> _getNewKeyState() => InputIsolate.keyClicked(uniqueId, currentKey!);

  @override
  bool isDown() => currentKey != null && InputManager.isKeyDown(currentKey!);
}
