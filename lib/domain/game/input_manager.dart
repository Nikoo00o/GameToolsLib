part of 'package:game_tools_lib/domain/game/game_window.dart';

/// This offers only static methods like [isKeyDown] to interact with the games input, but some methods
/// that are relative to a window may require a [GameWindow] or its bounds (see game window methods).
///
/// Most important methods would be: [leftClick], [keyPress], [isKeyDown] and [isMouseDown]
/// and [setClipboard], or [fillClipboard] and [getSelectedData], or [pasteDataIntoSelected], etc
abstract final class InputManager {
  /// Returns [NativeWindow.instance]
  static NativeWindow get _nativeWindow => NativeWindow.instance;

  /// Sets the mouse to [x], [y] relative to the top left corner of the full display screen.
  /// Affects both [getWindowMousePos] and [displayMousePos].
  /// Prefer to use [moveMouseInWindow] instead.
  static void setDisplayMousePos(int x, int y) {
    Logger.spam("Set display mouse pos at (", x, ", ", y, ")");
    _nativeWindow.setDisplayMousePos(x, y);
  }

  /// Returns the mouse position relative to the top left corner of the full display screen
  static Point<int> get displayMousePos => _nativeWindow.getDisplayMousePos();

  /// Same as [setDisplayMousePos], but with [Point]
  static set displayMousePos(Point<int> pos) => setDisplayMousePos(pos.x, pos.y);

  /// Returns the mouse position relative to the top left corner of the window.
  /// May throw a [WindowClosedException] if the window was not open.
  /// Returns [null] if the cursor is currently outside of the window (see [GameWindow.isWithinWindow])!
  /// There is also [getWindowMousePosNonNull] if preferred.
  ///
  /// Important: uses mouse position relative to top left window border, but [GameWindow.getWindowBounds] would also
  /// include a top window border in its height which is not included here!
  static Point<int>? getWindowMousePos(GameWindow window) {
    final Point<int>? pos = _nativeWindow.getWindowMousePos(window._windowID);
    if (pos == null) {
      throw const WindowClosedException(message: "Cant get mouse pos inside window");
    }
    if (window.isWithinWindow(pos) == false) {
      return null;
    }
    return pos;
  }

  /// Same as [getWindowMousePos], but instead of [null], this returns Point(0, 0) AND ALSO SETS THE mouse to the top
  /// left corner of the window!
  static Point<int> getWindowMousePosNonNull(GameWindow window) {
    Point<int>? pos = getWindowMousePos(window);
    if (pos == null) {
      pos = const Point<int>(0, 0);
      setWindowMousePos(0, 0, window);
    }
    return pos;
  }

  /// Sets the mouse to [x], [y] relative to the top left corner of the window. Prefer to use [moveMouseInWindow] instead!
  /// May throw a [WindowClosedException] if the window was not open.
  /// Affects both [getWindowMousePos] and [displayMousePos]
  ///
  /// Important: uses mouse position relative to top left window border, but [GameWindow.getWindowBounds] would also
  /// include a top window border in its height which is not included here!
  static void setWindowMousePos(int x, int y, GameWindow window) {
    if (_nativeWindow.setWindowMousePos(window._windowID, x, y) == false) {
      throw WindowClosedException(message: "Cant set mouse to pos in window: $x, $y");
    }
    Logger.spam("Set mouse pos into window ", window.name, " at (", x, ", ", y, ")");
  }

