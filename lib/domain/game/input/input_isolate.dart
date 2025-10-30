import 'dart:async';
import 'dart:isolate';

import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/enums/input/input_enums.dart';
import 'package:game_tools_lib/data/native/native_window.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

/// [GameToolsLib] will automatically call [createIsolate] and [destroyIsolate] and then [isKeyDown] and [isMouseDown]
/// will be used by [BaseInputListener]s!
///
/// This will run twice as fast as [FixedConfig.updatesPerSecond]
abstract final class InputIsolate {
  /// the unique ids are mapped to InputInfo on the isolate
  static final Map<int, _InputInfo> _inputInfos = <int, _InputInfo>{};

  /// to send data from main thread
  static SendPort? _sendToIsolate;

  /// set in [createIsolate] from main thread
  static bool _initializing = false;

  /// the thread from main thread
  static Isolate? _isolate;

  /// used when polling from main. only 1 request at a time for individual listeners possible! (will not cache
  /// multiple, but the thread should run faster than main)
  static final Map<int, Completer<bool>> _activeRequests = <int, Completer<bool>>{};

  /// used on isolate for keyboard
  static bool _getAndResetKey(int id, BoardKey key) {
    final _InputInfo? info = _inputInfos[id];
    if (info is _KeyInputInfo && info.key == key) {
      final bool wasDown = info.isDown;
      if (wasDown) {
        info.isDown = false;
        return true;
      }
    } else {
      _inputInfos[id] = _KeyInputInfo(isDown: false, key: key);
    }
    return false;
  }

  /// used on isolate for mouse
  static bool _getAndResetMouse(int id, MouseKey key) {
    final _InputInfo? info = _inputInfos[id];
    if (info is _MouseInputInfo && info.key == key) {
      final bool wasDown = info.isDown;
      if (wasDown) {
        info.isDown = false;
        return true;
      }
    } else {
      _inputInfos[id] = _MouseInputInfo(isDown: false, key: key);
    }
    return false;
  }

  /// isolate thread loop
  static Future<void> _startRemoteIsolate((SendPort port, Duration delay) pair) async {
    final (SendPort port, Duration delay) = pair;
    final ReceivePort receivePort = ReceivePort();
    port.send(receivePort.sendPort);
    receivePort.listen((dynamic message) async {
      if (message is (int, BoardKey)) {
        final (int id, BoardKey key) = message;
        port.send((id, _getAndResetKey(id, key)));
      } else if (message is (int, MouseKey)) {
        final (int id, MouseKey key) = message;
        port.send((id, _getAndResetMouse(id, key)));
      }
    });

    try {
      NativeWindow.clearNativeWindowInstance(createNewWindow: true);
    } catch (e, s) {
      // ignore: avoid_print
      print("ERROR: Input Isolate could not create native window: $e $s");
      return;
    }
    while (true) {
      try {
        for (int i = 0; i < _inputInfos.values.length; ++i) {
          final _InputInfo info = _inputInfos.values.elementAt(i);
          if (!info.isDown) {
            info.checkInput();
          }
        }
      } catch (_) {
        // ignored in thread, should not contain interruption exception on kill?
      }
      await Future<void>.delayed(delay);
    }
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
    if (message is (int, bool)) {
      final (int id, bool response) = message;
      final Completer<bool> completer = _activeRequests.remove(id)!;
      completer.complete(response);
    } else {
      Logger.warn("unknown message from isolate: $message");
    }
  }

  /// completed in [_handleResponsesFromIsolate]
  static Future<bool> _checkInput(int id, dynamic key) async {
    if (_sendToIsolate != null) {
      if (_activeRequests.containsKey(id)) {
        Logger.warn("main thread was faster than input isolate and send too many requests");
        return false;
      }
      final Completer<bool> completer = Completer<bool>.sync();
      _activeRequests[id] = completer;
      _sendToIsolate!.send((id, key));
      final bool result = await completer.future;
      return result;
    } else {
      Logger.warn("tried to get input $key from $id from stopped input isolate");
      return false;
    }
  }

  /// Called from [KeyInputListener] to interact with the isolate
  static Future<bool> isKeyDown(int id, BoardKey key) => _checkInput(id, key);

  /// Called from [MouseInputListener] to interact with the isolate
  static Future<bool> isMouseDown(int id, MouseKey key) => _checkInput(id, key);
}

/// Used internally in the isolate with the versions [_KeyInputInfo] and [_MouseInputInfo]
sealed class _InputInfo {
  bool isDown;

  _InputInfo({required this.isDown});

  /// sets [isDown]
  void checkInput();
}

/// Keyboard keys
final class _KeyInputInfo extends _InputInfo {
  BoardKey key;

  _KeyInputInfo({required super.isDown, required this.key});

  @override
  void checkInput() => isDown = InputManager.isKeyDown(key);
}

/// Mouse keys
final class _MouseInputInfo extends _InputInfo {
  MouseKey key;

  _MouseInputInfo({required super.isDown, required this.key});

  @override
  void checkInput() => isDown = InputManager.isMouseDown(key);
}
