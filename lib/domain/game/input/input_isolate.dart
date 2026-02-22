import 'dart:async';
import 'dart:isolate';

import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/enums/input/input_enums.dart';
import 'package:game_tools_lib/data/native/native_window.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

// ignore_for_file: avoid_print

/// [GameToolsLib] will automatically call [createIsolate] and [destroyIsolate] and then [keyClicked] and [mouseClicked]
/// and finally [ignoreClicks] will be used by [BaseInputListener]s!
///
/// This will run twice as fast as [FixedConfig.updatesPerSecond]
abstract final class InputIsolate {
  /// the unique ids are mapped to InputInfo on the isolate on how many times it was clicked since last time
  static final Map<int, _InputInfo> _inputInfos = <int, _InputInfo>{};

  /// keys are either [BoardKey] or [MouseKey]! and the value is if the key is currently down or not
  static final Map<dynamic, bool> _inputStates = <dynamic, bool>{};

  /// to send data from main thread
  static SendPort? _sendToIsolate;

  /// set in [createIsolate] from main thread
  static bool _initializing = false;

  /// the thread from main thread
  static Isolate? _isolate;

  /// used when polling from main. only 1 request at a time for individual listeners possible! (will not cache
  /// multiple, but the thread should run faster than main). key is id, value is amount clicked
  static final Map<int, Completer<int>> _activeRequests = <int, Completer<int>>{};

  /// used on isolate for any input to return how often it was clicked since last call. Called from [keyClicked] and
  /// [mouseClicked]
  static int _getAndResetInput(int id, dynamic key) {
    final _InputInfo? info = _inputInfos[id];
    if (info == null) {
      _inputInfos[id] = _InputInfo(key: key);
      if (_inputStates.containsKey(key) == false) {
        _inputStates[key] = false;
      }
      return 0;
    } else {
      if (info.key != key) {
        _cleanupKeyState(info.key); // remove old key for performance after the listener changed it
        info.key = key;
        if (_inputStates.containsKey(key) == false) {
          _inputStates[key] = false;
        }
      }
      final int clicks = info.resetAndGet();
      return clicks;
    }
  }

  /// used for performance reasons. only removed if no longer used (if only used by 1 input info which will be deleted)
  static void _cleanupKeyState(dynamic key) {
    final int keyUsedAmount = _inputInfos.values.where((_InputInfo info) => info.key == key).length;
    if (keyUsedAmount == 1) {
      _inputStates.remove(key);
    }
  }

  /// called from [ignoreClicks] to delete an input info
  static void _clearInput(int id) {
    final _InputInfo? info = _inputInfos[id];
    if (info != null) {
      _cleanupKeyState(info.key);
      _inputInfos.remove(id);
    }
  }

  /// isolate thread loop
  static Future<void> _startRemoteIsolate((SendPort port, Duration delay) pair) async {
    final (SendPort port, Duration delay) = pair;
    final ReceivePort receivePort = ReceivePort();
    port.send(receivePort.sendPort);
    receivePort.listen((dynamic message) async {
      if (message is (int, BoardKey)) {
        final (int id, BoardKey key) = message;
        port.send((id, _getAndResetInput(id, key)));
      } else if (message is (int, MouseKey)) {
        final (int id, MouseKey key) = message;
        port.send((id, _getAndResetInput(id, key)));
      } else if (message is int) {
        _clearInput(message);
      } else {
        print("ERROR: Input Isolate received invalid data $message");
      }
    });

    try {
      NativeWindow.clearNativeWindowInstance(createNewWindow: true);
    } catch (e, s) {
      print("ERROR: Input Isolate could not create native window: $e $s");
      return;
    }
    while (true) {
      try {
        for (final dynamic key in _inputStates.keys) {
          final bool lastState = _inputStates[key] ?? false;
          final bool newState = _inputStates[key] = _checkInputDown(key);
          final bool clicked = newState && !lastState;
          if (clicked) {
            final Iterable<_InputInfo> infos = _inputInfos.values.where((_InputInfo info) => info.key == key);
            for (final _InputInfo info in infos) {
              info.click();
            }
          }
        }
      } catch (_) {
        // ignored in thread, should not contain interruption exception on kill?
      }
      await Future<void>.delayed(delay);
    }
  }

