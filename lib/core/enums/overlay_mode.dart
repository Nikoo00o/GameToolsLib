import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/overlay/gt_overlay.dart';

/// Contains the different states for the [OverlayManager]
enum OverlayMode {
  /// Should currently just not be visible, so don't display any elements, but display overlay itself!
  /// This is handled automatically in the [GTOverlay] to not render anything!
  HIDDEN,

  /// The App is currently the focus and the overlay is not even displayed!
  // todo: MULTI-WINDOW IN THE FUTURE: might be removed
  APP_OPEN,

  /// Overlay is active in the foreground showing the overlay UI elements in default mode!
  VISIBLE,

  /// Special case of editing the overlay UI elements (different overlay).
  EDIT_UI,

  /// Another special mode to edit the compare images.
  EDIT_COMP_IMAGES;

  @override
  String toString() => name;

  factory OverlayMode.fromString(String data) {
    return values.firstWhere((OverlayMode element) => element.name == data);
  }
}
