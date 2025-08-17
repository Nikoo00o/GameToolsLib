import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/ui_helper.dart';
import 'package:game_tools_lib/presentation/pages/hotkeys/gt_hotkeys_page.dart';
import 'package:game_tools_lib/presentation/pages/hotkeys/hotkey_group_builder.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigation_page.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder.dart';
import 'package:game_tools_lib/presentation/pages/settings/gt_settings_page.dart';
import 'package:game_tools_lib/presentation/widgets/helper/changes/simple_change_notifier.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_search_container.dart';
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
  Widget buildProviderWithContent(BuildContext context, {required bool calledFromInnerGroup});

  /// Should be overridden in the subclass to display the name (or translation key) that should be put on the
  /// inner navigation rail on the left side
  TranslationString get groupName;

  /// Must be overridden to return if this builder should be shown when the user is searching [upperCaseSearchString]
  bool containsSearch(BuildContext context, String upperCaseSearchString);
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
/// inner navigation rail! by overriding [getInnerPadding] to null). And this also provides a search bar per default
/// which also uses the [navigationLabel] as translated hint!
base mixin GTGroupedBuildersExtension<BT extends GTGroupBuilderInterface, IndexType extends GTGroupIndex>
    on GTNavigationPage {
  /// The list of builders which must be initialized only once in the constructor of the sub class!
  late final List<BT> builders;

  /// Only used for logging
  int _debugCurIndex = 0;

  @override
  bool get allowTabTraversal => true;

  @override
  EdgeInsetsGeometry? getInnerPadding() => null;

  /// Calls [ConfigOptionBuilder.buildProviderWithContent] inside of a builder which then calls
  /// [ConfigOptionBuilder.buildContent] to build the content of the [MultiConfigOptionBuilder] (which is just the
  /// list of config options on the right part of the page)! May be overridden in sub classes! Used in
  /// [buildSearchState]
  Widget buildCurrentGroupOptions(BT builder) {
    return Builder(
      builder: (BuildContext context) {
        return FocusTraversalGroup(
          descendantsAreTraversable: false,
          child: builder.buildProviderWithContent(context, calledFromInnerGroup: false),
        );
      },
    );
  }

  /// Builds the [NavigationRail] (with some settings) by calling [MultiConfigOptionBuilder.buildGroupLabel] which
  /// returns the [NavigationRailDestination] with the icons and translation keys. May be overridden in the sub class!
  /// Used in [buildSearchState]
  Widget buildGroupLabels(BuildContext context, List<BT> searchedBuilders, int index) {
    final List<NavigationRailDestination> destinations = searchedBuilders
        .map((BT builder) => builder.buildGroupLabel(context))
        .toList();
    return FocusTraversalGroup(
      child: NavigationRail(
        selectedLabelTextStyle: TextStyle(color: colorPrimary(context)),
        minWidth: 140,
        backgroundColor: colorScaffoldBackground(context),
        selectedIndex: index,
        groupAlignment: -1.0,
        onDestinationSelected: (int index) => context.read<IndexType>().value = index,
        labelType: NavigationRailLabelType.all,
        destinations: destinations,
        scrollable: true,
      ),
    );
  }

  /// Used in [buildBody]
  Widget buildSearchState(BuildContext context, List<BT> searchedBuilders, int oldPos, BT oldBuilder) {
    late int currentPos;
    if (searchedBuilders.isEmpty) {
      return Center(
        child: Text(
          translate(const TS("input.search.not.found"), context),
          style: textTitleLarge(context).copyWith(color: colorError(context)),
        ),
      );
    } else if (searchedBuilders.length <= oldPos) {
      currentPos = searchedBuilders.length - 1;
    } else {
      currentPos = oldPos;
    }
    BT? newBuilder = searchedBuilders.elementAt(currentPos);
    if (newBuilder.groupName != oldBuilder.groupName) {
      newBuilder = searchedBuilders.where((BT builder) => builder.groupName == newBuilder!.groupName).firstOrNull;
      newBuilder ??= searchedBuilders.first;
    }
    if (newBuilder.groupName != oldBuilder.groupName) {
      Logger.verbose("Inner Nav Tab changed because of search: ${newBuilder.groupName}");
    }

    return Row(
      children: <Widget>[
        const SizedBox(width: 8),
        buildGroupLabels(context, searchedBuilders, currentPos),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: Padding(padding: pagePadding, child: buildCurrentGroupOptions(newBuilder)),
        ),
      ],
    );
  }

  @override
  Widget buildBody(BuildContext _) {
    return Consumer<IndexType>(
      builder: (BuildContext _, IndexType index, Widget? child) {
        final int pos = index.value;
        final BT builder = builders.elementAt(pos);
        if (pos != _debugCurIndex) {
          Logger.verbose("Inner Nav Tab selected: ${builder.groupName}");
        }
        _debugCurIndex = pos;
        return UIHelper.simpleConsumer<String>(
          builder: (BuildContext context, String searchString, Widget? innerChild) {
            final String upperCaseSearchString = searchString.toUpperCase();
            late final List<BT> searchedBuilders;
            if (searchString.isEmpty) {
              searchedBuilders = builders;
            } else {
              searchCallback(BT builder) => builder.containsSearch(context, upperCaseSearchString);
              searchedBuilders = builders.where(searchCallback).toList();
            }
            return buildSearchState(context, searchedBuilders, pos, builder);
          },
        );
      },
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) => buildAppBarDefaultTitle(
    key: ValueKey<String>(navigationLabel.identifier),
    navigationLabel,
    context,
    actions: <Widget>[
      SimpleSearchContainer(
        hintText: TS.combine(<TS>[const TS("input.search"), TS.raw(" "), navigationLabel], context),
      ),
      const SizedBox(width: 20),
    ],
  );

  @override
  List<SingleChildWidget> buildProviders(BuildContext context) => <SingleChildWidget>[
    ChangeNotifierProvider<IndexType>(create: createIndexSubclass),
    UIHelper.simpleProvider(createValue: (_) => ""),
  ];

  /// Must be overridden to create a new object of a unique subclass type of [GTGroupIndex]!
  IndexType createIndexSubclass(BuildContext context);
}
