import 'package:flutter/material.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/pages/logs/gt_logs_page.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigation_page.dart';

// todo: implement and document
base class GTHomePage extends GTNavigationPage {
  const GTHomePage({
    super.key,
    super.backgroundImage,
    super.backgroundColor,
    super.pagePadding,
  });

  @override
  Widget buildBody(BuildContext context) {
    Logger.info("REBUILD HOME");
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text("Edit ui"),
          Text("switch to overlay"),
          TextButton(
            onPressed: () {
              pushPage(context, GTLogsPage());
            },
            child: Text("Show App Logs"),
          ),
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
