import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/domain/entities/base/model.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_card.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_drop_down_menu.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_text_field.dart';

/// This builds the menu label, but for the content each [ModelConfigOption] type needs its own subclass of this
/// builder to build the correct part of the page for the model [T]! Subclasses then need to override [buildContent]!
///
/// For an example look at [ConfigOptionBuilderModelExample].
///
/// Of course you could also use [defaultContentTile] here, or also customize your own [SimpleCard]'s and
/// [SimpleTextField] / [Switch] in a column, because you have the whole right side of the page available.
abstract base class ConfigOptionBuilderModel<T extends Model> extends MultiConfigOptionBuilder<T> {
  const ConfigOptionBuilderModel({
    required ModelConfigOption<T> configOption,
  }) : super(configOption: configOption);
}

/// An example how to use a [ConfigOptionBuilderModel] with the [ExampleModel] used in
/// [ModelConfigOption.createExampleModelBuilder].
final class ConfigOptionBuilderModelExample extends ConfigOptionBuilderModel<ExampleModel> {
  const ConfigOptionBuilderModelExample({
    required super.configOption,
  });

  @override
  Widget buildContent(BuildContext context, ExampleModel model) {
    return buildMultiOptionsWithTitle(
      context: context,
      children: <Widget>[
        buildIntOption(
          title: "Modify Some Data",
          description: "Some info description...",
          initialData: model.someData ?? 0,
          onChanged: (int newValue) =>
              configOption.setValue(ExampleModel(someData: newValue, modifiableData: model.modifiableData)),
        ),
      ],
    );
  }
}

/// This builds the menu label and also the content for a [CustomConfigOption].
/// In this case you have to supply the [buildContentCallback] as well that is used in [buildContent]!
///
/// Of course you could also use [defaultContentTile] here, or also customize your own [SimpleCard]'s in a column,
/// because you have the whole right side of the page available.
final class ConfigOptionBuilderCustom<T> extends MultiConfigOptionBuilder<T> {
  /// This is the [CustomConfigOption.buildCustomContentWidget] to build the ui
  final Widget Function(BuildContext context, T customData) buildContentCallback;

  const ConfigOptionBuilderCustom({
    required CustomConfigOption<T> configOption,
    required this.buildContentCallback,
  }) : super(configOption: configOption);

  @override
  Widget buildContent(BuildContext context, T customData) => buildContentCallback.call(context, customData);
}

/// This is used to build the menu entries for config options of [TypeConfigOption]
final class ConfigOptionBuilderTypes<T> extends ConfigOptionBuilder<T> with ConfigOptionHelperMixin<T> {
  const ConfigOptionBuilderTypes({
    required TypeConfigOption<T> configOption,
  }) : super(configOption: configOption);

  @override
  Widget buildContent(BuildContext context, T currentData) {
    if (T == bool) {
      return buildBoolOption(
        title: configOption.titleKey,
        description: configOption.descriptionKey,
        initialData: currentData as bool,
        onChanged: (bool newState) => configOption.setValue(newState as T),
      );
    } else if (T == String) {
      return buildStringOption(
        title: configOption.titleKey,
        description: configOption.descriptionKey,
        initialData: currentData as String,
        onChanged: (String newValue) => configOption.setValue(newValue as T),
      );
    } else if (T == int) {
      return buildIntOption(
        title: configOption.titleKey,
        description: configOption.descriptionKey,
        initialData: currentData as int,
        onChanged: (int newValue) => configOption.setValue(newValue as T),
      );
    } else if (T == double) {
      return buildDoubleOption(
        title: configOption.titleKey,
        description: configOption.descriptionKey,
        initialData: currentData as double,
        onChanged: (double newValue) => configOption.setValue(newValue as T),
      );
    }
    throw ConfigException(message: "ConfigOptionBuilderTypes got invalid config type $T from $configOption");
  }
}

/// This is used to build the menu entries for config options of [TypeConfigOption]
final class ConfigOptionBuilderEnum<T> extends ConfigOptionBuilder<T> with ConfigOptionHelperMixin<T> {
  const ConfigOptionBuilderEnum({
    required EnumConfigOption<T> configOption,
  }) : super(configOption: configOption);

  EnumConfigOption<T> get enumOption => configOption as EnumConfigOption<T>;

