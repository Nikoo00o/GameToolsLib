import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder.dart';
import 'package:game_tools_lib/presentation/pages/settings/gt_settings_page.dart';

/// This is used to build the menu entries for config groups of [MutableConfigOptionGroup] in the [GTSettingsPage].
///
/// Calls [ConfigOptionBuilder.buildProviderWithContent] which then calls [ConfigOptionBuilder.buildContent] on the [builders]
/// children options!
final class ConfigOptionBuilderGroup extends MultiConfigOptionBuilder<List<MutableConfigOption<dynamic>>> {
  late final List<ConfigOptionBuilder<dynamic>> builders;

  ConfigOptionBuilderGroup({
    required MutableConfigOptionGroup configOption,
  }) : super(configOption: configOption) {
    final List<MutableConfigOption<dynamic>> children = value!;
    builders = children.map((MutableConfigOption<dynamic> option) {
      final ConfigOptionBuilder<dynamic>? builder = option.builder;
      if (builder == null) {
        throw ConfigException(
          message:
              "Config Option $option did not contain a builder, "
              "but was used in MutableConfig.getConfigurableOptions",
        );
      } else if (builder is MultiConfigOptionBuilder<dynamic>) {
        throw ConfigException(
          message:
              "Config Option $option returned builder ${builder.runtimeType} in a group! "
              "Remember to not use any nested group, model, or custom config option!",
        );
      }
      return builder;
    }).toList();
  }

  @override
  Widget buildProviderWithContent(BuildContext context) {
    return ListView.builder(
      itemCount: builders.length,
      itemBuilder: (BuildContext context, int index) {
        final ConfigOptionBuilder<dynamic> builder = builders.elementAt(index);
        return builder.buildProviderWithContent(context);
      },
    );
  }

  @override
  Widget buildContent(BuildContext context, List<MutableConfigOption<dynamic>> value) {
    throw UnimplementedError(); // this will never be called
  }
}
