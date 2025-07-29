import 'package:game_tools_lib/core/enums/event/game_event_group.dart';
import 'package:game_tools_lib/core/enums/event/game_event_priority.dart';
import 'package:game_tools_lib/core/enums/event/game_event_status.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_game_manager.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

/// Example for [ExampleGameManager]
final class ExampleEvent extends GameEvent {
  int startStopCounter = 0;
  int updateCounter = 0;

  final bool isInstant;

  /// Optionally used for testing to do some custom work always in step 1 (most of the times this is null)
  Future<void> Function()? additionalWorkInStep1;

  ExampleEvent({required this.isInstant, super.groups = GameEventGroup.no_group, this.additionalWorkInStep1})
    : super(priority: isInstant ? GameEventPriority.INSTANT : GameEventPriority.LAST);

  @override
  Future<void> onStart() async => startStopCounter += 1;

  @override
  Future<void> onStop() async => startStopCounter -= 2;

  @override
  Future<void> onOpenChange(GameWindow window) async => updateCounter += 100;

  @override
  Future<void> onFocusChange(GameWindow window) async => updateCounter += 1000;

  @override
  Future<void> onStateChange(GameState oldState, GameState newState) async => updateCounter += 1000;

  @override
  Future<(GameEventStatus, Duration)> onStep1() async {
    updateCounter++;
    await additionalWorkInStep1?.call();
    if (isInstant) {
      return (GameEventStatus.DONE, Duration.zero);
    } else {
      final bool someCheckBefore = checkCorrectState<GameState>();
      if (someCheckBefore) {
        // requires focus and open window! do something....
      }
      if (updateCounter >= 11) {
        return (GameEventStatus.DONE, const Duration(milliseconds: 45));
      } else {
        return (GameEventStatus.NEXT_STEP, const Duration(milliseconds: 45));
      }
    }
  }

  @override
  Future<(GameEventStatus, Duration)> onStep2() async {
    updateCounter += 10;
    return (GameEventStatus.PREV_STEP, const Duration(milliseconds: 45));
  }
}
