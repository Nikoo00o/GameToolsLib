import 'dart:io' show Platform;

import 'package:collection/collection.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey, kWindowsToLogicalKey;
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';

/// Used for [InputManager] to represent the different states of the mouse buttons
enum MouseEvent implements Comparable<MouseEvent> {
  LEFT_DOWN(0x0002),
  LEFT_UP(0x0004),
  RIGHT_DOWN(0x0008),
  RIGHT_UP(0x0010),
  MIDDLE_DOWN(0x0020),
  MIDDLE_UP(0x0040);

  const MouseEvent(this.value);

  final int value;

  /// Returns the platform specific virtual keycode from this
  int convertToPlatformCode() {
    if (Platform.isWindows == false) {
      // todo: might have to change for different platforms
      throw UnimplementedError("This platform is currently not supported yet");
    } else {
      return value; // windows: default values
    }
  }

  @override
  int compareTo(MouseEvent other) => value - other.value;

  @override
  String toString() => name;
}

/// Used for [InputManager] to identify the different mouse buttons
enum MouseKey implements Comparable<MouseKey> {
  LEFT(0x01),
  RIGHT(0x02),
  MIDDLE(0x04);

  const MouseKey(this.value);

  final int value;

  /// Returns the platform specific virtual keycode from this
  int convertToPlatformCode() {
    if (Platform.isWindows == false) {
      // todo: might have to change for different platforms
      throw UnimplementedError("This platform is currently not supported yet");
    } else {
      return value; // windows: default values
    }
  }

  @override
  int compareTo(MouseKey other) => value - other.value;

  @override
  String toString() => name;

  static MouseKey? fromString(String? data) {
    return values.firstWhereOrNull((MouseKey element) => element.name == data);
  }
}

/// Used within [BoardKey] for platform mapping.
///
/// Or throws a [KeyNotFoundException] if the keycode was not found.
extension LogicalKeyboardKeyExtension on LogicalKeyboardKey {
  /// Returns the platform specific virtual keycode from this and null if it was not found
  int convertToPlatformCode() {
    int? key;
    if (Platform.isWindows == false) {
      // todo: might have to change for different platforms
      throw UnimplementedError("This platform is currently not supported yet");
    } else {
      key = logicalToWindows[keyId];
    }
    if (key == null) {
      throw KeyNotFoundException(message: "No key code for Key $keyLabel with id $keyId");
    }
    return key;
  }

  /// windows keycode (as key) mapped to logical key (as value)
  static Map<int, LogicalKeyboardKey> windowsToLogical = kWindowsToLogicalKey;
  static Map<int, int>? _logicalToWindows;

  /// logical key id (as key) mapped to windows keycode (as value)
  static Map<int, int> get logicalToWindows {
    if (_logicalToWindows == null) {
      _logicalToWindows = <int, int>{};
      for (final MapEntry<int, LogicalKeyboardKey> pair in windowsToLogical.entries) {
        _logicalToWindows![pair.value.keyId] = pair.key;
      }
      // the general special modifier keys have to be added manually
      _logicalToWindows!.addAll(<int, int>{
        LogicalKeyboardKey.shift.keyId: 0x10,
        LogicalKeyboardKey.control.keyId: 0x11,
        LogicalKeyboardKey.alt.keyId: 0x12,
        LogicalKeyboardKey.meta.keyId: 0x5B,
        LogicalKeyboardKey.semicolon.keyId: 0xBA,
        LogicalKeyboardKey.slash.keyId: 0xBF,
        LogicalKeyboardKey.backquote.keyId: 0xC0,
        LogicalKeyboardKey.braceLeft.keyId: 0xDB,
        LogicalKeyboardKey.backslash.keyId: 0xDC,
        LogicalKeyboardKey.braceRight.keyId: 0xDD,
        LogicalKeyboardKey.quote.keyId: 0xDE,
        LogicalKeyboardKey.tilde.keyId: 0xE2,
      });
    }
    return _logicalToWindows!;
  }
}
