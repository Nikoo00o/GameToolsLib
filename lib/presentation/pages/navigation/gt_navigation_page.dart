import 'package:flutter/material.dart';
import 'package:game_tools_lib/presentation/base/gt_base_page.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigator.dart';

/// The classes that depend on this are used in the [GTNavigator] and have a navigation rail displayed on the left of
/// the screen and the [buildBody] of this is the expanded part of a row (only a divider and no padding in between)!
///
/// The same general info from [GTBasePage] what to override still applies here. But the [pagePadding] here only
/// applies to the right part of the row containing this and not the navigation rail on the left! The general padding
/// around the whole right part is retrieved with [getInnerPadding] which can be overridden in the subclass if you
/// want to use some other padding for your body instead of the default [pagePadding]. But there is also the
/// [innerNavPadding] always applied for the [GTNavigationPage]'s to give them rounded corners
///
/// Also per default the [buildAppBar] is overridden to build the [buildAppBarDefaultTitle] with the [navigationLabel]
/// and no back button! And per default the default app bar is in the same color as the outer left navigation bar.
/// And the same color is around the padded inner page with rounded borders.
///
/// Important: [buildProviders] of this will be called from [GTNavigator.buildScaffold] so that it includes body and
/// appbar of this!
///
/// Additionally [navigationLabel] must be overridden to provide info for the navigation rail together with
/// [navigationSelectedIcon] and [navigationNotSelectedIcon].
///
/// Also subclasses can control tabbing with [allowTabTraversal].
abstract base class GTNavigationPage extends GTBasePage {
  /// This is build around the [GTNavigationPage]
  static const EdgeInsets innerNavPadding = EdgeInsets.fromLTRB(8, 8, 8, 8);

  const GTNavigationPage({
    super.key,
    super.backgroundImage,
    super.backgroundColor,
    super.pagePadding,
  });

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) => buildAppBarDefaultTitle(context, navigationLabel);

  /// Can be overridden in the sub class to return something differently, but per default returns the [pagePadding].
  /// It will be used as the padding around the right side of the page!
  EdgeInsetsGeometry? getInnerPadding() => pagePadding;

  /// Can be overridden in sub classes to control of the tab key on the keyboard should be able to focus widgets of
  /// the page
  bool get allowTabTraversal => false;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = getBackgroundColor(context) ?? colorScaffoldBackground(context);
    final DecorationImage? backgroundImage = getBackgroundImage();

    return FocusTraversalGroup(
      descendantsAreTraversable: allowTabTraversal,
      child: Container(
        margin: innerNavPadding,
        padding: getInnerPadding(),
        decoration: BoxDecoration(
          image: backgroundImage,
          color: backgroundColor,
          borderRadius: const BorderRadius.all(
            Radius.circular(12.0),
          ),
        ),
        child: buildBody(context),
      ),
    );
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
