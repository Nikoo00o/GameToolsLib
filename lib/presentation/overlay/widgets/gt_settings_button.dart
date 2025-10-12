import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/enums/overlay_mode.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/overlay/gt_overlay.dart';

/// Used in top right corner of [GTOverlay]
class GtSettingsButton extends StatelessWidget with GTBaseWidget {
  const GtSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            OverlayManager.overlayManager().changeMode(OverlayMode.APP_OPEN);
          },
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: colorSurface(context).withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.settings,
              size: 16,
              color: colorOnSurface(context).withValues(alpha: 0.80),
            ),
          ),
        ),
      ),
    );
  }
}
