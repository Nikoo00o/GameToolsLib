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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Spacer(),
        Text("${translate(context, configOption.titleKey)} specific settings: ..."),
        const Spacer(),
        SimpleCard(
          titleKey: "Modify Some Data",
          descriptionKey: "Some info",
          trailingActions: SimpleTextField<int>(
            width: 140,
            initialValue: model.someData?.toString() ?? "",
            onChanged: (String newValue) {
              configOption.setValue(ExampleModel(someData: int.parse(newValue), modifiableData: model.modifiableData));
            },
          ),
        ),
        const Spacer(),
        Text("Modifiable Data count: ${model.modifiableData.length}"),
        const Spacer(),
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
final class ConfigOptionBuilderTypes<T> extends ConfigOptionBuilder<T> {
  const ConfigOptionBuilderTypes({
    required TypeConfigOption<T> configOption,
  }) : super(configOption: configOption);

  String get stringValue => value?.toString() ?? "";

  Widget _buildInput(BuildContext context, T currentData) {
    if (T == bool) {
      return Switch(
        value: currentData as bool,
        onChanged: (bool newState) => configOption.setValue(newState as T),
      );
    } else if (T == String) {
      return SimpleTextField<String>(
        width: 280,
        initialValue: stringValue,
        onChanged: (String newValue) => configOption.setValue(newValue as T),
      );
    } else if (T == int) {
      return SimpleTextField<int>(
        width: 140,
        initialValue: stringValue,
        onChanged: (String newValue) => configOption.setValue(int.parse(newValue) as T),
      );
    } else if (T == double) {
      return SimpleTextField<double>(
        width: 140,
        initialValue: stringValue,
        onChanged: (String newValue) => configOption.setValue(double.parse(newValue) as T),
      );
    }
    throw ConfigException(message: "ConfigOptionBuilderTypes got invalid config type $T from $configOption");
  }

  @override
  Widget buildContent(BuildContext context, T currentData) {
    return defaultContentTile(
      context,
      _buildInput(context, currentData),
    );
  }
}

/// This is used to build the menu entries for config options of [TypeConfigOption]
final class ConfigOptionBuilderEnum<T> extends ConfigOptionBuilder<T> {
  const ConfigOptionBuilderEnum({
    required EnumConfigOption<T> configOption,
  }) : super(configOption: configOption);

  EnumConfigOption<T> get enumOption => configOption as EnumConfigOption<T>;

  @override
  Widget buildContent(BuildContext context, T selectedData) {
    return defaultContentTile(
      context,
      SimpleDropDownMenu<T>(
        height: 40,
        maxWidth: 250,
        values: enumOption.availableOptions,
        initialValue: configOption.cachedValueNotNull(),
        onValueChange: (T? newValue) => configOption.setValue(newValue as T),
        translationKeys: enumOption.convertToTranslationKeys,
      ),
    );
  }
}
