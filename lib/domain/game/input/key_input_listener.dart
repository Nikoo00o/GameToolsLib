part of 'package:game_tools_lib/game_tools_lib.dart';

/// You can either use this directly, or use your own subclass of this to add events on key presses!
///
/// Important: look at the docs of [BaseInputListener]! This only overrides the methods [_keyToString], [_stringToKey],
/// [_getNewKeyState].
base class KeyInputListener extends BaseInputListener<BoardKey> {
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
  bool _getNewKeyState() => InputManager.isKeyDown(currentKey!);
}
