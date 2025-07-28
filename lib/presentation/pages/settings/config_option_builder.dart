import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';

/// Use subclasses of this to build the menu structure for the different classes of [MutableConfigOption].
///
/// Subclasses need to override [buildContent]
abstract base class ConfigOptionBuilder<T> {
  /// Reference to the option that this is build for
  final MutableConfigOption<T> configOption;

  const ConfigOptionBuilder({
    required this.configOption,
  });

  /// Builds the ui for the config option content
  Widget buildContent(BuildContext context);

  /// Returns the cached value of the [configOption]
  T? get value => configOption.cachedValue();
}

/// Subclasses of this are only for the custom and model config options, or for config option groups to also build
/// the label in the navigation bar with [buildGroupLabel]. [buildContent] still depends on the sub class.
abstract base class MultiConfigOptionBuilder<T> extends ConfigOptionBuilder<T> {
  const MultiConfigOptionBuilder({
    required super.configOption,
  });

  /// Menu structure in addition to [buildContent]!
  NavigationRailDestination buildGroupLabel(BuildContext context) {
    return NavigationRailDestination(
      padding: EdgeInsets.symmetric(vertical: 4),
      icon: Icon(Icons.keyboard_arrow_right),
      selectedIcon: Icon(Icons.keyboard_double_arrow_right),
      label: Text(GTBaseWidget.translateS(context, configOption.titleKey)),
    );
  }
}
