import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/enums/overlay_mode.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/overlay/gt_overlay.dart';

/// Used in top right corner of [GTOverlay] build with [GTOverlayState.buildTopRightSettings] and this can also receive
/// clicks so it is checked in [OverlayManager.checkMouseForClickableOverlayElements]!
class GtSettingsButton extends StatelessWidget with GTBaseWidget {
  const GtSettingsButton({super.key});

  /// This is used to calculate the position for this to receive clicks in
  /// [OverlayManager.checkMouseForClickableOverlayElements]
  static const int sizeForClicks = 24;

  /// If this changes, also change [sizeForClicks]
  static const double iconSize = 16;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: buildButton(context),
      ),
    );
  }

  Widget buildButton(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () {
        OverlayManager.overlayManager().changeMode(OverlayMode.APP_OPEN);
      },
      child: buildIcon(context),
    );
  }

  Widget buildIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorSurface(context).withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.settings,
        size: iconSize,
        color: colorOnSurface(context).withValues(alpha: 0.80),
      ),
    );
  }
}
