part of 'package:game_tools_lib/game_tools_lib.dart';

/// Helper class that contains everything related to the event loop of the game tools lib as only static methods
mixin _GameToolsLibEventLoop on _GameToolsLibHelper {
  static bool _loopRunning = false;
  static Future<bool>? _loopResult;
  static final List<GameEvent> _eventQueue = <GameEvent>[];
  static final List<GameEvent> _instantEvents = <GameEvent>[];
  static GameState? _currentState;
  static Future<void>? _managerUpdate;
  static Future<void>? _eventUpdates;
  static final SpamIdentifier _eventLog = SpamIdentifier();
  // ignore: unused_field
  static final SpamIdentifier _loopLog = SpamIdentifier();

  /// is awaited in [GameToolsLib.runLoop]
  static Future<void> _startLoop(int updatesPerSecond) async {
    if (_loopRunning == false) {
      _loopRunning = true;
      Logger.spam("Started GameToolsLib event loop");
      _loopResult = _loopInternal(updatesPerSecond);
      await _loopResult;
    } else {
      Logger.warn("Could not start GameToolsLib event loop");
    }
  }

  /// Is awaited in [GameToolsLib.close] to wait for the loop to stop (which was started with [GameToolsLib.runLoop]).
  /// Also clears the events and calls onStop for them
  static Future<void> _stopLoop() async {
    if (_loopRunning) {
      _loopRunning = false;
      Logger.spam("Stopping GameToolsLib event loop...");
      await _loopResult;
      await _GameToolsLibEventLoop._runForAllEventsAsync((GameEvent event) async {
        await event.onStop();
      });
      _instantEvents.clear();
      _eventQueue.clear();
    } else {
      await StartupLogger().log("GameToolsLib event loop wasn't running while closing", LogLevel.WARN, null, null);
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
      // Logger.spamPeriodic(_loopLog, "Loop step at ", loopEndTime, " awaiting ", sleepTime);
      await Utils.delayMS(sleepTime);
    }
    return true;
  }

  static Future<void> _updateOpen(GameWindow window) async {
    await GameManager._instance?.onOpenChange(window);
    await _currentState?.onOpenChange(window);
    for (int i = 0; i < _instantEvents.length; ++i) {
      // some might be skipped if added/removed while this is running
      await _instantEvents[i].onOpenChange(window);
    }
    for (int i = 0; i < _eventQueue.length; ++i) {
      // some might be skipped if added/removed while this is running
      await _eventQueue[i].onOpenChange(window);
    }
  }

  static Future<void> _updateFocus(GameWindow window) async {
    await GameManager._instance?.onFocusChange(window);
    await _currentState?.onFocusChange(window);
    for (int i = 0; i < _instantEvents.length; ++i) {
      // some might be skipped if added/removed while this is running
      await _instantEvents[i].onFocusChange(window);
    }
    for (int i = 0; i < _eventQueue.length; ++i) {
      // some might be skipped if added/removed while this is running
      await _eventQueue[i].onFocusChange(window);
    }
  }

  /// This is not awaited
  static Future<void> _updateManagerAndState() async {
    try {
      await GameManager._instance?.onUpdate();
      await Utils.delayMS(1); // needed so that other async tasks may be processed in the meantime
      await _currentState?.onUpdate();
      await Utils.delayMS(1); // needed so that other async tasks may be processed in the meantime
    } catch (e, s) {
      Logger.error("Error Game Tools Lib Updating Manager And State: ", e, s);
    }
  }

  /// This is not awaited
  static Future<void> _updateEvents() async {
    try {
      final int size = _eventQueue.length;
      if (size >= 3) {
        for (int i = 0; i < _eventQueue.length; ++i) {
          // process events in order by awaiting them. some might be skipped if added/removed while this is running
          if (await _eventQueue[i]._onLoop()) {
            --i; // event was removed
          }
          if (i == size ~/ 2) {
            await Utils.delayMS(1); // needed so that other async tasks may be processed in the meantime
          }
        }
      } else {
        for (int i = 0; i < _eventQueue.length; ++i) {
          if (await _eventQueue[i]._onLoop()) {
            --i; // same as above, but without delay in between
          }
        }
      }
      await Utils.delayMS(1); // needed so that other async tasks may be processed in the meantime
    } catch (e, s) {
      Logger.error("Error Game Tools Lib Updating Events: ", e, s);
    }
  }

  /// this is awaited
  static Future<void> _updateListeners() async {
    for (final BaseInputListener<dynamic> listener
        in GameManager._instance?._inputListeners ?? <BaseInputListener<dynamic>>[]) {
      await listener._update();
    }
    await Utils.delayMS(1);
    await GameLogWatcher._instance!._fetchNewLines();
  }

  static Future<void> _loopStep() async {
    for (final GameWindow window in GameToolsLib.gameWindows) {
      if (window.updateOpen()) {
        Logger.verbose("Open status change: $window");
        await _updateOpen(window);
      }
      await Utils.delayMS(1); // needed so that other async tasks may be processed in the meantime
      if (window.updateFocus()) {
        Logger.verbose("Focus status change: $window");
        await _updateFocus(window);
      }
    }
    _managerUpdate ??= _updateManagerAndState().whenComplete(() => _managerUpdate = null); // not awaited
    _eventUpdates ??= _updateEvents().whenComplete(() => _eventUpdates = null); // not awaited
    await _updateListeners(); // is awaited
  }

  static void _addEventInternal(GameEvent event) {
    switch (event.priority) {
      case GameEventPriority.INSTANT:
        _instantEvents.add(event);
        unawaited(event._onLoop()); // execute instant events unawaited directly
        return;
      case GameEventPriority.FIRST:
        if (_eventQueue.contains(event) == false) {
          _eventQueue.insert(0, event);
          Logger.spamPeriodic(_eventLog, "added event ", event);
          return;
        }
      case GameEventPriority.LAST:
        if (_eventQueue.contains(event) == false) {
          _eventQueue.add(event);
          Logger.spamPeriodic(_eventLog, "added event ", event);
          return;
        }
    }
    Logger.warn("Could not add event $event, because it was already contained");
  }

  static Future<void> _removeEventInternal(GameEvent event) async {
    if (event.priority == GameEventPriority.INSTANT) {
      _instantEvents.remove(event);
    } else {
      _eventQueue.remove(event);
    }
    Logger.spamPeriodic(_eventLog, "calling onStop and removed event ", event);
    await event.onStop();
  }

  /// Will be run for all events in the queue, but also all instant events
  static void _runForAllEvents(void Function(GameEvent) callback) {
    _instantEvents.forEach(callback);
    _eventQueue.forEach(callback);
  }

  /// Will be run for all events in the queue, but also all instant events
  static Future<void> _runForAllEventsAsync(Future<void> Function(GameEvent) callback) async {
    for (int i = 0; i < _instantEvents.length; ++i) {
      await callback(_instantEvents[i]);
    }
    for (int i = 0; i < _eventQueue.length; ++i) {
      await callback(_eventQueue[i]);
    }
  }
}
