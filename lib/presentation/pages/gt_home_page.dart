import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigation_page.dart';

// todo: implement and document
base class GTHome extends GTNavigationPage {
  const GTHome({
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
          ElevatedButton(
            onPressed: () {
              final BoolConfigOption darkTheme = MutableConfig.mutableConfig.useDarkTheme;
              darkTheme.setValue(!darkTheme.cachedValueNotNull());
            },
            child: Text("Change Dark theme"),
          ),
          SizedBox(height: 5),
          TextButton(
            onPressed: () {
              final LocaleConfigOption locale = MutableConfig.mutableConfig.currentLocale;
              locale.setValue(locale.activeLocale == Locale("de") ? Locale("en") : Locale("de"));
            },
            child: Text("Change Locale"),
          ),
        ],
      ),
    );
  }

  @override
  String get pageName => "GTHome";

  @override
  String get navigationLabel => "page.home.title";

  @override
  IconData get navigationNotSelectedIcon => Icons.home_outlined;

  @override
  IconData get navigationSelectedIcon => Icons.home;
}
