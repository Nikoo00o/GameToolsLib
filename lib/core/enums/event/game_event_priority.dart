import 'package:game_tools_lib/game_tools_lib.dart' show GameEvent;

/// Used when adding [GameEvent]s to control how and when they are executed
enum GameEventPriority {
  /// The event will be instantly executed unawaited
  INSTANT,
  /// The event will be added to the beginning of the event queue and executed later
  FIRST,
  /// The event will be added to the end of the event queue and executed later
  LAST;

  @override
  String toString() => name;

  factory GameEventPriority.fromString(String data) {
    return values.firstWhere((GameEventPriority element) => element.name == data);
  }
}
