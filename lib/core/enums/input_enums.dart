part of 'package:game_tools_lib/data/native/native_window.dart';

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
  int _convertToPlatformCode() {
    if (Platform.isWindows == false) {
      // todo: might have to change for different platforms
      throw UnimplementedError("This platform is currently not supported yet");
    } else {
      return value; // windows: default values
    }
  }

  @override
  int compareTo(MouseEvent other) => value - other.value;
}

/// Used for [InputManager] to identify the different mouse buttons
enum MouseKey implements Comparable<MouseKey> {
  LEFT(0x01),
  RIGHT(0x02),
  MIDDLE(0x04);

  const MouseKey(this.value);

  final int value;

  /// Returns the platform specific virtual keycode from this
  int _convertToPlatformCode() {
    if (Platform.isWindows == false) {
      // todo: might have to change for different platforms
      throw UnimplementedError("This platform is currently not supported yet");
    } else {
      return value; // windows: default values
    }
  }

  @override
  int compareTo(MouseKey other) => value - other.value;
}

/// Used within [BoardKey] for platform mapping.
///
/// Or throws a [KeyNotFoundException] if the keycode was not found.
extension LogicalKeyboardKeyExtension on LogicalKeyboardKey {
  /// Returns the platform specific virtual keycode from this and null if it was not found
  int _convertToPlatformCode() {
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

/// Used for [InputManager] to identify the different keyboard keys including special modifier.
/// Can be used to either press a key, or check if a key is pressed.
/// Uses [keyCode], [keyName] and [logicalKeys].
/// Also contains the all used keys as static members like [enter], [n1] for the number 1 key, [a] characters,
/// etc which should be preferred to be used directly (or with the [copyWith] constructor, because not all
/// [LogicalKeyboardKey]'s are supported!
final class BoardKey {
  /// If actual key is down
  final LogicalKeyboardKey logicalKey;

  /// If shift is down (all platforms) (doesn't matter if left or right key is pressed!)
  /// If null, this is ignored, otherwise if used in check [false] means that it must not be active!
  /// If this is used for checking if the key was pressed, then this also treats caps lock as the same as shift!
  final bool? withShift;

  /// On windows the ctrl key and on mac named "⌃" (doesn't matter if left or right key is pressed!)
  /// If null, this is ignored, otherwise if used in check [false] means that it must not be active!
  final bool? withControl;

  /// On windows the alt key and on mac the option key "⌥" (doesn't matter if left or right key is pressed!)
  /// If null, this is ignored, otherwise if used in check [false] means that it must not be active!
  final bool? withAlt;

  /// On windows the windows key and on mac the command key (doesn't matter if left or right key is pressed!)
  /// If null, this is ignored, otherwise if used in check [false] means that it must not be active!
  final bool? withMeta;

  /// Fn key only available on some keyboards (all platforms)
  /// If null, this is ignored, otherwise if used in check [false] means that it must not be active!
  /// If this is used for checking if the key was pressed, then this also treats fn lock as the same as fn!
  final bool? withFN;

  /// Use with a [LogicalKeyboardKey] as [key] for the virtual key and optionally your modifiers see [BoardKey].
  /// Prefer to use the [copyWith] constructor on the static members of this if you need different modifier!
  const BoardKey(
    LogicalKeyboardKey key, {
    this.withShift,
    this.withControl,
    this.withAlt,
    this.withMeta,
    this.withFN,
  }) : logicalKey = key;

  BoardKey copyWith({
    LogicalKeyboardKey? logicalKey,
    bool? withShift,
    bool? withControl,
    bool? withAlt,
    bool? withMeta,
    bool? withFN,
  }) {
    return BoardKey(
      logicalKey ?? this.logicalKey,
      withShift: withShift ?? this.withShift,
      withControl: withControl ?? this.withControl,
      withAlt: withAlt ?? this.withAlt,
      withMeta: withMeta ?? this.withMeta,
      withFN: withFN ?? this.withFN,
    );
  }

  /// The matching logical keys for this including the [logicalKey] and modifiers that are true
  /// (for example [withShift]).
  /// This is used for pressing a key.
  List<LogicalKeyboardKey> get logicalKeys => <LogicalKeyboardKey>[
    if (withShift == true) LogicalKeyboardKey.shift,
    if (withControl == true) LogicalKeyboardKey.control,
    if (withAlt == true) LogicalKeyboardKey.alt,
    if (withMeta == true) LogicalKeyboardKey.meta,
    if (withFN == true) LogicalKeyboardKey.fn,
    logicalKey,
  ];

  /// This always contains shift and capslock. Only used for checking if a key was pressed.
  List<LogicalKeyboardKey> get anyShift => <LogicalKeyboardKey>[LogicalKeyboardKey.shift, LogicalKeyboardKey.capsLock];

  /// This always contains fn and fn lock. Only used for checking if a key was pressed.
  List<LogicalKeyboardKey> get anyFN => <LogicalKeyboardKey>[LogicalKeyboardKey.fn, LogicalKeyboardKey.fnLock];

  /// The matching logical keys for the modifiers that are explicitly set to [true] except [withShift] and [withFN],
  /// see [anyShift] and [anyFN].
  /// Only used for checking if a key was pressed.
  List<LogicalKeyboardKey> get activeModifierNoLocks => <LogicalKeyboardKey>[
    if (withControl == true) LogicalKeyboardKey.control,
    if (withAlt == true) LogicalKeyboardKey.alt,
    if (withMeta == true) LogicalKeyboardKey.meta,
  ];

  /// The matching logical keys for the modifiers that are explicitly set to [false] except [withShift] and [withFN],
  /// see [anyShift] and [anyFN].
  /// Only used for checking if a key was pressed.
  List<LogicalKeyboardKey> get inactiveModifierNoLocks => <LogicalKeyboardKey>[
    if (withControl == false) LogicalKeyboardKey.control,
    if (withAlt == false) LogicalKeyboardKey.alt,
    if (withMeta == false) LogicalKeyboardKey.meta,
  ];

  /// Returns the platform specific key code for this [logicalKey]
  int get keyCode => logicalKey._convertToPlatformCode();

  /// Returns the label for the [logicalKey]
  String get keyName => logicalKey.keyLabel;

  /// Special Key combinations
  static const BoardKey ctrlC = BoardKey(LogicalKeyboardKey.keyC, withControl: true);
  static const BoardKey ctrlV = BoardKey(LogicalKeyboardKey.keyV, withControl: true);

  /// Modifier keys themself (don't use the general modifier key to press it manually!)
  static const BoardKey shiftLeft = BoardKey(LogicalKeyboardKey.shiftLeft);
  static const BoardKey shiftRight = BoardKey(LogicalKeyboardKey.shiftRight);
  static const BoardKey controlLeft = BoardKey(LogicalKeyboardKey.controlLeft);
  static const BoardKey controlRight = BoardKey(LogicalKeyboardKey.controlRight);
  static const BoardKey altLeft = BoardKey(LogicalKeyboardKey.altLeft);
  static const BoardKey altRight = BoardKey(LogicalKeyboardKey.altRight);
  static const BoardKey metaLeft = BoardKey(LogicalKeyboardKey.metaLeft);
  static const BoardKey metaRight = BoardKey(LogicalKeyboardKey.metaRight);
  static const BoardKey fn = BoardKey(LogicalKeyboardKey.fn);
  static const BoardKey numLock = BoardKey(LogicalKeyboardKey.numLock);

  /// Numbers
  static const BoardKey n1 = BoardKey(LogicalKeyboardKey.digit1);
  static const BoardKey n2 = BoardKey(LogicalKeyboardKey.digit2);
  static const BoardKey n3 = BoardKey(LogicalKeyboardKey.digit3);
  static const BoardKey n4 = BoardKey(LogicalKeyboardKey.digit4);
  static const BoardKey n5 = BoardKey(LogicalKeyboardKey.digit5);
  static const BoardKey n6 = BoardKey(LogicalKeyboardKey.digit6);
  static const BoardKey n7 = BoardKey(LogicalKeyboardKey.digit7);
  static const BoardKey n8 = BoardKey(LogicalKeyboardKey.digit8);
  static const BoardKey n9 = BoardKey(LogicalKeyboardKey.digit9);
  static const BoardKey n0 = BoardKey(LogicalKeyboardKey.digit0);

  /// Characters
  static const BoardKey q = BoardKey(LogicalKeyboardKey.keyQ);
  static const BoardKey w = BoardKey(LogicalKeyboardKey.keyW);
  static const BoardKey e = BoardKey(LogicalKeyboardKey.keyE);
  static const BoardKey r = BoardKey(LogicalKeyboardKey.keyR);
  static const BoardKey t = BoardKey(LogicalKeyboardKey.keyT);

  /// Different location on keyboard depending on region
  static const BoardKey z = BoardKey(LogicalKeyboardKey.keyZ);
  static const BoardKey u = BoardKey(LogicalKeyboardKey.keyU);
  static const BoardKey i = BoardKey(LogicalKeyboardKey.keyI);
  static const BoardKey o = BoardKey(LogicalKeyboardKey.keyO);
  static const BoardKey p = BoardKey(LogicalKeyboardKey.keyP);
  static const BoardKey a = BoardKey(LogicalKeyboardKey.keyA);
  static const BoardKey s = BoardKey(LogicalKeyboardKey.keyS);
  static const BoardKey d = BoardKey(LogicalKeyboardKey.keyD);
  static const BoardKey f = BoardKey(LogicalKeyboardKey.keyF);
  static const BoardKey g = BoardKey(LogicalKeyboardKey.keyG);
  static const BoardKey h = BoardKey(LogicalKeyboardKey.keyH);
  static const BoardKey j = BoardKey(LogicalKeyboardKey.keyJ);
  static const BoardKey k = BoardKey(LogicalKeyboardKey.keyK);
  static const BoardKey l = BoardKey(LogicalKeyboardKey.keyL);

  /// Different location on keyboard depending on region
  static const BoardKey y = BoardKey(LogicalKeyboardKey.keyY);
  static const BoardKey x = BoardKey(LogicalKeyboardKey.keyX);
  static const BoardKey c = BoardKey(LogicalKeyboardKey.keyC);
  static const BoardKey v = BoardKey(LogicalKeyboardKey.keyV);
  static const BoardKey b = BoardKey(LogicalKeyboardKey.keyB);
  static const BoardKey n = BoardKey(LogicalKeyboardKey.keyN);
  static const BoardKey m = BoardKey(LogicalKeyboardKey.keyM);

  /// F keys
  static const BoardKey f1 = BoardKey(LogicalKeyboardKey.f1);
  static const BoardKey f2 = BoardKey(LogicalKeyboardKey.f2);
  static const BoardKey f3 = BoardKey(LogicalKeyboardKey.f3);
  static const BoardKey f4 = BoardKey(LogicalKeyboardKey.f4);
  static const BoardKey f5 = BoardKey(LogicalKeyboardKey.f5);
  static const BoardKey f6 = BoardKey(LogicalKeyboardKey.f6);
  static const BoardKey f7 = BoardKey(LogicalKeyboardKey.f7);
  static const BoardKey f8 = BoardKey(LogicalKeyboardKey.f8);
  static const BoardKey f9 = BoardKey(LogicalKeyboardKey.f9);
  static const BoardKey f10 = BoardKey(LogicalKeyboardKey.f10);
  static const BoardKey f11 = BoardKey(LogicalKeyboardKey.f11);
  static const BoardKey f12 = BoardKey(LogicalKeyboardKey.f12);
  static const BoardKey f13 = BoardKey(LogicalKeyboardKey.f13);
  static const BoardKey f14 = BoardKey(LogicalKeyboardKey.f14);
  static const BoardKey f15 = BoardKey(LogicalKeyboardKey.f15);
  static const BoardKey f16 = BoardKey(LogicalKeyboardKey.f16);
  static const BoardKey f17 = BoardKey(LogicalKeyboardKey.f17);
  static const BoardKey f18 = BoardKey(LogicalKeyboardKey.f18);
  static const BoardKey f19 = BoardKey(LogicalKeyboardKey.f19);
  static const BoardKey f20 = BoardKey(LogicalKeyboardKey.f20);
  static const BoardKey f21 = BoardKey(LogicalKeyboardKey.f21);
  static const BoardKey f22 = BoardKey(LogicalKeyboardKey.f22);
  static const BoardKey f23 = BoardKey(LogicalKeyboardKey.f23);
  static const BoardKey f24 = BoardKey(LogicalKeyboardKey.f24);

  /// Often used special keys
  static const BoardKey enter = BoardKey(LogicalKeyboardKey.enter);
  static const BoardKey space = BoardKey(LogicalKeyboardKey.space);
  static const BoardKey tab = BoardKey(LogicalKeyboardKey.tab);
  static const BoardKey backspace = BoardKey(LogicalKeyboardKey.backspace);
  static const BoardKey escape = BoardKey(LogicalKeyboardKey.escape);
  static const BoardKey arrowLeft = BoardKey(LogicalKeyboardKey.arrowLeft);
  static const BoardKey arrowUp = BoardKey(LogicalKeyboardKey.arrowUp);
  static const BoardKey arrowRight = BoardKey(LogicalKeyboardKey.arrowRight);
  static const BoardKey arrowDown = BoardKey(LogicalKeyboardKey.arrowDown);

  /// Additional special keys that are region specific and may have region specific locations as well
  /// Right of [m]: . and either < or ;
  static const BoardKey comma = BoardKey(LogicalKeyboardKey.comma);

  /// (Also Called Dot) Right of [comma]: . and either > or :
  static const BoardKey period = BoardKey(LogicalKeyboardKey.period);

  /// Also(minus, or underscore key): -_ (location right of [n0], or left of [shiftRight])
  static const BoardKey dash = BoardKey(LogicalKeyboardKey.minus);

  /// Region specific either +/= or +*~  (location left of [backspace], or left of [enter])
  static const BoardKey plus = BoardKey(LogicalKeyboardKey.add);

  /// Region specific either :; or Ü (location either left of [oem7], or left of [plus])
  static const BoardKey oem1 = BoardKey(LogicalKeyboardKey.semicolon);
  /// Region specific either /? or #' (location left of [shiftRight], or left of [enter])
  static const BoardKey oem2 = BoardKey(LogicalKeyboardKey.slash);
  /// Region specific either ~` or Ö (location either left of [n1], or left of [oem7])
  static const BoardKey oem3 = BoardKey(LogicalKeyboardKey.backquote);
  /// Region specific either {[ or ß?\ (location either left of [oem6], or right of [n0])
  static const BoardKey oem4 = BoardKey(LogicalKeyboardKey.braceLeft);
  /// Region specific either \| or ^° (location either above [enter], or left of [n1])
  static const BoardKey oem5 = BoardKey(LogicalKeyboardKey.backslash);
  /// Region specific either }] or ´` (location either left of [oem7], or right of [oem4])
  static const BoardKey oem6 = BoardKey(LogicalKeyboardKey.braceRight);
  /// Region specific either "' or Ä (location either left of [enter], or left of [oem2])
  static const BoardKey oem7 = BoardKey(LogicalKeyboardKey.quote);
  /// On windows called oem102 instead
  /// Region specific either unknown or <>| (location either unknown, or left of [y])
  static const BoardKey oem8 = BoardKey(LogicalKeyboardKey.tilde);

  /// Ü in supported regions
  static BoardKey get ue => oem1;
  /// Ä in supported regions
  static BoardKey get ae => oem7;
  /// Ö in supported regions
  static BoardKey get oe => oem3;
  /// ß in supported regions
  static BoardKey get ss => oem4;

  /// Default Special Keys
}
