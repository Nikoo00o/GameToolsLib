import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_app.dart';
import 'package:game_tools_lib/presentation/base/gt_base_page.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigation_page.dart';
import 'package:game_tools_lib/presentation/widgets/helper/changes/simple_change_notifier.dart';
import 'package:provider/provider.dart';

// ignore_for_file: must_be_immutable

/// The navigator of the [GTApp] building the current [GTNavigationPage] at the [GTNavIndex] which starts at
/// [startIndex] of the [pages] (which should be set in the constructor!).
///
/// This does not override / use any of the methods of [GTBasePage]
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
    this.minRailSize = 190,
    this.alignment = -1.0,
  }) : _debugCurIndex = startIndex;

  Widget buildCurrentPage(BuildContext context, GTNavigationPage page) {
    return page.build(context);
  }

  Widget buildCurrentNavRail(BuildContext context, int index) {
    final List<NavigationRailDestination> destinations = pages.map(
      (GTNavigationPage page) {
        return NavigationRailDestination(
          padding: const EdgeInsets.symmetric(vertical: 4),
          icon: Icon(page.navigationNotSelectedIcon),
          selectedIcon: Icon(page.navigationSelectedIcon),
          label: Text(translate(context, page.navigationLabel)),
        );
      },
    ).toList();
    return NavigationRail(
      backgroundColor: colorSurface(context).blend(colorPrimaryContainer(context), 0.2),
      selectedLabelTextStyle: TextStyle(color: colorPrimary(context)),
      minWidth: minRailSize,
      selectedIndex: index,
      groupAlignment: alignment,
      onDestinationSelected: (int index) => context.read<GTNavIndex>().value = index,
      labelType: NavigationRailLabelType.all,
      leading: navTopWidget,
      destinations: destinations,
    );
  }

  Widget buildScaffold(BuildContext context, int index) {
    final GTNavigationPage page = pages.elementAt(index);
    return Scaffold(
      body: Row(
        children: <Widget>[
          buildCurrentNavRail(context, index),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: buildCurrentPage(context, page)),
        ],
      ),
      appBar: page.buildAppBar(context),
      drawer: page.buildMenuDrawer(context),
      bottomNavigationBar: page.buildBottomBar(context),
    );
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
