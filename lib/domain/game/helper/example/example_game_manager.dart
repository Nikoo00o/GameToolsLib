import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_config.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

/// Example that uses [ExampleGameToolsConfig]
final class ExampleGameManager extends GameManager<ExampleGameToolsConfig> {
  int startStopCounter = 0;
  int updateCounter = 0;

  ExampleGameManager({required super.inputListeners});

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
  Future<void> onUpdate() async => updateCounter++;
}
