import 'package:flutter/material.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/pages/hotkeys/gt_hotkeys_page.dart';
import 'package:game_tools_lib/presentation/pages/hotkeys/hotkey_group_builder.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigation_page.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder.dart';
import 'package:game_tools_lib/presentation/pages/settings/gt_settings_page.dart';
import 'package:game_tools_lib/presentation/widgets/helper/changes/simple_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// This class stores the current index of [GTGroupedBuildersExtension] which settings group is selected.
/// Important: every page needs its own subclass of this if navigating between those pages, because the consumer
/// might not be rebuild otherwise!
abstract base class GTGroupIndex extends SimpleChangeNotifier<int> {
  GTGroupIndex(super.value);
}

/// Subclasses of this are used as type for [GTGroupedBuildersExtension.builders] and are generally either
/// [MultiConfigOptionBuilder] or [HotkeyGroupBuilder] which then need to override [buildGroupLabel] and
/// [buildProviderWithContent]!
///
/// So subclasses of this are generally a kind of config group with a number of children.
abstract interface class GTGroupBuilderInterface {
  /// This should build a Menu structure to the left of the [buildProviderWithContent] and is called from
  /// [GTGroupedBuildersExtension.buildGroupLabels] when building the menu entries.
  NavigationRailDestination buildGroupLabel(BuildContext context);

  /// This should build the content of the children of this on the right side. Optionally a provider and consumer
  /// can be used to update when some config state changes
  Widget buildProviderWithContent(BuildContext context);

  /// Should be overridden in the subclass to display the name (or translation key) that should be put on the
  /// navigation rail
  String get groupName;
}

/// An extension for [GTNavigationPage] for config pages that have a sub navigation rail on the left of available
/// selectable config options (from [buildGroupLabels]) and then the content on the right from [buildCurrentGroupOptions].
///
/// This overrides [buildBody] and [buildProviders] and provides a [GTGroupIndex] to everything build below.
///
/// Internally [buildCurrentGroupOptions] and [buildGroupLabels] are then used to build the UI which may be
/// overridden in a sub class!
///
/// The builder type [BT] must either be [MultiConfigOptionBuilder] for [GTSettingsPage], or [HotkeyGroupBuilder] for
/// [GTHotkeysPage] which have the initialize the [builders] in the subclass constructor only once!!!
///
/// And the [GTGroupIndex] must be just an empty subclass of [GTGroupIndex] to have different types for the provider
/// and you have to override and create new object of it in [createIndexSubclass].
///
/// This also changes the [pagePadding] so that it only applies to the right side of the body! (and not the next
/// inner navigation rail! by overriding [getInnerPadding] to null).
base mixin GTGroupedBuildersExtension<BT extends GTGroupBuilderInterface, IndexType extends GTGroupIndex>
    on GTNavigationPage {
  /// The list of builders which must be initialized only once in the constructor of the sub class!
  late final List<BT> builders;

  @override
  bool get allowTabTraversal => true;

  @override
  EdgeInsetsGeometry? getInnerPadding() => null;

  /// Calls [ConfigOptionBuilder.buildProviderWithContent] which then calls [ConfigOptionBuilder.buildContent] to build
  /// the content of the [MultiConfigOptionBuilder] (which is just the list of config options on the right part of the
  /// page)! May be overridden in sub classes!
  Widget buildCurrentGroupOptions(BuildContext context, BT builder) {
    return FocusTraversalGroup(descendantsAreTraversable: false, child: builder.buildProviderWithContent(context));
  }

  /// Builds the [NavigationRail] (with some settings) by calling [MultiConfigOptionBuilder.buildGroupLabel] which
  /// returns the [NavigationRailDestination] with the icons and translation keys. May be overridden in the sub class!
  Widget buildGroupLabels(BuildContext context, int index) {
    final List<NavigationRailDestination> destinations = builders
        .map((BT builder) => builder.buildGroupLabel(context))
        .toList();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraint) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraint.maxHeight),
            child: IntrinsicHeight(
              child: NavigationRail(
                selectedLabelTextStyle: TextStyle(color: colorPrimary(context)),
                minWidth: 140,
                backgroundColor: colorScaffoldBackground(context),
                selectedIndex: index,
                groupAlignment: -1.0,
                onDestinationSelected: (int index) => context.read<IndexType>().value = index,
                labelType: NavigationRailLabelType.all,
                destinations: destinations,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return Consumer<IndexType>(
      builder: (BuildContext context, IndexType index, Widget? child) {
        final int pos = index.value;
        final BT builder = builders.elementAt(pos);
        Logger.verbose("Inner Nav Tab selected: ${builder.groupName}");
        return Row(
          children: <Widget>[
            const SizedBox(width: 8),
            buildGroupLabels(context, pos),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Padding(padding: pagePadding, child: buildCurrentGroupOptions(context, builder)),
            ),
          ],
        );
      },
    );
  }

  @override
  List<SingleChildWidget> buildProviders(BuildContext context) => <SingleChildWidget>[
    ChangeNotifierProvider<IndexType>(create: createIndexSubclass),
  ];

  /// Must be overridden to create a new object of a unique subclass type of [GTGroupIndex]!
  IndexType createIndexSubclass(BuildContext context);
}
