import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_grouped_builders_extension.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigation_page.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder_group.dart';
import 'package:provider/provider.dart';

/// A [GTNavigationPage] that contains all config options from [MutableConfig.getConfigurableOptions] by using
/// [GTGroupedBuildersExtension] with [MultiConfigOptionBuilder]\<dynamic\> as the type to use the builders for the
/// config options and [GTSettingsGroupIndex] for the index which is also provided for [Consumer]'s further down the
/// widget tree!
///
/// This builds an internal config group navigation bar to navigate through the [MutableConfigOptionGroup],
/// [ModelConfigOption] and [CustomConfigOption] of [MutableConfig.getConfigurableOptions] in [buildBody]'s
/// [buildGroupLabels]. Then the individual config options on the right part of a page are build with
/// [buildCurrentGroupOptions] by using the [ConfigOptionBuilder] subclasses!
base class GTSettingsPage extends GTNavigationPage
    with GTGroupedBuildersExtension<MultiConfigOptionBuilder<dynamic>, GTSettingsGroupIndex> {
  /// For the remaining options with no group
  static const TranslationString otherGroup = TS("page.settings.group.other");

  GTSettingsPage({
    super.key,
    super.backgroundImage,
    super.backgroundColor,
    super.pagePadding,
  }) {
    builders = <MultiConfigOptionBuilder<dynamic>>[];
    final List<MutableConfigOption<dynamic>> options = MutableConfig.mutableConfig.configurableOptions;
    Logger.spam("Building GTSettingsPage options: ", options);
    final List<MutableConfigOption<dynamic>> otherRemaining = <MutableConfigOption<dynamic>>[];
    for (final MutableConfigOption<dynamic> option in options) {
      if (option.builder == null) {
        throw ConfigException(
          message:
              "Config Option $option did not contain a builder, "
              "but was used in MutableConfig.getConfigurableOptions",
        );
      } else if (option.builder is MultiConfigOptionBuilder<dynamic>) {
        builders.add(option.builder as MultiConfigOptionBuilder<dynamic>);
      } else {
        otherRemaining.add(option);
      }
    }
    if (otherRemaining.isNotEmpty) {
      final MutableConfigOptionGroup other = MutableConfigOptionGroup(
        title: otherGroup,
        configOptions: otherRemaining,
      );
      builders.add(ConfigOptionBuilderGroup(configOption: other));
    }
  }

  @override
  String get pageName => "GTSettingsPage";

  @override
  TranslationString get navigationLabel => const TS("page.settings.title");

  @override
  IconData get navigationNotSelectedIcon => Icons.settings_outlined;

  @override
  IconData get navigationSelectedIcon => Icons.settings;

  @override
  GTSettingsGroupIndex createIndexSubclass(BuildContext context) => GTSettingsGroupIndex(0);
}

/// The specific subclass used for [GTSettingsPage] to provide the current config group index
final class GTSettingsGroupIndex extends GTGroupIndex {
  GTSettingsGroupIndex(super.value);
}
