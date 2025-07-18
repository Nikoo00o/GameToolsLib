import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

/// Only used for testing
final class TestGameManager extends GameManager<GameToolsConfig<FixedConfig, MutableConfig>> {
  static int callCounter = 0;

  @override
  Future<void> onStart() async => callCounter++;

  @override
  Future<void> onStop() async => callCounter++;

  @override
  Future<void> onUpdate() async {}
}