  @override
  Widget buildContent(BuildContext context, T selectedData) {
    return buildEnumOption<T>(
      title: configOption.titleKey,
      description: configOption.descriptionKey,
      availableOptions: enumOption.availableOptions,
      initialValue: configOption.cachedValueNotNull(),
      onValueChange: (T? newValue) => configOption.setValue(newValue as T),
      convertToTranslationKeys: enumOption.convertToTranslationKeys,
    );
  }
}

/// Provides useful helper methods to build the widgets of a [ConfigOptionBuilder] for the config options with for
/// example [defaultContentTile], [buildBoolOption], etc
base mixin ConfigOptionHelperMixin<T> on ConfigOptionBuilder<T> {
  /// Can be used in [ConfigOptionBuilder.buildContent] to build a list tile with the description and title if they
  /// are not null by using [SimpleCard] with the [configOption] and then adding additional methods on the right with
  /// [trailingWidget]!
  Widget defaultContentTile(Widget trailingWidget) {
    return SimpleCard(
      titleKey: configOption.titleKey,
      descriptionKey: configOption.descriptionKey,
      trailingActions: trailingWidget,
    );
  }

  /// Builds a list tile with a bool option
  Widget buildBoolOption({
    required String title,
    String? description,
    required bool initialData,
    required ValueChanged<bool> onChanged,
  }) {
    return SimpleCard(
      titleKey: title,
      descriptionKey: description,
      trailingActions: Switch(
        value: initialData,
        onChanged: onChanged,
      ),
    );
  }

  /// Builds a list tile with a string option
  Widget buildStringOption({
    required String title,
    String? description,
    required String initialData,
    required ValueChanged<String> onChanged,
  }) {
    return SimpleCard(
      titleKey: title,
      descriptionKey: description,
      trailingActions: SimpleTextField<String>(
        width: 280,
        initialValue: initialData,
        onChanged: onChanged,
      ),
    );
  }

  /// Builds a list tile with an int option
  Widget buildIntOption({
    required String title,
    String? description,
    required int initialData,
    required ValueChanged<int> onChanged,
  }) {
    return SimpleCard(
      titleKey: title,
      descriptionKey: description,
      trailingActions: SimpleTextField<int>(
        width: 140,
        initialValue: initialData.toString(),
        onChanged: (String newValue) => onChanged.call(int.parse(newValue)),
      ),
    );
  }

  /// Builds a list tile with a double option
  Widget buildDoubleOption({
    required String title,
    String? description,
    required double initialData,
    required ValueChanged<double> onChanged,
  }) {
    return SimpleCard(
      titleKey: title,
      descriptionKey: description,
      trailingActions: SimpleTextField<double>(
        width: 140,
        initialValue: initialData.toString(),
        onChanged: (String newValue) => onChanged.call(double.parse(newValue.replaceAll(',', '.'))),
      ),
    );
  }

  /// Builds a list tile with an enum option
  Widget buildEnumOption<ET>({
    required String title,
    String? description,
    required List<ET> availableOptions,
    required ET initialValue,
    required void Function(ET? newValue) onValueChange,
    required String Function(ET value)? convertToTranslationKeys,
  }) {
    return SimpleCard(
      titleKey: title,
      descriptionKey: description,
      trailingActions: SimpleDropDownMenu<ET>(
        height: 40,
        maxWidth: 250,
        values: availableOptions,
        initialValue: initialValue,
        onValueChange: onValueChange,
        translationKeys: convertToTranslationKeys,
      ),
    );
  }

  /// Builds a column with the [MutableConfigOption.titleKey] from [configOption] as the title at the top
  /// (optional [MutableConfigOption.descriptionKey] if not null as well) and the [children] as a list view below that.
  Widget buildMultiOptionsWithTitle({
    required BuildContext context,
    required List<Widget> children,
  }) {
    return Column(
      children: <Widget>[
        Text(
          translate(context, configOption.titleKey),
          style: textTitleLarge(context).copyWith(color: colorPrimary(context)),
          textAlign: TextAlign.center,
        ),
        if (configOption.descriptionKey != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 8, 0),
              child: Text(
                translate(context, configOption.descriptionKey!),
                textAlign: TextAlign.left,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textBodyMedium(context).copyWith(color: colorSecondary(context)),
              ),
            ),
          ),
        const SizedBox(height: 25),
        Expanded(child: ListView(children: children)),
      ],
    );
  }
}
