import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/domain/entities/base/entity.dart';
import 'package:game_tools_lib/domain/entities/base/model.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_helper_mixin.dart';
import 'package:game_tools_lib/presentation/pages/settings/gt_list_editor.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_card.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_text_field.dart';

/// This builds the menu label, but for the content each [ModelConfigOption] type needs its own subclass of this
/// builder to build the correct part of the page for the model [T]! Subclasses then need to override [buildContent]!
///
/// For an example look at [ConfigOptionBuilderModelExample].
///
/// Of course you could also use [defaultContentTile] here, or also customize your own [SimpleCard]'s and
/// [SimpleTextField] / [Switch] in a column, because you have the whole right side of the page available.
///
/// Remember that you might need to override [containsSearch] to only include your sub type config options instead of
/// the title!
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

  Widget buildModifiableDataEditor(BuildContext context, ExampleModel model) {
    final List<int> initialList = model.modifiableData.map((ExampleEntity entity) => entity.someData ?? 0).toList();
    return buildListOption(
      title: "Modify some List",
      description: "Some other description...",
      elements: initialList,
      onChange: () {
        final List<ExampleEntity> mappedList = initialList
            .map<ExampleEntity>((int element) => ExampleModel(someData: element, modifiableData: <ExampleEntity>[]))
            .toList();
        configOption.setValue(ExampleModel(someData: model.someData, modifiableData: mappedList));
      },
    );
  }

  @override
  Widget buildContent(BuildContext context, ExampleModel model) {
    return buildMultiOptionsWithTitle(
      context: context,
      children: <Widget>[
        buildIntOption(
          title: "Modify some Data",
          description: "Some info description...",
          initialData: model.someData ?? 0,
          onChanged: (int newValue) =>
              configOption.setValue(ExampleModel(someData: newValue, modifiableData: model.modifiableData)),
        ),
        buildModifiableDataEditor(context, model),
      ],
    );
  }
}

/// This builds the menu label and also the content for a [CustomConfigOption].
/// In this case you have to supply the [buildContentCallback] as well that is used in [buildContent]!
///
/// Of course you could also use [defaultContentTile] here, or also customize your own [SimpleCard]'s in a column,
/// because you have the whole right side of the page available. Also look at [containsSearchCallback].
final class ConfigOptionBuilderCustom<T> extends MultiConfigOptionBuilder<T> {
  /// This is the [CustomConfigOption.buildCustomContentWidget] to build the ui
  final Widget Function(BuildContext context, T customData) buildContentCallback;

  /// This should return true if your custom option should be shown for the [upperCaseSearchString] in the search bar.
  /// If this is null it will compare against the title.
  final bool Function(BuildContext context, String upperCaseSearchString)? containsSearchCallback;

  const ConfigOptionBuilderCustom({
    required CustomConfigOption<T> configOption,
    required this.buildContentCallback,
    this.containsSearchCallback,
  }) : super(configOption: configOption);

  @override
  Widget buildContent(BuildContext context, T customData) => buildContentCallback.call(context, customData);

  @override
  bool containsSearch(BuildContext context, String upperCaseSearchString) =>
      containsSearchCallback?.call(context, upperCaseSearchString) ??
      super.containsSearch(context, upperCaseSearchString);
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
