import 'package:flutter/material.dart';
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
/// and you have to override and create new object of it in [createIndexSubclass]
base mixin GTGroupedBuildersExtension<BT extends GTGroupBuilderInterface, IndexType extends GTGroupIndex>
    on GTNavigationPage {
  /// The list of builders which must be initialized only once in the constructor of the sub class!
  late final List<BT> builders;

  /// Calls [ConfigOptionBuilder.buildProvider] which then calls [ConfigOptionBuilder.buildContent] to build the
  /// content of the [MultiConfigOptionBuilder] (which is just the list of config options on the right part of the
  /// page)! May be overridden in sub classes!
  Widget buildCurrentGroupOptions(BuildContext context, BT builder) {
    return builder.buildProviderWithContent(context);
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
                elevation: 15,
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
        return Row(
          children: <Widget>[
            buildGroupLabels(context, pos),
            const SizedBox(width: 10),
            Expanded(child: buildCurrentGroupOptions(context, builders.elementAt(pos))),
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
