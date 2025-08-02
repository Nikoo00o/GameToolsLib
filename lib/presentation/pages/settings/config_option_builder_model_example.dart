import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/domain/entities/base/entity.dart';
import 'package:game_tools_lib/domain/entities/base/model.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder_types.dart';

/// An example how to use a [ConfigOptionBuilderModel] with the [ExampleModel] used in
/// [ModelConfigOption.createExampleModelBuilder].
final class ConfigOptionBuilderModelExample extends ConfigOptionBuilderModel<ExampleModel?> {
  const ConfigOptionBuilderModelExample({
    required super.configOption,
  });

  Widget buildModifiableDataEditor(BuildContext context, ExampleModel? model) {
    final List<int> initialList =
        model?.modifiableData.map((ExampleEntity entity) => entity.someData ?? 0).toList() ?? <int>[];
    return buildListOption(
      title: "Modify some List",
      description: "Some other description...",
      elements: initialList,
      onChange: () {
        final List<ExampleEntity> mappedList = initialList
            .map<ExampleEntity>((int element) => ExampleModel(someData: element, modifiableData: <ExampleEntity>[]))
            .toList();
        configOption.setValue(ExampleModel(someData: model?.someData, modifiableData: mappedList));
      },
    );
  }

  @override
  Widget buildContent(BuildContext context, ExampleModel? model, {required bool calledFromInnerGroup}) {
    return buildMultiOptionsWithTitle(
      context: context,
      children: <Widget>[
        buildIntOption(
          title: "Modify some Data",
          description: "Some info description...",
          initialData: model?.someData,
          onChanged: (int? newValue) => configOption.setValue(
            ExampleModel(someData: newValue, modifiableData: model?.modifiableData ?? <ExampleEntity>[]),
          ),
        ),
        buildModifiableDataEditor(context, model),
      ],
    );
  }
}
