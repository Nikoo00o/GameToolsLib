part of 'package:game_tools_lib/game_tools_lib.dart';

/// You can either use this directly, or use your own subclass of this to add events on mouse clicks!
///
/// Important: look at the docs of [BaseInputListener]! This only overrides the methods [_keyToString], [_stringToKey],
/// [_getNewKeyState].
base class MouseInputListener extends BaseInputListener<MouseKey> {
  /// Optionally you can also use the [MouseInputListener.instant] constructor instead!
  MouseInputListener({
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
  MouseInputListener.instant({
    required super.configLabel,
    super.configLabelDescription,
    super.eventCreateCondition,
    required void Function() quickAction,
    required super.defaultKey,
    super.configGroupLabel,
    super.isActive = true,
  }) : super(
    createEventCallback: () {
      Logger.spamPeriodic(_instantLog, "MouseInputListener quick action called for ", configLabel);
      quickAction.call();
      return null;
    },
    alwaysCreateNewEvents: true,
  );

  static final SpamIdentifier _instantLog = SpamIdentifier();

  @override
  String? _keyToString(MouseKey? data) => data?.toString();

  @override
  MouseKey? _stringToKey(String? str) => MouseKey.fromString(str);

  @override
  bool _getNewKeyState() => InputManager.isMouseDown(currentKey!);
}
