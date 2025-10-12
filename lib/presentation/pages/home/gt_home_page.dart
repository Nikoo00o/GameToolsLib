import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/enums/overlay_mode.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_app.dart';
import 'package:game_tools_lib/presentation/pages/debug/gt_debug_page.dart';
import 'package:game_tools_lib/presentation/pages/home/gt_window_status.dart';
import 'package:game_tools_lib/presentation/pages/logs/gt_logs_page.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigation_page.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigator.dart';
import 'package:game_tools_lib/presentation/widgets/functional/gt_version_check.dart';

/// The default landing page of the [GTNavigator] inside of the [GTApp] that can display some information about the
/// app and also provide some extra navigation steps in overridden sub classes.
///
/// Sub classes may override [buildMiddleEnd] for custom content at the bottom!
base class GTHomePage extends GTNavigationPage {
  const GTHomePage({
    super.key,
    super.backgroundImage,
    super.backgroundColor,
    super.pagePadding,
  });

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        buildTop(context),
        buildMiddle(context),
        buildBot(context),
      ],
    );
  }

  Widget buildTop(BuildContext context) {
    return const Column(
      children: <Widget>[
        GTWindowStatus(),
        SizedBox(height: 10),
      ],
    );
  }

  Widget buildBot(BuildContext context) {
    return const Column(
      children: <Widget>[
        SizedBox(height: 10),
        GTVersionCheck(),
      ],
    );
  }

  Widget buildMiddle(BuildContext context) {
    final String open = const TS("page.home.open").tl(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(const TranslationString("page.home.overlay.warning").tl(context)),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => OverlayManager.overlayManager().changeMode(OverlayMode.VISIBLE),
          child: const Text("switch to overlay"),
        ),
        const SizedBox(height: 10),
        FilledButton.tonal(
          onPressed: () => OverlayManager.overlayManager().changeMode(OverlayMode.EDIT_UI),
          child: const Text("Edit UI"),
        ),
        const SizedBox(height: 15),
        FilledButton.tonal(
          onPressed: () {
            pushPage(context, const GTDebugPage());
          },
          child: Text("$open ${const TS("page.debug.title").tl(context)}"),
        ),
        const SizedBox(height: 15),
        FilledButton.tonal(
          onPressed: () {
            pushPage(context, const GTLogsPage());
          },
          child: Text("$open ${const TS("page.logs.title").tl(context)}"),
        ),
        const SizedBox(height: 10),
        buildMiddleEnd(),
      ],
    );
  }

  /// Can be overridden in sub classes to display some custom elements at the bottom of [buildMiddle]
  Widget buildMiddleEnd() => const SizedBox();

  @override
  String get pageName => "GTHomePage";

  @override
  TranslationString get navigationLabel => const TS("page.home.title");

  @override
  IconData get navigationNotSelectedIcon => Icons.home_outlined;

  @override
  IconData get navigationSelectedIcon => Icons.home;
}
