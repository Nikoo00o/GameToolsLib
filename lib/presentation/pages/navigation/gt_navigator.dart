import 'package:flutter/material.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_app.dart';
import 'package:game_tools_lib/presentation/base/gt_base_page.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigation_page.dart';
import 'package:game_tools_lib/presentation/widgets/helper/changes/simple_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

// ignore_for_file: must_be_immutable

/// The navigator of the [GTApp] building the current [GTNavigationPage] at the [GTNavIndex] which starts at
/// [startIndex] of the [pages] (which should be set in the constructor!). Also it provides the [GTNavIndex] which
/// can be accessed in [Consumer]'s further down.
///
/// This does not override / use any of the methods of [GTBasePage].
///
/// The first menu on the left has the same color as the default app bar per default and then the inner content of
/// the page has rounded corners.
///
/// Per default this will build the right inner body of the [GTNavigationPage] in the [colorScaffoldBackground] color
/// with a padding around it and everything else (like [buildAppBarDefaultTitle]) and the [buildCurrentNavRail] is in the
/// [colorSurfaceContainer] color! Also the [GTNavigationPage]'s are padded with the [GTNavigationPage.innerNavPadding]
///
/// The [buildScaffold] uses [GTNavigationPage.buildProviders]
base class GTNavigator extends GTBasePage {
  /// List of [GTNavigationPage] pages that are the options to navigate to
  final List<GTNavigationPage> pages;

  /// This has to be a constant value from the config, or something (default is 0)
  final int startIndex;

  /// This should to be a constant value from the config, or something (default is 190)
  final double minRailSize;

  /// How entries in nav bar are aligned. Default -1.0 for top, can be 1.0 for bot and 0.0 for center
  final double alignment;

  /// Shown above all other entries, per default this is null
  final Widget? navTopWidget;

  /// Only used for [pageName]
  int _debugCurIndex;

  GTNavigator({
    super.key,
    required this.pages,
    this.navTopWidget,
    this.startIndex = 0,
    this.minRailSize = 120,
    this.alignment = -1.0,
  }) : _debugCurIndex = startIndex;

  /// Build the current right side [page] inside of a builder for [buildScaffold]
  Widget buildCurrentPage(GTNavigationPage page) {
    return Builder(builder: (BuildContext context) => page.build(context));
  }

  /// Builds the left side menu of [buildScaffold]
  Widget buildCurrentNavRail(BuildContext context, int index) {
    final List<NavigationRailDestination> destinations = pages.map(
      (GTNavigationPage page) {
        return NavigationRailDestination(
          padding: const EdgeInsets.symmetric(vertical: 4),
          icon: Icon(page.navigationNotSelectedIcon),
          selectedIcon: Icon(page.navigationSelectedIcon),
          label: Text(page.navigationLabel.tl(context)),
        );
      },
    ).toList();
    return FocusTraversalGroup(
      child: NavigationRail(
        backgroundColor: colorSurfaceContainer(context),
        selectedLabelTextStyle: TextStyle(color: colorPrimary(context)),
        minWidth: minRailSize,
        selectedIndex: index,
        groupAlignment: alignment,
        onDestinationSelected: (int index) => context.read<GTNavIndex>().value = index,
        labelType: NavigationRailLabelType.all,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(12.0),
          ),
        ),
        leading: navTopWidget,
        destinations: destinations,
        scrollable: true,
      ),
    );
  }

  /// Called from [build] to build the current content
  Widget buildScaffold(BuildContext context, int index) {
    final GTNavigationPage page = pages.elementAt(index);
    final List<SingleChildWidget> providers = page.buildProviders(context);

    final Widget scaffold = Builder(
      builder: (BuildContext context) {
        return Scaffold(
          body: Row(
            children: <Widget>[
              buildCurrentNavRail(context, index),
              Expanded(child: buildCurrentPage(page)),
            ],
          ),
          appBar: page.buildAppBar(context),
          drawer: page.buildMenuDrawer(context),
          bottomNavigationBar: page.buildBottomBar(context),
          backgroundColor: colorSurfaceContainer(context),
        );
      },
    );

    if (providers.isNotEmpty) {
      return MultiProvider(providers: providers, child: scaffold);
    } else {
      return scaffold;
    }
  }

  @override
  Widget buildBody(BuildContext context) => const SizedBox();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GTNavIndex>(
      create: (BuildContext context) => GTNavIndex(startIndex),
      child: Consumer<GTNavIndex>(
        builder: (BuildContext context, GTNavIndex index, Widget? child) {
          final int value = index.value;
          if (value != _debugCurIndex) {
            Logger.verbose("GTNavigator switched from ${_pageNameOf(_debugCurIndex)} to ${_pageNameOf(value)}");
          }
          _debugCurIndex = value;
          return buildScaffold(context, value);
        },
      ),
    );
  }

  String _pageNameOf(int index) => pages.elementAt(index).pageName;

  @override
  String get pageName => "GTNavigator: ${_pageNameOf(_debugCurIndex)}";
}

/// This class stores the current index of [GTNavigator] which [GTNavigationPage] is selected
final class GTNavIndex extends SimpleChangeNotifier<int> {
  GTNavIndex(super.value);
}
