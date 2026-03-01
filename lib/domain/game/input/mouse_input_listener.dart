part of 'package:game_tools_lib/game_tools_lib.dart';

/// You can either use this directly, or use your own subclass of this to add events on mouse clicks!
///
/// Important: look at the docs of [BaseInputListener]! This only overrides the methods [_keyToString], [_stringToKey],
/// [_getNewKeyState].
///
/// Also important: this is also affected by [OverlayManager.isOverlayFocused] and will never return true that the
/// key is down in that case if the overlay is focused!!
///
/// Also read through [delayedFocusCondition] for clicking back into the window after tabbing out!
base class MouseInputListener extends BaseInputListener<MouseKey> {
  /// Optionally you can also use the [MouseInputListener.instant] constructor instead!
  MouseInputListener({
    required super.configLabel,
    super.configLabelDescription,
    super.eventCreateCondition = delayedFocusConditionMainWindow,
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
    super.eventCreateCondition = delayedFocusConditionMainWindow,
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

  /// This will wait 250 milliseconds and then update and check the focus of the [gameWindow] again if it did not
  /// have focus before discarding the event. The reason is that when tabbing out and then clicking on the main
  /// window again, it would otherwise not receive focus fast enough and discard the click which may be very bad for
  /// [MouseKey.LEFT] or [MouseKey.RIGHT] clicks! So always use this instead of just checking the focus of the window
  /// normally! For usage, see [delayedFocusConditionMainWindow] for example which is the default.
  static Future<bool> delayedFocusCondition(GameWindow gameWindow) async {
    if (!gameWindow.hasFocus) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return gameWindow.updateAndGetFocus();
    } else {
      return true;
    }
  }

  /// Same as [delayedFocusCondition], but with [GameToolsLib.mainGameWindow]
  static Future<bool> delayedFocusConditionMainWindow() => delayedFocusCondition(GameToolsLib.mainGameWindow);

  static final SpamIdentifier _instantLog = SpamIdentifier();

  @override
  String? _keyToString(MouseKey? data) => data?.toString();

  @override
  MouseKey? _stringToKey(String? str) => MouseKey.fromString(str);

  @override
  bool updateChecks() {
    if (super.updateChecks() == false) {
      return false;
    }
    try {
      if (OverlayManager.overlayManager().isOverlayFocused) return false;
    } catch (_) {}
    return true;
  }

  @override
  Future<int> _getNewKeyState() => InputIsolate.mouseClicked(uniqueId, currentKey!);

  @override
  bool isDown() => currentKey != null && InputManager.isMouseDown(currentKey!);

  @override
  Future<void> pressManually() async {
    if (currentKey != null) {
      await InputManager.mouseClick(key: currentKey!, delayBeforeAndBetweenInMS: null);
    }
  }
}