  /// Sets the mouse to [point] relative to the top left corner of the window in natural slower way instead of just
  /// instantly setting the mouse pos. Prefer to use this method!
  ///
  /// Optionally use [offset] to move the mouse to a random pos in an area instead (with a +- offset
  /// around the middle point). You can also set a different [minMaxStepDelayInMS] on how long each
  /// step / mouse change should take in combination with a custom positive number of [minStepSize] and
  /// [maxStepSize] on how far the pos should be moved at a time.The default value for [minMaxStepDelayInMS]
  /// is [FixedConfig.tinyDelayMS].
  ///
  /// Before returning, this also awaits [FixedConfig.shortDelayMS] once at the end!
  ///
  /// May throw a [WindowClosedException] if the window was not open. You can also use [GameWindow.moveMouse] instead!
  /// Affects both [getWindowMousePos] and [displayMousePos]
  ///
  /// Important: uses mouse position relative to top left window border, but [GameWindow.getWindowBounds] would also
  /// include a top window border in its height which is not included here!
  ///
  /// Very Important: use at your own risk! some games, or anti cheats may not like forced mouse movements even if they
  /// don't do anything bad and could flag you for using this!
  static Future<void> moveMouseInWindow(
    Point<int> point,
    GameWindow window, {
    Point<int> offset = const Point<int>(3, 3),
    Point<int>? minMaxStepDelayInMS,
    int minStepSize = 14,
    int maxStepSize = 18,
  }) async {
    // if the start point is not in window, then set it to top left corner
    final Point<int> startPos = getWindowMousePosNonNull(window);
    minMaxStepDelayInMS ??= FixedConfig.fixedConfig.tinyDelayMS; // default value for delay
    int currX = startPos.x;
    int currY = startPos.y;
    int targetX = NumUtils.getRandomNumber(point.x - offset.x, point.x + offset.x);
    targetX = targetX < 0 ? 0 : targetX; // only check for negative cords, not checking for out of bounds for bot right
    int targetY = NumUtils.getRandomNumber(point.y - offset.y, point.y + offset.y);
    targetY = targetY < 0 ? 0 : targetY; // only check for negative cords, not checking for out of bounds for bot right

    // now calculate general step vector from distance
    final Point<int> distance = Point<int>(targetX - currX, targetY - currY);
    final Point<double> normalized = NumUtils.normalizePoint(
      NumUtils.absPoint(distance.toDoublePoint(), higherThanZero: true),
    );
    final Point<double> stepXY = NumUtils.raisePointTo(normalized, 1.0);
    // and set specific step min max values
    final Point<int> xStep = Point<int>((stepXY.x * minStepSize).ceil(), (stepXY.x * maxStepSize).ceil());
    final Point<int> yStep = Point<int>((stepXY.y * minStepSize).ceil(), (stepXY.y * maxStepSize).ceil());

    int addToX = 0; // now start loop with steppers
    int addToY = 0;
    while (true) {
      final int randomXStep = distance.x >= 0 ? NumUtils.getRandomNumberP(xStep) : -NumUtils.getRandomNumberP(xStep);
      final int randomYStep = distance.y >= 0 ? NumUtils.getRandomNumberP(yStep) : -NumUtils.getRandomNumberP(yStep);
      addToX = distance.x >= 0 ? min(targetX - currX, randomXStep) : max(targetX - currX, randomXStep);
      addToY = distance.y >= 0 ? min(targetY - currY, randomYStep) : max(targetY - currY, randomYStep);
      _nativeWindow.moveMouse(addToX, addToY);
      currX += addToX;
      currY += addToY;
      if (addToX == 0 && addToY == 0) {
        await Utils.delay(NumUtils.getRandomDuration(FixedConfig.fixedConfig.shortDelayMS));
        final Point<int> currPos = getWindowMousePosNonNull(window);
        if (currPos.x != currX || currPos.y != currY) {
          addToX = targetX - currPos.x;
          addToY = targetY - currPos.y;
          _nativeWindow.moveMouse(addToX, addToY);
          Logger.spam("Had to correct last mouse move step by ", addToX, ", ", addToY);
        }
        Logger.spam("Moved mouse in window ", window.name, " from ", startPos, " to ", currPos);
        break;
      }
      await Utils.delay(NumUtils.getRandomDuration(minMaxStepDelayInMS));
    }
  }

  /// Uses [GameWindow.getPixelOfWindowP] with [getWindowMousePos]
  static Color? getPixelAtCursor(GameWindow window) {
    final Point<int>? cursor = getWindowMousePos(window);
    if (cursor == null) {
      return null;
    }
    return window.getPixelOfWindow(cursor.x, cursor.y);
  }

  /// Scrolls by this amount of scroll wheel clicks into one direction (can be negative for reverse)
  static void scrollMouse(int scrollClickAmount) {
    Logger.spam("Scrolled mouse ", scrollClickAmount, " times");
    _nativeWindow.scrollMouse(scrollClickAmount);
  }

