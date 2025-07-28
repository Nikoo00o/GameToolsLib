import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigation_page.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder_types.dart';
import 'package:game_tools_lib/presentation/widgets/helper/changes/simple_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

// todo: implement and document
base class GTSettingsPage extends GTNavigationPage {
  final List<MultiConfigOptionBuilder<dynamic>> _builders;

  GTSettingsPage({
    super.key,
    super.backgroundImage,
    super.backgroundColor,
    super.pagePadding,
  }) : _builders = <MultiConfigOptionBuilder<dynamic>>[] {
    final List<MutableConfigOption<dynamic>> options = MutableConfig.mutableConfig.getConfigurableOptions();
    final List<MutableConfigOption<dynamic>> otherRemaining = <MutableConfigOption<dynamic>>[];
    for (final MutableConfigOption<dynamic> option in options) {
      if (option.builder is MultiConfigOptionBuilder<dynamic>) {
        _builders.add(option.builder as MultiConfigOptionBuilder<dynamic>);
      } else {
        otherRemaining.add(option);
      }
    }
    if (otherRemaining.isNotEmpty) {
      final MutableConfigOptionGroup other = MutableConfigOptionGroup(
        titleKey: "page.settings.group.other",
        configOptions: otherRemaining,
      );
      _builders.add(ConfigOptionBuilderGroup(configOption: other));
    }
  }

  Widget buildCurrentGroupOptions(BuildContext context, MultiConfigOptionBuilder<dynamic> builder) {
    return builder.buildContent(context);
  }

  Widget buildGroupLabels(BuildContext context, int index) {
    final List<NavigationRailDestination> destinations = _builders
        .map((MultiConfigOptionBuilder<dynamic> builder) => builder.buildGroupLabel(context))
        .toList();
    return NavigationRail(
      selectedLabelTextStyle: TextStyle(color: colorPrimary(context)),
      minWidth: 100,
      elevation: 15,
      selectedIndex: index,
      groupAlignment: -1.0,
      onDestinationSelected: (int index) => context.read<GTSettingsIndex>().value = index,
      labelType: NavigationRailLabelType.all,
      destinations: destinations,
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return Consumer<GTSettingsIndex>(
      builder: (BuildContext context, GTSettingsIndex index, Widget? child) {
        final int pos = index.value;
        return Row(
          children: <Widget>[
            buildGroupLabels(context, pos),
            SizedBox(width: 10),
            Expanded(child: buildCurrentGroupOptions(context, _builders.elementAt(pos))),
          ],
        );
      },
    );
  }

  @override
  List<SingleChildWidget> buildProviders(BuildContext context) => <SingleChildWidget>[
    ChangeNotifierProvider<GTSettingsIndex>(create: (BuildContext context) => GTSettingsIndex(0)),
  ];

  @override
  String get pageName => "GTSettingsPage";

  @override
  String get navigationLabel => "page.settings.title";

  @override
  IconData get navigationNotSelectedIcon => Icons.settings_outlined;

  @override
  IconData get navigationSelectedIcon => Icons.settings;
}

/// This class stores the current index of [GTSettingsPage] which settings group is selected
final class GTSettingsIndex extends SimpleChangeNotifier<int> {
  GTSettingsIndex(super.value);
}
