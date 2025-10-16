import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/enums/overlay_mode.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/overlay/gt_overlay.dart';
import 'package:game_tools_lib/presentation/overlay/widgets/gt_settings_button.dart';

/// Used in top right corner of [GTOverlay] left of [GtSettingsButton] and is build in [GTOverlayState.buildEditCheckmark]
/// only for [OverlayMode.EDIT_UI] and [OverlayMode.EDIT_COMP_IMAGES]. Important: the position of this is set outside
/// and needs to respect the size of the settings button.
class GTEditDoneButton extends StatelessWidget with GTBaseWidget {
  const GTEditDoneButton({super.key});

  /// If this changes, also change [sizeForClicks]
  static const double iconSize = 18;

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
        OverlayManager.overlayManager().changeMode(OverlayMode.VISIBLE);
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
        Icons.check_circle_outlined,
        size: iconSize,
        color: colorSuccess(context).withValues(alpha: 0.80),
      ),
    );
  }
}