  /// Presses and holds the mouse button down. Used in [leftClick], etc
  static void mouseDown(MouseKey mouseButton) => _nativeWindow.sendMouseEvent(switch (mouseButton) {
    MouseKey.LEFT => MouseEvent.LEFT_DOWN,
    MouseKey.RIGHT => MouseEvent.RIGHT_DOWN,
    MouseKey.MIDDLE => MouseEvent.MIDDLE_DOWN,
  });

  /// Releases a mouse button up that was pressed down before. Used in [leftClick], etc
  static void mouseUp(MouseKey mouseButton) => _nativeWindow.sendMouseEvent(switch (mouseButton) {
    MouseKey.LEFT => MouseEvent.LEFT_UP,
    MouseKey.RIGHT => MouseEvent.RIGHT_UP,
    MouseKey.MIDDLE => MouseEvent.MIDDLE_UP,
  });

  /// helper method used internally
  static Future<void> _mouseClick({required MouseKey key, required Point<int>? delayBeforeAndBetweenInMS}) async {
    final Duration duration = NumUtils.getRandomDuration(delayBeforeAndBetweenInMS);
    await Utils.delay(duration);
    mouseDown(key);
    await Utils.delay(duration);
    mouseUp(key);
    Logger.spam("Clicked mouse ", key);
  }

  /// Clicks the left mouse button down and up.
  /// [delayBeforeAndBetweenInMS] is awaited at the start and middle of this and defaults to [FixedConfig.shortDelayMS]
  static Future<void> leftClick({Point<int>? delayBeforeAndBetweenInMS}) async =>
      _mouseClick(key: MouseKey.LEFT, delayBeforeAndBetweenInMS: delayBeforeAndBetweenInMS);

  /// Clicks the right mouse button down and up.
  /// [delayBeforeAndBetweenInMS] is awaited at the start and middle of this and defaults to [FixedConfig.shortDelayMS]
  static Future<void> rightClick({Point<int>? delayBeforeAndBetweenInMS}) async =>
      _mouseClick(key: MouseKey.RIGHT, delayBeforeAndBetweenInMS: delayBeforeAndBetweenInMS);

  /// Clicks the middle mouse button down and up.
  /// [delayBeforeAndBetweenInMS] is awaited at the start and middle of this and defaults to [FixedConfig.shortDelayMS]
  static Future<void> middleMouseClick({Point<int>? delayBeforeAndBetweenInMS}) async =>
      _mouseClick(key: MouseKey.MIDDLE, delayBeforeAndBetweenInMS: delayBeforeAndBetweenInMS);

  /// Manually Presses a keyboard key down (with the virtual [keyCode]). used in [keyPress]
  static void keyDown(LogicalKeyboardKey keyCode) => _nativeWindow.sendKeyEvent(keyUp: false, keyCode: keyCode);

  /// Manually Releases a keyboard key up (with the virtual [keyCode]) that was pressed down before. used in [keyPress]
  static void keyUp(LogicalKeyboardKey keyCode) => _nativeWindow.sendKeyEvent(keyUp: true, keyCode: keyCode);

  /// This can be used to send multiple raw key events at the same time (rarely used).
  /// [keyUp]=true will send a key release event and otherwise a key pressed down event is send.
  /// [keyCodes] represents the virtual keycodes of the keys.
  static void sendRawKeyEvents({required bool keyUp, required List<LogicalKeyboardKey> keyCodes}) =>
      _nativeWindow.sendKeyEvents(keyUp: keyUp, keyCodes: keyCodes);

  /// Taps the key [key] up and down and optionally also its modifier keys and returns true if it was successful.
  ///
  /// Otherwise if the [key] was already down, this returns false!
  ///
  /// [delayBeforeAndBetweenInMS] is awaited at the start and middle of this and defaults to [FixedConfig.shortDelayMS]
  static Future<bool> keyPress(BoardKey key, {Point<int>? delayBeforeAndBetweenInMS}) async {
    final Duration duration = NumUtils.getRandomDuration(delayBeforeAndBetweenInMS);
    await Utils.delay(duration);
    final List<LogicalKeyboardKey> keyCodes = key.logicalKeys;
    if (_nativeWindow.isKeyDown(keyCodes.last)) {
      Logger.spam("Can't press ", key, " because it was already down!");
      return false;
    }
    if (keyCodes.length == 1) {
      keyDown(keyCodes.first);
      await Utils.delay(duration);
      keyUp(keyCodes.first);
    } else {
      for (int i = 0; i < keyCodes.length - 1; ++i) {
        if (_nativeWindow.isKeyDown(keyCodes[i])) {
          keyCodes.removeAt(i--);
        }
      }
      sendRawKeyEvents(keyUp: false, keyCodes: keyCodes);
      await Utils.delay(duration);
      sendRawKeyEvents(keyUp: true, keyCodes: keyCodes);
    }
    Logger.spam("Pressed key ", key);
    return true;
  }

