import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_grouped_builders_extension.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder_group.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder_types.dart';
import 'package:game_tools_lib/presentation/pages/settings/gt_settings_page.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_card.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_text_field.dart';
import 'package:provider/provider.dart';

/// Use subclasses of this to build the menu structure for the different classes of [MutableConfigOption] in the
/// [GTSettingsPage].
///
/// Subclasses need to override [buildContent] which will be called in the subtree of [buildProviderWithContent]
/// (this will be called automatically like a default build method!). For example [defaultContentTile] is used in
/// many sub classes. Or of course you can also manually use [SimpleCard], [SimpleTextField], etc.
///
/// The current stored config values for rebuilds is provided with consumer and providers, but to changes something,
/// [MutableConfigOption.setValue] should be used on the [configOption]
abstract base class ConfigOptionBuilder<T> with GTBaseWidget {
  /// Reference to the option that this is build for
  final MutableConfigOption<T> configOption;

  const ConfigOptionBuilder({
    required this.configOption,
  });

  /// Builds a [ChangeNotifierProvider] provider around for the [configOption] and also directly consumes it and
  /// calls [buildContent] every time the listeners are notified to build the right side of the ui!
  /// (this is called automatically)
  Widget buildProviderWithContent(BuildContext context) {
    return ChangeNotifierProvider<MutableConfigOption<T>>.value(
      value: configOption,
      child: Consumer<MutableConfigOption<T>>(
        builder: (BuildContext context, MutableConfigOption<T> option, Widget? child) {
          return buildContent(context, option.cachedValueNotNull());
        },
      ),
    );
  }

  /// Should build the right side ui for the config option content depending on the subclass.
  /// For example look at [defaultContentTile]
  Widget buildContent(BuildContext context, T value);

  /// Can be used in [buildContent] to build a list tile with the description and title if they are not null by using
  /// [SimpleCard]!
  Widget defaultContentTile(BuildContext context, Widget trailingWidget) {
    return SimpleCard(
      titleKey: configOption.titleKey,
      descriptionKey: configOption.descriptionKey,
      trailingActions: trailingWidget,
    );
  }

  /// Returns the cached value of the [configOption]
  T? get value => configOption.cachedValue();
}

/// Subclasses of this are only for the custom and model config options, or for config option groups to also build
/// the label in the navigation bar with [buildGroupLabel]. [buildContent] still depends on the sub class.
///
/// This also implements [GTGroupBuilderInterface], because it is the only config option builder that is directly
/// used in the [GTSettingsPage]. This is one of [ConfigOptionBuilderCustom], [ConfigOptionBuilderModel] or
/// [ConfigOptionBuilderGroup]
abstract base class MultiConfigOptionBuilder<T> extends ConfigOptionBuilder<T> implements GTGroupBuilderInterface {
  const MultiConfigOptionBuilder({
    required super.configOption,
  });

  /// Builds a Menu structure to the left of the [buildContent]!
  @override
  NavigationRailDestination buildGroupLabel(BuildContext context) {
    return NavigationRailDestination(
      padding: const EdgeInsets.symmetric(vertical: 4),
      icon: const Icon(Icons.keyboard_arrow_right),
      selectedIcon: const Icon(Icons.keyboard_double_arrow_right),
      label: Text(translate(context, configOption.titleKey)),
    );
  }
}
