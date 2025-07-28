part of 'package:game_tools_lib/game_tools_lib.dart';

/// You can either use this directly, or use your own subclass of this to add events on mouse clicks!
///
/// Important: look at the docs of [BaseInputListener]! This only overrides the methods [_keyToString], [_stringToKey],
/// [_getNewKeyState].
base class MouseInputListener extends BaseInputListener<MouseKey> {
  MouseInputListener({
    required super.configLabel,
    required super.createEventCallback,
    required super.alwaysCreateNewEvents,
    required super.defaultKey,
    super.configGroupLabel,
  });

  @override
  String? _keyToString(MouseKey? data) => data?.toString();

  @override
  MouseKey? _stringToKey(String? str) => MouseKey.fromString(str);

  @override
  bool _getNewKeyState() => InputManager.isMouseDown(currentKey);
}
