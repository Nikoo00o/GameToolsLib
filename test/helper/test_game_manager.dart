import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

/// Only used for testing when the default config is needed and not the example config!
final class TestGameManager extends GameManager<GameToolsConfigBaseType> {
  static int callCounter = 0;

  TestGameManager() : super(inputListeners: null);

  @override
  Future<void> onStart() async => callCounter++;

  @override
  Future<void> onStop() async => callCounter++;

  @override
  Future<void> onUpdate() async {}

  @override
  Future<void> onFocusChange(GameWindow window) async {}

  @override
  Future<void> onOpenChange(GameWindow window) async {}

  @override
  Future<void> onStateChange(GameState oldState, GameState newState) async {}
}
