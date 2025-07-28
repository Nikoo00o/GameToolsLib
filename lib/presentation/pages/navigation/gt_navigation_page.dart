import 'package:flutter/material.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_base_page.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigator.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// The classes that depend on this are used in the [GTNavigator] and have a navigation rail displayed on the left of
/// the screen and the [buildBody] of this is the expanded part of a row!
///
/// The same general info from [GTBasePage] what to override still applies here. But the [pagePadding] now of course
/// only applies to the right part of the row containing this and not the navigation rail on the left! And per
/// default the [buildAppBar] is overridden to build the [buildAppBarDefaultTitle] with the [navigationLabel] and no
/// back button!
///
/// Additionally [navigationLabel] must be overridden to provide info for the navigation rail together with
/// [navigationSelectedIcon] and [navigationNotSelectedIcon].
abstract base class GTNavigationPage extends GTBasePage {
  const GTNavigationPage({
    super.key,
    super.backgroundImage,
    super.backgroundColor,
    super.pagePadding,
  });

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) => buildAppBarDefaultTitle(context, navigationLabel);

  @override
  Widget build(BuildContext context) {
    final List<SingleChildWidget> providers = buildProviders(context);
    final Color? backgroundColor = getBackgroundColor(context);
    final DecorationImage? backgroundImage = getBackgroundImage();
    final Widget body = backgroundColor != null || backgroundImage != null
        ? Container(
            padding: pagePadding,
            decoration: BoxDecoration(image: backgroundImage, color: backgroundColor),
            child: buildBody(context),
          )
        : Padding(padding: pagePadding, child: buildBody(context));

    if (providers.isNotEmpty) {
      return MultiProvider(providers: providers, child: body);
    } else {
      return body;
    }
  }

  /// Must be overridden in sub classes to show a different label on the navigation rail bar to navigate to this!
  /// This is also used per default to build [buildAppBar].
  String get navigationLabel;

  /// The image to display in the left navigation bar for this. Must be overridden.
  IconData get navigationSelectedIcon;

  /// Can be the same icon as [navigationSelectedIcon], but can also be a "_border" suffix for a different not selected
  /// effect, or something else. Must be overridden.
  IconData get navigationNotSelectedIcon;
}
