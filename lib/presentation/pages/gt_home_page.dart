import 'package:flutter/material.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/presentation/pages/debug/gt_debug_page.dart';
import 'package:game_tools_lib/presentation/pages/logs/gt_logs_page.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigation_page.dart';
import 'package:provider/provider.dart';

// todo: implement and document
base class GTHomePage extends GTNavigationPage {
  const GTHomePage({
    super.key,
    super.backgroundImage,
    super.backgroundColor,
    super.pagePadding,
  });

  Widget _checkBox(BuildContext context, String translationKey, {required bool active}) {
    return Column(
      children: <Widget>[
        Icon(active ? Icons.check_box : Icons.close, color: active ? colorSuccess(context) : colorError(context)),
        const SizedBox(height: 2),
        Text(
          translate(context, translationKey),
          style: textLabelSmall(context),
        ),
      ],
    );
  }

  Widget buildMainWindowStatus() {
    return Consumer<GameWindow>(
      builder: (BuildContext context, GameWindow window, Widget? child) {
        return Column(
          children: <Widget>[
            Text(translate(context, "page.home.window.status")),
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

  @override
  Widget buildBody(BuildContext context) {
    final String open = translate(context, "page.home.open");
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          buildMainWindowStatus(),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              pushPage(context, const GTDebugPage());
            },
            child: Text("$open ${translate(context, "page.debug.title")}"),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () {},
            child: const Text("Edit UI"),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () {},
            child: const Text("switch to overlay"),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () {
              pushPage(context, const GTLogsPage());
            },
            child: Text("$open ${translate(context, "page.logs.title")}"),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  String get pageName => "GTHomePage";

  @override
  String get navigationLabel => "page.home.title";

  @override
  IconData get navigationNotSelectedIcon => Icons.home_outlined;

  @override
  IconData get navigationSelectedIcon => Icons.home;
}
