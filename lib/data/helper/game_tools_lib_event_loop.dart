part of 'package:game_tools_lib/game_tools_lib.dart';

/// Helper class that contains everything related to the event loop of the game tools lib as only static methods
mixin _GameToolsLibEventLoop on _GameToolsLibHelper {
  static bool _loopRunning = false;
  static Future<bool>? _loopResult;

  /// is unawaited in [GameToolsLib.runLoop]
  static Future<void> _startLoop(int updatesPerSecond) async {
    if (_loopRunning == false) {
      _loopRunning = true;
      _loopResult = _loopInternal(updatesPerSecond);
      Logger.spam("Started GameToolsLib event loop");
    } else {
      Logger.warn("Could not start GameToolsLib event loop");
    }
  }

  /// Is awaited in [GameToolsLib.close] to wait for the loop to stop (which was started with [GameToolsLib.runLoop])
  static Future<void> _stopLoop() async {
    if (_loopRunning) {
      _loopRunning = false;
      Logger.spam("Stopping GameToolsLib event loop...");
      await _loopResult;
    } else {
      Logger.warn("Could not stop GameToolsLib event loop");
    }
  }

  static Future<bool> _loopInternal(int updatesPerSecond) async {
    final int timePerLoopInMs = (1000.0 / updatesPerSecond).round();
    int loopStartTime = DateTime.now().millisecondsSinceEpoch;
    while (_loopRunning) {
      try {
        await _loopStep();
      } catch (e, s) {
        Logger.error("Error Game Tools Lib Loop: ", e, s);
      }
      final int loopEndTime = DateTime.now().millisecondsSinceEpoch;
      final int timeSpent = loopEndTime - loopStartTime;
      final int sleepTime = max(timePerLoopInMs - timeSpent, 1);
      loopStartTime = loopEndTime + sleepTime;
      await Future<void>.delayed(Duration(milliseconds: sleepTime));
    }
    return true;
  }

  static Future<void> _loopStep() async {

  }
}
