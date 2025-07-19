import 'package:game_tools_lib/game_tools_lib.dart' show GameEvent;

/// This is used to control which step should be executed in [GameEvent] by the event loop
enum GameEventStatus {
  /// This same step callback will still be called in the next loop
  SAME_STEP,
  /// The next step callback will be called in the next loop (out of bounds will delete the event)
  NEXT_STEP,
  /// The previous step callback will be called in the next loop (out of bounds will delete the event)
  PREV_STEP,
  /// No more step callbacks will be called and this event is removed
  DONE;

  @override
  String toString() => name;

  factory GameEventStatus.fromString(String data) {
    return values.firstWhere((GameEventStatus element) => element.name == data);
  }
}