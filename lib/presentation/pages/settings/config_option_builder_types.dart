import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/domain/entities/base/model.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder_group.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder_model_example.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_helper_mixin.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_card.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_text_field.dart';

/// This builds the menu label, but for the content each [ModelConfigOption] type needs its own subclass of this
/// builder to build the correct part of the page for the model [T]! Subclasses then need to override [buildContent]!
///
/// For an example look at [ConfigOptionBuilderModelExample] which uses a nullable type "[T]?".
///
/// Of course you could also use [defaultContentTile] here, or also customize your own [SimpleCard]'s and
/// [SimpleTextField] / [Switch] in a column, because you have the whole right side of the page available. For
/// multiple inner options [buildMultiOptionsWithTitle] should be build around and then [buildIntOption], etc can be
/// used inside.
///
/// Remember that you might need to override [containsSearch] to only include your sub type config options instead of
/// the title!
///
/// If this is build inside of a [ConfigOptionBuilderGroup] then the [buildContent] of this will be shown on a new
/// page and a config entry for this name is build that can navigate to that new page! Therefor you might want to
/// check the [calledFromInnerGroup] inside of [buildContent] and only build a title if that is true (when building
/// as entry of navigation rail instead of pushing a new page which already contains title in app bar on top!).
///
/// Remember building from navigation rail is only true when the config option was not inside of a config option group!
abstract base class ConfigOptionBuilderModel<T extends Model?> extends MultiConfigOptionBuilder<T> {
  const ConfigOptionBuilderModel({
    required ModelConfigOption<T> configOption,
  }) : super(configOption: configOption);
}

/// This builds the menu label and also the content for a [CustomConfigOption] where it is used internally (don't create
/// instances of this directly!).
///
/// Of course you could also use [defaultContentTile] in the [buildContentCallback], or also customize your own
/// [SimpleCard]'s in a column, because you have the whole right side of the page available. For multiple inner options
/// [buildMultiOptionsWithTitle] should be build around and then [buildIntOption], etc can be  used inside.
///
/// Also look at [containsSearchCallback]. And read through doc comments of [buildContentCallback]!
///
/// If this is build inside of a [ConfigOptionBuilderGroup] then the [buildContent] of this will be shown on a new
/// page and a config entry for this name is build that can navigate to that new page!
final class ConfigOptionBuilderCustom<T> extends MultiConfigOptionBuilder<T> {
  /// This is the [CustomConfigOption.buildCustomContentWidget] to build the ui which is shown in [buildContent]
  /// right side of this config option (or new page).
  ///
  /// Important: the [calledFromInnerGroup] is only true when the config option was built as a part of the navigation
  /// rail and then a title should be displayed at the top of the page. Otherwise if false then this is built as a
  /// new pushed page when the entry is clicked and the title was already built in the app bar!
  ///
  /// Remember building from navigation rail is only true when the config option was not inside of a config option group!
  final Widget Function(
    BuildContext context,
    T customData,
    ConfigOptionBuilderCustom<T> builder, {
    required bool calledFromInnerGroup,
  })
  buildContentCallback;

  /// This should return true if your custom option should be shown for the [upperCaseSearchString] in the search bar.
  /// If this is null it will compare against the title.
  final bool Function(BuildContext context, ConfigOptionBuilderCustom<T> builder, String upperCaseSearchString)?
  containsSearchCallback;

  const ConfigOptionBuilderCustom({
    required CustomConfigOption<T> configOption,
    required this.buildContentCallback,
    required this.containsSearchCallback,
  }) : super(configOption: configOption);

  @override
  Widget buildContent(BuildContext context, T customData, {required bool calledFromInnerGroup}) =>
      buildContentCallback.call(context, customData, this, calledFromInnerGroup: calledFromInnerGroup);

  @override
  bool containsSearch(BuildContext context, String upperCaseSearchString) =>
      containsSearchCallback?.call(context, this, upperCaseSearchString) ??
      super.containsSearch(context, upperCaseSearchString);
}

/// This is used to build the menu entries for config options of [TypeConfigOption]
final class ConfigOptionBuilderTypes<T> extends ConfigOptionBuilder<T> with ConfigOptionHelperMixin<T> {
  const ConfigOptionBuilderTypes({
    required TypeConfigOption<T> configOption,
  }) : super(configOption: configOption);

  void _setOption(T? newValue) {
    if (newValue == null && Utils.isNullableType<T>() == false) {
      Logger.verbose("Skipped updating non nullable $configOption with an empty field(null)");
    } else {
      configOption.setValue(newValue as T);
    }
  }

  @override
  Widget buildContent(BuildContext context, T currentData, {required bool calledFromInnerGroup}) {
    if (Utils.isSameOrNullableType<T, bool>()) {
      return buildBoolOption(
        title: configOption.title,
        description: configOption.description,
        initialData: currentData as bool?,
        onChanged: (bool newState) => configOption.setValue(newState as T),
      );
    } else if (Utils.isSameOrNullableType<T, String>()) {
      return buildStringOption(
        title: configOption.title,
        description: configOption.description,
        initialData: currentData as String?,
        onChanged: (String newValue) => configOption.setValue(newValue as T),
      );
    } else if (Utils.isSameOrNullableType<T, int>()) {
      return buildIntOption(
        title: configOption.title,
        description: configOption.description,
        initialData: currentData as int?,
        onChanged: (int? newValue) => _setOption(newValue as T?),
      );
    } else if (Utils.isSameOrNullableType<T, double>()) {
      return buildDoubleOption(
        title: configOption.title,
        description: configOption.description,
        initialData: currentData as double?,
        onChanged: (double? newValue) => _setOption(newValue as T?),
      );
    }
    throw ConfigException(message: "ConfigOptionBuilderTypes got invalid config type $T from $configOption");
  }
}

/// This is used to build the menu entries for config options of [FileConfigOption]
final class FileConfigOptionBuilder extends ConfigOptionBuilder<String> with ConfigOptionHelperMixin<String> {
  const FileConfigOptionBuilder({
    required FileConfigOption configOption,
  }) : super(configOption: configOption);

  @override
  Widget buildContent(BuildContext context, String currentData, {required bool calledFromInnerGroup}) {
    return SimpleCard(
      title: configOption.title,
      description: configOption.description,
      // todo: implement file picker!
      trailingActions: SimpleTextField<String>(
        width: 280,
        initialValue: currentData ?? "",
        onChanged: (String newValue) => configOption.setValue(newValue),
      ),
    );
  }
}

/// This is used to build the menu entries for config options of [TypeConfigOption]
final class ConfigOptionBuilderEnum<T> extends ConfigOptionBuilder<T> with ConfigOptionHelperMixin<T> {
  const ConfigOptionBuilderEnum({
    required EnumConfigOption<T> configOption,
  }) : super(configOption: configOption);

  EnumConfigOption<T> get enumOption => configOption as EnumConfigOption<T>;

  @override
  Widget buildContent(BuildContext context, T selectedData, {required bool calledFromInnerGroup}) {
    return buildEnumOption<T>(
      title: configOption.title,
      description: configOption.description,
      availableOptions: enumOption.availableOptions,
      initialValue: configOption.cachedValueNotNull(),
      onValueChange: (T? newValue) => configOption.setValue(newValue as T),
      convertToTranslationKeys: enumOption.convertToTranslationKeys,
    );
  }
}
