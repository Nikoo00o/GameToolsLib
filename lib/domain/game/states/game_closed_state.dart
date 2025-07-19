import 'package:game_tools_lib/game_tools_lib.dart';

/// This will always be the first and last state (on start and on finish)
final class GameClosedState extends GameState {
  @override
  Future<void> onUpdate() async {}
}
