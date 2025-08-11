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

/// Used within [BoardKey] for platform mapping like [convertToPlatformCode], or [fromPlatformCode], etc
extension LogicalKeyboardKeyExtension on LogicalKeyboardKey {
  /// Returns the platform specific virtual keycode from this. Throws a [KeyNotFoundException] if no platform
  /// specific keycode was found!
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

  /// If this is either right, or left, or global shift key
  bool get isAnyShift =>
      this == BoardKey.shiftLeft.logicalKey ||
      this == BoardKey.shiftRight.logicalKey ||
      this == LogicalKeyboardKey.shift;

  /// If this is either right, or left, or global control key
  bool get isAnyControl =>
      this == BoardKey.controlLeft.logicalKey ||
      this == BoardKey.controlRight.logicalKey ||
      this == LogicalKeyboardKey.control;

  /// If this is either right, or left, or global alt key
  bool get isAnyAlt =>
      this == BoardKey.altLeft.logicalKey ||
          this == BoardKey.altRight.logicalKey ||
          this == LogicalKeyboardKey.alt;

  /// If this is either right, or left, or global meta key
  bool get isAnyMeta =>
      this == BoardKey.metaLeft.logicalKey ||
          this == BoardKey.metaRight.logicalKey ||
          this == LogicalKeyboardKey.meta;

  /// Converts the platform specific virtual [keyCode] to a logical key. Throws a [KeyNotFoundException] if no platform
  /// specific keycode was found! (for example special language/region specific characters like ÖÄÜ)
  static LogicalKeyboardKey fromPlatformCode(int keyCode) {
    LogicalKeyboardKey? key;
    if (Platform.isWindows == false) {
      // todo: might have to change for different platforms
      throw UnimplementedError("This platform is currently not supported yet");
    } else {
      key = windowsToLogical[keyCode];
    }
    if (key == null) {
      throw KeyNotFoundException(message: "No logical keyboard key for key code $keyCode");
    }
    return key;
  }

  /// Tries to convert a [writtenCharacter] like "A", or "shift". Throws a [KeyNotFoundException] if no matching
  /// logical key was found! (for example special language/region specific characters like ÖÄÜ)
  static LogicalKeyboardKey fromString(String writtenCharacter) {
    LogicalKeyboardKey? key;
    if (Platform.isWindows == false) {
      // todo: might have to change for different platforms
      throw UnimplementedError("This platform is currently not supported yet");
    } else {
      for (final LogicalKeyboardKey entry in windowsToLogical.values) {
        if (entry.keyLabel.toUpperCase() == writtenCharacter.toUpperCase()) {
          key = entry;
          break;
        }
      }
    }
    if (key == null) {
      throw KeyNotFoundException(message: "No logical keyboard key for written character $writtenCharacter");
    }
    return key;
  }

  static Map<int, LogicalKeyboardKey>? _windowsToLogical;

  /// logical key id (as key) mapped to windows keycode (as value)
  static Map<int, LogicalKeyboardKey> get windowsToLogical {
    if (_windowsToLogical == null) {
      _windowsToLogical = Map<int, LogicalKeyboardKey>.of(kWindowsToLogicalKey);
      // the general special modifier keys have to be added manually once
      _windowsToLogical!.addAll(<int, LogicalKeyboardKey>{
        0x10: LogicalKeyboardKey.shift,
        0x11: LogicalKeyboardKey.control,
        0x12: LogicalKeyboardKey.alt,
        0x5B: LogicalKeyboardKey.meta,
        0xBA: LogicalKeyboardKey.semicolon,
        0xBF: LogicalKeyboardKey.slash,
        0xC0: LogicalKeyboardKey.backquote,
        0xDB: LogicalKeyboardKey.braceLeft,
        0xDC: LogicalKeyboardKey.backslash,
        0xDD: LogicalKeyboardKey.braceRight,
        0xDE: LogicalKeyboardKey.quote,
        0xE2: LogicalKeyboardKey.tilde,
      });
    }
    return _windowsToLogical!;
  }

  static Map<int, int>? _logicalToWindows;

  /// logical key id (as key) mapped to windows keycode (as value)
  static Map<int, int> get logicalToWindows {
    if (_logicalToWindows == null) {
      _logicalToWindows = <int, int>{};
      for (final MapEntry<int, LogicalKeyboardKey> pair in windowsToLogical.entries) {
        _logicalToWindows![pair.value.keyId] = pair.key;
      }
    }
    return _logicalToWindows!;
  }
}
