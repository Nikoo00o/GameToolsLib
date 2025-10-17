import 'dart:async' show FutureOr;
import 'dart:math' show Point;

import 'package:flutter/widgets.dart';
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/enums/overlay_mode.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/num_utils.dart';
import 'package:game_tools_lib/data/native/native_image.dart';
import 'package:game_tools_lib/data/native/native_overlay_window.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/overlay/gt_overlay.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/compare_image.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/overlay_element.dart';
import 'package:game_tools_lib/presentation/overlay/widgets/gt_settings_button.dart';

/// Provides some base getters which are overridden in [OverlayManager] and is only used directly there!
/// Also provides the [checkMouseForClickableOverlayElements], [checkWindowPosition] and [executeDelayedUpdates] to be
/// called from [OverlayManager.onUpdate]. Also [getWindowImageWithoutOverlay].
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

  /// for [getWindowImageWithoutOverlay]
  NativeImage? _cachedImage;

  /// for [getWindowImageWithoutOverlay]
  DateTime? _latestGet;

  /// for [_currentPositionAndClickTicks]
  static final int _maxPositionAndClickTicks = FixedConfig.fixedConfig.overlayRefreshTicks;

  /// first tick counter for the two methods
  static int _currentPositionAndClickTicks = _maxPositionAndClickTicks;

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
  /// [checkMouseForClickableOverlayElements] will not be called this time!
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

  /// This will call [checkWindowPosition], [checkMouseForClickableOverlayElements] periodically with
  /// [FixedConfig.overlayRefreshTicks] (look at doc comments of those!) ONLY if [active] is true (checked
  /// inside of this update method only and not in the callbacks!)! Important: the two other methods are only called
  /// if the position check returned false (no change) and otherwise they are called next time.
  ///
  /// Is called periodically from [OverlayManager.onUpdate]
  @protected
  Future<void> executeDelayedUpdates() async {
    if (active) {
      if (_currentPositionAndClickTicks++ >= _maxPositionAndClickTicks) {
        _currentPositionAndClickTicks = 0;
        final bool posChanged = await checkWindowPosition();
        if (!posChanged) {
          await checkMouseForClickableOverlayElements();
        }
      }
    }
  }

  /// Important: this can be used manually (and may be used in [CompareImage]) to return a screenshot of the game
  /// window without the overlay.
  ///
  /// This may throw a [WindowClosedException] and it may return a cached image depending on [allowCacheOlderThan].
  /// Because this method will always cause the overlay to flicker by turning it on and off !!! The default cache
  /// duration would be 500 milliseconds!
  Future<NativeImage> getWindowImageWithoutOverlay([
    Duration allowCacheOlderThan = const Duration(milliseconds: 500),
  ]) async {
    if (!windowToTrack.isOpen) {
      throw WindowClosedException(message: "$windowToTrack was closed during getWindowImageWithoutOverlay");
    }
    final DateTime newest = DateTime.now();

    if (_latestGet != null && newest.difference(_latestGet!) < allowCacheOlderThan) {
      return _cachedImage!;
    }

    if (overlayMode == OverlayMode.VISIBLE) {
      try {
        await changeModeAsync(OverlayMode.HIDDEN);
        if (overlayMode == OverlayMode.HIDDEN) {
          await scheduleUIWork((_) async {
            if (windowToTrack.isOpen && overlayMode == OverlayMode.HIDDEN) {
              _cachedImage = await windowToTrack.getFullImage();
              await changeModeAsync(OverlayMode.VISIBLE);
              Logger.verbose("Cached new window image without overlay");
            }
          });
        }
        if (overlayMode == OverlayMode.HIDDEN) {
          await changeModeAsync(OverlayMode.VISIBLE);
        }
      } catch (e) {
        Logger.error("OverlayManager.updateCachedWindowImage error:", e);
        if (overlayMode == OverlayMode.HIDDEN) {
          await changeModeAsync(OverlayMode.VISIBLE);
        }
        rethrow;
      }
    }

    _latestGet = newest;
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
