import 'package:flutter/material.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_grouped_builders_extension.dart';

/// Subclasses of this are only for the custom and model config options, or for config option groups to also build
/// the label in the navigation bar with [buildGroupLabel]. [buildContent] still depends on the sub class.
base class HotkeyGroupBuilder with GTBaseWidget implements GTGroupBuilderInterface {
  final String groupLabel;
  final List<BaseInputListener<dynamic>> inputListener;

  const HotkeyGroupBuilder({
    required this.groupLabel,
    required this.inputListener,
  });

  /// Builds a Menu structure in addition to [buildContent]!
  @override
  NavigationRailDestination buildGroupLabel(BuildContext context) {
    return NavigationRailDestination(
      padding: const EdgeInsets.symmetric(vertical: 4),
      icon: const Icon(Icons.keyboard_arrow_right),
      selectedIcon: const Icon(Icons.keyboard_double_arrow_right),
      label: Text(translate(context, groupLabel)),
    );
  }

  @override
  Widget buildProviderWithContent(BuildContext context) {
    return ListView.builder(
      itemCount: inputListener.length,
      itemBuilder: (BuildContext context, int index) {
        final BaseInputListener<dynamic> listener = inputListener.elementAt(index);
        return Text(listener.configLabel); // todo: build different listeners
      },
    );
  }
}
