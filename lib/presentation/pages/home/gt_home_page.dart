import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/presentation/base/gt_app.dart';
import 'package:game_tools_lib/presentation/pages/debug/gt_debug_page.dart';
import 'package:game_tools_lib/presentation/pages/home/gt_window_status.dart';
import 'package:game_tools_lib/presentation/pages/logs/gt_logs_page.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigation_page.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigator.dart';

/// The default landing page of the [GTNavigator] inside of the [GTApp] that can display some information about the
/// app and also provide some extra navigation steps in overridden sub classes.
base class GTHomePage extends GTNavigationPage {
  const GTHomePage({
    super.key,
    super.backgroundImage,
    super.backgroundColor,
    super.pagePadding,
  });

  @override
  Widget buildBody(BuildContext context) {
    final String open = translate(const TS("page.home.open"), context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const GTWindowStatus(),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              pushPage(context, const GTDebugPage());
            },
            child: Text("$open ${translate(const TS("page.debug.title"), context)}"),
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
            child: Text("$open ${translate(const TS("page.logs.title"), context)}"),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  String get pageName => "GTHomePage";

  @override
  TranslationString get navigationLabel => const TS("page.home.title");

  @override
  IconData get navigationNotSelectedIcon => Icons.home_outlined;

  @override
  IconData get navigationSelectedIcon => Icons.home;
}