  /// Only used in [_startRemoteIsolate]
  static bool _checkInputDown(dynamic key) {
    if (key is BoardKey) {
      return InputManager.isKeyDown(key);
    } else if (key is MouseKey) {
      return InputManager.isMouseDown(key);
    }
    print("ERROR: Input Isolate checked input for wrong type: $key");
    return false;
  }

  /// This should be used to start the isolate (will be done automatically in [GameToolsLib.initGameToolsLib] )
  static Future<void> createIsolate() async {
    if (!_initializing) {
      _initializing = true;
      final RawReceivePort initPort = RawReceivePort();
      final Completer<(ReceivePort, SendPort)> connection = Completer<(ReceivePort, SendPort)>.sync();
      initPort.handler = (dynamic initialMessage) {
        final SendPort commandPort = initialMessage as SendPort;
        connection.complete((ReceivePort.fromRawReceivePort(initPort), commandPort));
      };
      try {
        final Duration sleep = Duration(milliseconds: 1000 ~/ (FixedConfig.fixedConfig.updatesPerSecond * 2));
        await Isolate.spawn(_startRemoteIsolate, (initPort.sendPort, sleep));
      } on Object {
        initPort.close();
        rethrow;
      }
      final (ReceivePort receivePort, SendPort sendPort) = await connection.future;
      _sendToIsolate = sendPort;
      receivePort.listen(_handleResponsesFromIsolate);
      Logger.verbose("Creating input isolate");
    } else {
      Logger.spam("tried to create input isolate multiple times");
    }
  }

  /// Can be used to close the isolate if its running (will be done automatically in [GameToolsLib.initGameToolsLib] )
  static Future<void> destroyIsolate() async {
    if (_isolate != null) {
      _sendToIsolate = null;
      _isolate!.kill();
      _initializing = false;
      _isolate = null;
      Logger.verbose("Destroyed input isolate");
    }
  }

  static void _handleResponsesFromIsolate(dynamic message) {
    if (message is (int, int)) {
      final (int id, int response) = message;
      final Completer<int> completer = _activeRequests.remove(id)!;
      completer.complete(response);
    } else {
      Logger.warn("unknown message from isolate: $message");
    }
  }

  /// completed in [_handleResponsesFromIsolate]
  static Future<int> _checkInput(int id, dynamic key) async {
    if (_sendToIsolate != null) {
      if (_activeRequests.containsKey(id)) {
        Logger.warn("main thread was faster than input isolate and send too many requests");
        return 0;
      }
      final Completer<int> completer = Completer<int>.sync();
      _activeRequests[id] = completer;
      _sendToIsolate!.send((id, key));
      final int result = await completer.future;
      return result;
    } else {
      Logger.warn("tried to get input $key from $id from stopped input isolate");
      return 0;
    }
  }

  /// Called from [KeyInputListener] to interact with the isolate. Returns how often the [key] has been clicked since
  /// the last call with the [id]
  static Future<int> keyClicked(int id, BoardKey key) => _checkInput(id, key);

  /// Called from [MouseInputListener] to interact with the isolate. Returns how often the [key] has been clicked since
  /// the last call with the [id]
  static Future<int> mouseClicked(int id, MouseKey key) => _checkInput(id, key);

  /// Will remove the internal [_InputInfo] that tracks the clicks while the listener is not active, so that those
  /// clicks can be skipped.
  static Future<void> ignoreClicks(int id) async {
    if (_sendToIsolate != null) {
      if (_activeRequests.containsKey(id)) {
        Logger.warn("main thread was faster than input isolate and send too many requests");
      } else {
        _sendToIsolate!.send(id);
        await Future<void>.delayed(const Duration(milliseconds: 1)); // no answer is awaited, so small delay!
      }
    } else {
      Logger.warn("tried to ignore clicks for $id from stopped input isolate");
    }
  }
}

final class _InputInfo {
  int _clickAmount;

  /// Mutable key which is either [BoardKey] or [MouseKey]
  dynamic key;

  _InputInfo({required this.key}) : _clickAmount = 0;

  void click() => ++_clickAmount;

  int resetAndGet() {
    final int clicks = _clickAmount;
    _clickAmount = 0;
    return clicks;
  }

  @override
  String toString() => "$_clickAmount $key";
}