  /// Returns if the virtual keycode is currently pressed down and optionally also its modifier keys
  static bool isKeyDown(BoardKey key) {
    if (!_nativeWindow.isKeyDown(key.logicalKey)) {
      return false;
    }
    for (final LogicalKeyboardKey keyCode in key._activeModifierNoLocks) {
      if (!_nativeWindow.isKeyDown(keyCode)) {
        return false;
      }
    }
    for (final LogicalKeyboardKey keyCode in key._inactiveModifierNoLocks) {
      if (_nativeWindow.isKeyDown(keyCode)) {
        return false;
      }
    }
    if (key.withShift != null) {
      final List<LogicalKeyboardKey> keys = key._anyShift;
      bool shiftDown = _nativeWindow.isKeyDown(keys.first);
      if (_nativeWindow.isKeyToggled(keys.last)) {
        shiftDown = true;
      }
      if (key.withShift == true) {
        if (shiftDown == false) {
          return false;
        }
      } else if (key.withShift == false) {
        if (shiftDown) {
          return false;
        }
      }
    }
    if (key.withFN != null) {
      final List<LogicalKeyboardKey> keys = key._anyFN;
      bool fnDown = _nativeWindow.isKeyDown(keys.first);
      if (_nativeWindow.isKeyToggled(keys.last)) {
        fnDown = true;
      }
      if (key.withFN == true) {
        if (fnDown == false) {
          return false;
        }
      } else if (key.withFN == false) {
        if (fnDown) {
          return false;
        }
      }
    }
    return true;
  }

  /// Returns if virtual mouse key code is currently down(also works correctly if left and right mouse buttons are
  /// swapped).
  static bool isMouseDown(MouseKey mouseButton) => _nativeWindow.isMouseDown(mouseButton);

  /// Stores [data] in the clipboard (may be empty).
  /// [delayBeforeAndAfter] will be awaited first and x2 after and is [FixedConfig.mediumDelayMS] if null. It
  /// will also be awaited again 5 times if a [PlatformException] is thrown during clipboard access (if that try
  /// fails, then the exception is rethrown!)
  static Future<void> setClipboard(String data, {Point<int>? delayBeforeAndAfter}) async {
    final Duration duration = NumUtils.getRandomDuration(
      delayBeforeAndAfter,
      defaultIfNull: FixedConfig.fixedConfig.mediumDelayMS,
    );
    try {
      await Utils.delay(duration);
      await Clipboard.setData(ClipboardData(text: data));
    } catch (_) {
      Logger.spam("could not get clipboard, trying again...");
      await Utils.delay(duration * 5);
      await Clipboard.setData(ClipboardData(text: data));
    }
    Logger.spam("Set clipboard data length ", data.length);
    await Utils.delay(duration);
  }

  /// Returns the data currently stored in the clipboard (may be empty)
  /// [delayBeforeAndAfter] will be awaited first and after and is [FixedConfig.mediumDelayMS] if null. It will also
  /// be awaited again 5 times if a [PlatformException] is thrown during clipboard access (if that try fails, then
  /// the exception is rethrown!).
  ///
  /// Currently this can only return text and no image, or binary data from the clipboard!
  static Future<String> getClipboard({Point<int>? delayBeforeAndAfter}) async {
    final Duration duration = NumUtils.getRandomDuration(
      delayBeforeAndAfter,
      defaultIfNull: FixedConfig.fixedConfig.mediumDelayMS,
    );
    late final ClipboardData? data;
    try {
      await Utils.delay(duration);
      data = await Clipboard.getData("text/plain");
    } catch (_) {
      Logger.spam("could not get clipboard, trying again...");
      await Utils.delay(duration * 5);
      data = await Clipboard.getData("text/plain");
    }
    final String text = data?.text ?? "";
    Logger.spam("Got clipboard data length: ", text.length);
    await Utils.delay(duration);
    return text;
  }

