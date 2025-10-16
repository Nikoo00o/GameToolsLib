import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/enums/overlay_mode.dart';
import 'package:game_tools_lib/core/utils/bounds.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:window_manager/window_manager.dart';

/// Static only accessed to modify the flutter app window (maximize / transparent / resize) from [OverlayManager]
// todo: MULTI-WINDOW IN THE FUTURE: might be removed
final class NativeOverlayWindow {
  NativeOverlayWindow._();

  static bool _initialized = false;

  static bool _isActive = false;

  static Size? _oldSize;
  static Offset? _oldPos;
  static bool? _onTop;
  static int? _barSize;
  static bool? _shadow;

  static int? _width;
  static int? _height;
  static int? _x;
  static int? _y;

  static bool? _ignoreMouse;

  static final SpamIdentifier _snapLog1 = SpamIdentifier();
  static final SpamIdentifier _snapLog2 = SpamIdentifier();

  static Future<void> _init() async {
    if (_initialized == false) {
      Logger.spam("Initializing NativeOverlayWindow");
      await windowManager.ensureInitialized();
      _initialized = true;
    }
  }

  /// This is used for the overlay to [ignore] mouse events and pass them through.
  /// Used in [activateOverlay] and [deactivateOverlay], but also conditionally
  static Future<void> setMouseEvents({required bool ignore}) async {
    try {
      if (ignore != _ignoreMouse) {
        await _init();
        await windowManager.setIgnoreMouseEvents(ignore);
        Logger.spam("Mouse Passthrough: ", ignore);
        _ignoreMouse = ignore;
      }
    } catch (e) {
      Logger.warn("NativeOverlayWindow.setMouseEvents error $e");
    }
  }

  static Future<void> snapOverlay(GameWindow window) async {
    if (_isActive) {
      if (window.isOpen == false) {
        Logger.error("NativeOverlayWindow.snapOverlay can not work with a closed window ${window.name}");
        return;
      }
      await _init();
      final Bounds<int> bounds = window.getWindowBounds();
      final Point<int> outerSize = bounds.size;
      final Point<int> innerSize = window.size!;
      final int xOffset = outerSize.x - innerSize.x;
      final int yOffset = outerSize.y - innerSize.y;

      final int width = innerSize.x;
      final int height = innerSize.y;
      final int x = xOffset == 0 ? bounds.left : bounds.left + xOffset ~/ 2;
      final int y = yOffset == 0 ? bounds.top : bounds.top + yOffset - xOffset ~/ 2;

      if (width != _width || height != _height) {
        await windowManager.setSize(Size(width.toDouble(), height.toDouble()));
        _width = width;
        _height = height;
        Logger.spamPeriodic(_snapLog1, "NativeOverlayWindow snap size: ", width, ", ", height);
      }
      if (x != _x || y != _y) {
        await windowManager.setPosition(Offset(x.toDouble(), y.toDouble()), animate: false);
        _x = x;
        _y = y;
        Logger.spamPeriodic(_snapLog2, "NativeOverlayWindow snap pos: ", x, ", ", y);
      }
    } else {
      Logger.warn("NativeOverlayWindow.snapOverlay called with no active overlay");
    }
  }

  static Future<void> activateOverlay(GameWindow window, OverlayMode mode) async {
    if (_isActive == false) {
      await _init();
      _oldSize = await windowManager.getSize();
      _oldPos = await windowManager.getPosition();
      _onTop = await windowManager.isAlwaysOnTop();
      _barSize = await windowManager.getTitleBarHeight();
      _shadow = await windowManager.hasShadow();

      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setAsFrameless();

      if (mode != OverlayMode.EDIT_UI && mode != OverlayMode.EDIT_COMP_IMAGES) {
        await setMouseEvents(ignore: true);
      }

      _isActive = true;
      Logger.spam("NativeOverlayWindow activated overlay");
      await snapOverlay(window);
    } else {
      Logger.warn("NativeOverlayWindow.activateOverlay called with already active overlay");
    }
  }

  static Future<void> deactivateOverlay() async {
    if (_isActive) {
      await _init();
      _width = null;
      _height = null;
      _x = null;
      _y = null;

      await windowManager.setAlwaysOnTop(_onTop!);
      await windowManager.setBackgroundColor(Colors.black);
      if (_barSize! > 0) {
        await windowManager.setTitleBarStyle(TitleBarStyle.normal);
      }
      await windowManager.setHasShadow(_shadow!);

      await setMouseEvents(ignore: false);

      await windowManager.setSize(_oldSize!);
      await windowManager.setPosition(_oldPos!, animate: false);
      _isActive = false;
      Logger.spam("NativeOverlayWindow deactivated overlay");
    } else {
      Logger.warn("NativeOverlayWindow.deactivateOverlay called with no active overlay");
    }
  }
}
