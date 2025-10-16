import 'dart:async' show FutureOr, Completer;
import 'dart:math' show Point;

import 'package:flutter/foundation.dart' show protected;
import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/widgets.dart';
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/enums/overlay_mode.dart';
import 'package:game_tools_lib/core/utils/num_utils.dart';
import 'package:game_tools_lib/data/native/native_image.dart';
import 'package:game_tools_lib/data/native/native_overlay_window.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/overlay/gt_overlay.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/overlay_element.dart';
import 'package:game_tools_lib/presentation/overlay/widgets/gt_settings_button.dart';

/// Provides some base getters which are overridden in [OverlayManager] and is only used directly there!
/// Also provides the [checkMouseForClickableOverlayElements], [checkWindowPosition], [updateCachedWindowImage] and
/// [executeDelayedUpdates] to be called from [OverlayManager.onUpdate]
base mixin DelayedOverlayChecks<OverlayStateType extends GTOverlayState> {
  /// See docs of [OverlayManager.windowToTrack]
  GameWindow get windowToTrack;

  /// See docs of [OverlayManager.overlayMode]
  OverlayMode get overlayMode;

  /// Just shorter syntax to access those directly of the overlay elements list
  List<OverlayElement> get clickableElements;

  /// See docs of [OverlayManager.active]
  bool get active;

  /// used in [checkWindowPosition] as cached pos
  Point<int>? _lastWindowPos;

  /// Used to call [OverlayElement.onMouseLeave] in [checkMouseForClickableOverlayElements] as cached status
  OverlayElement? _mouseFocused;

  /// for [_currentPositionAndClickTicks]
  static final int _maxPositionAndClickTicks = FixedConfig.fixedConfig.overlayRefreshTicks;

  /// first tick counter for the two methods
  static int _currentPositionAndClickTicks = _maxPositionAndClickTicks;

  /// for [_currentPositionAndClickTicks]
  static final int _maxImageTicks = FixedConfig.fixedConfig.overlayRefreshTicks;

  /// second tick counter for the image method
  static int _currentImageTicks = _maxImageTicks;

  /// Will be called from [executeDelayedUpdates] inside of a check for [active] to check if the mouse hovers over
  /// a [OverlayElement.clickable] element and then [NativeOverlayWindow.setMouseEvents] for the passthrough setting
  /// only if the [OverlayElement.visible] is true .
  ///
  /// Only checks every [FixedConfig.overlayRefreshTicks] when [windowToTrack.isOpen] and [overlayMode] is [OverlayMode.VISIBLE]!
  ///
  /// This also checks the [GtSettingsButton] separately! And this checks [OverlayElement.onMouseEnter] first before
  /// accepting mouse focus and then if it was true, then [OverlayElement.onMouseLeave] after the mouse left the area!
  @protected
  Future<void> checkMouseForClickableOverlayElements() async {
    if (windowToTrack.isOpen && overlayMode == OverlayMode.VISIBLE) {
      final Point<double>? mousePos = windowToTrack.windowMousePos?.toDoublePoint();
      if (mousePos != null) {
        for (final OverlayElement element in clickableElements) {
          if (element.visible) {
            if (element.displayDimension?.contains(mousePos) ?? false) {
              if (element.onMouseEnter(mousePos)) {
                if (_mouseFocused != element) {
                  _mouseFocused?.onMouseLeave(); // check old element
                  _mouseFocused = element;
                }
                await NativeOverlayWindow.setMouseEvents(ignore: false);
                return; // found a clickable region, so skip until next try
              }
            }
          }
        }
        if (_mouseFocused != null) {
          _mouseFocused!.onMouseLeave(); // check old element
          _mouseFocused = null;
        }
        // now also check the settings button
        if (mousePos.y <= GtSettingsButton.sizeForClicks &&
            mousePos.x >= windowToTrack.width - GtSettingsButton.sizeForClicks) {
          await NativeOverlayWindow.setMouseEvents(ignore: false); // found click region
        } else {
          await NativeOverlayWindow.setMouseEvents(ignore: true); // no click region found, so ignore
        }
      } else {
        // mouse out of window, or top bar
        await NativeOverlayWindow.setMouseEvents(ignore: true); // no click region found, so ignore
      }
    }
  }

  /// Will be called from [executeDelayedUpdates] inside of a check for [active] to reposition the overlay if the
  /// window changed (only if window and overlay open). returns true if something changed and then the other
  /// [checkMouseForClickableOverlayElements] and [updateCachedWindowImage] will not be called this time!
  ///
  /// This is checked every [FixedConfig.overlayRefreshTicks]!
  @protected
  Future<bool> checkWindowPosition() async {
    if (windowToTrack.isOpen && overlayMode != OverlayMode.HIDDEN && overlayMode != OverlayMode.APP_OPEN) {
      final Point<int> pos = windowToTrack.getWindowBounds().pos;
      if (pos != _lastWindowPos) {
        _lastWindowPos = pos;
        await NativeOverlayWindow.snapOverlay(windowToTrack);
        return true;
      }
    }
    return false;
  }

  /// Will be called from [executeDelayedUpdates] inside of a check for [active] every
  /// [FixedConfig.overlayWindowImageCaptureTicks]
  @protected
  Future<void> updateCachedWindowImage() async {
    if (overlayMode == OverlayMode.VISIBLE) {
      try {
        await changeModeAsync(OverlayMode.HIDDEN);
        if (windowToTrack.isOpen && overlayMode == OverlayMode.HIDDEN) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (overlayMode == OverlayMode.HIDDEN) {
              // await windowToTrack.getFullImage();
              await changeModeAsync(OverlayMode.VISIBLE);
            }
          });
        } else {
          if (overlayMode == OverlayMode.HIDDEN) {
            await changeModeAsync(OverlayMode.VISIBLE);
          }
        }
      } catch (e) {
        Logger.error("OverlayManager.updateCachedWindowImage error:", e);
        if (overlayMode == OverlayMode.HIDDEN) {
          await changeModeAsync(OverlayMode.VISIBLE);
        }
        rethrow;
      }
    }
  }

  /// cached for [executeDelayedUpdates]
  bool _posChanged = false;

  /// This will call [checkWindowPosition], [checkMouseForClickableOverlayElements] and [updateCachedWindowImage]
  /// periodically with their specific timings (look at doc comments of those!) ONLY if [active] is true (checked
  /// inside of this update method only and not in the callbacks!)! Important: the two other methods are only called
  /// if the position check returned false (no change) and otherwise they are called next time.
  ///
  /// Is called periodically from [OverlayManager.onUpdate]
  @protected
  Future<void> executeDelayedUpdates() async {
    if (active) {
      if (_currentPositionAndClickTicks++ >= _maxPositionAndClickTicks) {
        _currentPositionAndClickTicks = 0;
        _posChanged = await checkWindowPosition();
        if (!_posChanged) {
          await checkMouseForClickableOverlayElements();
        }
      }
      if (!_posChanged) {
        if (_currentImageTicks++ >= 6) {
          _currentImageTicks = 0;
          await updateCachedWindowImage();
        }
      }
    }
  }

  NativeImage? _cachedImage;

  Future<NativeImage> get cachedWindowImage async {
    return _cachedImage!;
  }

  /// See [OverlayManager.changeModeAsync]
  Future<void> changeModeAsync(OverlayMode newOverlayMode);

  /// See [OverlayManager.scheduleUIWork]
  Future<void> scheduleUIWork(
    FutureOr<void> Function(BuildContext? context) callback, [
    Duration delay = Duration.zero,
  ]);

  /// Reference to final type
  OverlayManager<OverlayStateType> get manager => this as OverlayManager<OverlayStateType>;
}
