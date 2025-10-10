import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/pages/home/gt_home_page.dart';
import 'package:provider/provider.dart';

/// Used in [GTHomePage] to display the status of the main window
class GTWindowStatus extends StatelessWidget with GTBaseWidget {
  const GTWindowStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameWindow>(
      builder: (BuildContext context, GameWindow window, Widget? child) {
        return Column(
          children: <Widget>[
            Text(const TS("page.home.window.status").tl(context)),
            const SizedBox(height: 2),
            Text(
              window.name,
              style: textBodyMedium(context).copyWith(color: colorPrimary(context), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _checkBox(context, "page.home.window.status.open", active: window.isOpen),
                const SizedBox(width: 14),
                _checkBox(context, "page.home.window.status.focused", active: window.hasFocus),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _checkBox(BuildContext context, String translationKey, {required bool active}) {
    return Column(
      children: <Widget>[
        Icon(active ? Icons.check_box : Icons.close, color: active ? colorSuccess(context) : colorError(context)),
        const SizedBox(height: 2),
        Text(
          TS(translationKey).tl(context),
          style: textLabelSmall(context),
        ),
      ],
    );
  }
}
