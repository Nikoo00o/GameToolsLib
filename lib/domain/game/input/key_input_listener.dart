part of 'package:game_tools_lib/game_tools_lib.dart';

/// You can either use this directly, or use your own subclass of this to add events on key presses!
///
/// Important: look at the docs of [BaseInputListener]! This only overrides the methods [_keyToString], [_stringToKey],
/// [_getNewKeyState].
base class KeyInputListener extends BaseInputListener<BoardKey> {
  KeyInputListener({
    required super.configLabel,
    required super.createEventCallback,
    required super.alwaysCreateNewEvents,
    required super.defaultKey,
    super.configGroupLabel,
  });

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
  bool _getNewKeyState() => InputManager.isKeyDown(currentKey);
}
