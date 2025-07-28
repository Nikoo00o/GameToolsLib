import 'package:flutter/cupertino.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/domain/entities/base/model.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder.dart';

/// This is used to build the menu entries for config groups of [MutableConfigOptionGroup]
final class ConfigOptionBuilderGroup extends MultiConfigOptionBuilder<List<MutableConfigOption<dynamic>>> {
  List<MutableConfigOption<dynamic>> get children => value!;

  const ConfigOptionBuilderGroup({
    required MutableConfigOptionGroup configOption,
  }) : super(configOption: configOption);

  @override
  Widget buildContent(BuildContext context) {
    final List<MutableConfigOption<dynamic>> children = this.children;
    return ListView.builder(
      itemCount: children.length,
      itemBuilder: (BuildContext context, int index) {
        final ConfigOptionBuilder<dynamic> builder = children
            .elementAt(index)
            .builder;
        if (builder is MultiConfigOptionBuilder<dynamic>) {
          throw ConfigException(
            message:
            "Config Option ${children.elementAt(index)} returned builder ${builder.runtimeType} in a group! "
                "Remember to not use any nested group, model, or custom config option!",
          );
        }
        final Widget child = builder.buildContent(context);
        return child; // todo: maybe padding
      },
    );
  }
}

/// This builds the menu label, but for the content each [ModelConfigOption] type needs its own subclass of this
/// builder to build the correct part of the page for the model [T]! Subclasses then need to override [buildContent]!
abstract base class ConfigOptionBuilderModel<T extends Model> extends MultiConfigOptionBuilder<T> {
  const ConfigOptionBuilderModel({
    required ModelConfigOption<T> configOption,
  }) : super(configOption: configOption);

}


/// This is used to build the menu entries for config options of [TypeConfigOption]
final class ConfigOptionBuilderTypes<T> extends ConfigOptionBuilder<T> {
  const ConfigOptionBuilderTypes({
    required TypeConfigOption<T> configOption,
  }) : super(configOption: configOption);

  @override
  Widget buildContent(BuildContext context) {
    // todo: compare types and build depending on it
    return Text(configOption.titleKey);
  }
}

/// This is used to build the menu entries for config options of [TypeConfigOption]
final class ConfigOptionBuilderTypes<T> extends ConfigOptionBuilder<T> {
  const ConfigOptionBuilderTypes({
    required TypeConfigOption<T> configOption,
  }) : super(configOption: configOption);

  @override
  Widget buildContent(BuildContext context) {
    // todo: compare types and build depending on it
    return Text(configOption.titleKey);
  }
}