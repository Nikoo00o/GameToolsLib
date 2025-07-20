import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_game_manager.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

/// Example for [ExampleGameManager]
final class ExampleState extends GameState {
  int startStopCounter = 0;
  int updateCounter = 0;

  @override
  Future<void> onStart(GameState oldState) async => startStopCounter += 1;

  @override
  Future<void> onStop(GameState newState) async => startStopCounter -= 2;

  @override
  Future<void> onOpenChange(GameWindow window) async => updateCounter += 100;

  @override
  Future<void> onFocusChange(GameWindow window) async => updateCounter += 1000;

  @override
  Future<void> onUpdate() async => updateCounter++;
}