  /// Uses CTRL+C to copy something selected into the clipboard.
  /// The [delayBeforeAndAfter] will be awaited first, middle and after and is [FixedConfig.mediumDelayMS] if
  /// null.
  static Future<void> fillClipboard({Point<int>? delayBeforeAndAfter}) async {
    final Duration duration = NumUtils.getRandomDuration(
      delayBeforeAndAfter,
      defaultIfNull: FixedConfig.fixedConfig.mediumDelayMS,
    );
    await Utils.delay(duration);
    await keyPress(BoardKey.ctrlC); // additional 2 smaller delays
    Logger.spam("Got clipboard from selection");
    await Utils.delay(duration);
  }

  /// Uses CTRL+V to paste the clipboard into something selected.
  /// The [delayBeforeAndAfter] will be awaited first, middle and after and is [FixedConfig.mediumDelayMS] if
  /// null.
  static Future<void> pasteClipboard({Point<int>? delayBeforeAndAfter}) async {
    final Duration duration = NumUtils.getRandomDuration(
      delayBeforeAndAfter,
      defaultIfNull: FixedConfig.fixedConfig.mediumDelayMS,
    );
    await Utils.delay(duration);
    await keyPress(BoardKey.ctrlV); // additional 2 smaller delays
    Logger.spam("Pasted clipboard into selection");
    await Utils.delay(duration);
  }

  /// Tries to fill the clipboard with data of either some selected text with CTRL+C, or something at the position of
  /// the mouse cursor and returns the read data!
  /// The [delayBeforeAndAfter] will be awaited 9 times and is [FixedConfig.mediumDelayMS] if null.
  /// This uses [fillClipboard], but preserves the initial clipboard data of the user!
  /// If [selectFirst] is true, then this will first select the data with CTRL+A with additional 4 awaits!
  ///
  /// Currently this can only restore your old clipboard text (and no image, or binary data!)
  static Future<String> getSelectedData({Point<int>? delayBeforeAndAfter, bool selectFirst = false}) async {
    if (selectFirst) {
      await keyPress(BoardKey.ctrlA, delayBeforeAndBetweenInMS: delayBeforeAndAfter);
      await Utils.delay(NumUtils.getRandomDuration(delayBeforeAndAfter));
    }
    final String oldData = await getClipboard();
    await fillClipboard(delayBeforeAndAfter: delayBeforeAndAfter);
    final String newData = await getClipboard();
    await setClipboard(oldData);
    Logger.spam("Return selected data: ", newData, "\nAnd preserved old data: ", oldData);
    return newData;
  }

  /// Tries to paste [data] into some selected text field with CTRL+V, or something at the position of the mouse cursor.
  /// For example used in [sendChatMessage].
  /// The [delayBeforeAndAfter] will be awaited 9 times and is [FixedConfig.mediumDelayMS] if null.
  /// This uses [pasteClipboard], but preserves the initial clipboard data of the user!
  ///
  /// Currently this can only restore your old clipboard text (and no image, or binary data!)
  static Future<void> pasteDataIntoSelected(String data, {Point<int>? delayBeforeAndAfter}) async {
    if (data.isEmpty) {
      Logger.warn("Pasting empty data into something selected");
    }
    final String oldData = await getClipboard();
    await setClipboard(data);
    await pasteClipboard(delayBeforeAndAfter: delayBeforeAndAfter);
    await setClipboard(oldData);
    Logger.spam("Pasted data into selection: ", data, "\nand preserved old data: ", oldData);
  }

  /// Tries to open a default chat window with [LogicalKeyboardKey.enter] to then use [pasteDataIntoSelected] to put
  /// the [text] into it and pressing enter again to send the chat message.
  /// There will be in total 11 await calls for the [delay] which is [FixedConfig.mediumDelayMS] if null.
  ///
  /// Currently this can only restore your old clipboard text (and no image, or binary data!)
  static Future<void> sendChatMessage(String text, {Point<int>? delay}) async {
    Logger.verbose("Sending chat message...: $text");
    await keyPress(BoardKey.enter); // additional 2 smaller delays
    await pasteDataIntoSelected(text, delayBeforeAndAfter: delay); // 9 medium delays
    await keyPress(BoardKey.enter); // additional 2 smaller delays
  }
}
