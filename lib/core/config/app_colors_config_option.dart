import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/enums/gt_contrast.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_app_theme.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder_types.dart';

/// This is an example on how to use the [CustomConfigOption] here with the [GTAppTheme] as a new class.
///
/// It also builds the ui to configure the data! And static callbacks are used for all available parameters.
final class AppColorsConfigOption extends CustomConfigOption<GTAppTheme> {
  /// The [defaultValue] is the only option that can use the [GTAppTheme.seed] constructor
  AppColorsConfigOption({
    super.defaultValue,
  }) : super(
         createNewInstance: _createNewInstance,
         convertInstanceToString: _convertInstanceToString,
         buildCustomContentWidget: _buildCustomContentWidget,
         containsSearchCallback: _containsSearchCallback,
         lazyLoaded: false,
         onInit: null,
         updateCallback: null,
         title: const TS("config.appColors"),
         description: const TS("config.appColors.description"),
       );

  static GTAppTheme? _createNewInstance(String? str) => str != null ? GTAppTheme.fromString(str) : null;

  static String? _convertInstanceToString(GTAppTheme? data) => data?.toString();

  static List<WrappedBool> testList = <WrappedBool>[
    WrappedBool(false),
    WrappedBool(true),
    WrappedBool(false),
    WrappedBool(true),
    WrappedBool(true),
    WrappedBool(true),
    WrappedBool(true),
    WrappedBool(false),
    WrappedBool(false),
    WrappedBool(false),
    WrappedBool(false),
    WrappedBool(false),
    WrappedBool(false),
    WrappedBool(false),
    WrappedBool(false),
    WrappedBool(false),
    WrappedBool(false),
    WrappedBool(false),
  ];

  static Widget _buildCustomContentWidget(
    BuildContext context,
    GTAppTheme data,
    ConfigOptionBuilderCustom<GTAppTheme> builder, {
    required bool calledFromInnerGroup,
  }) {
    return ListView(
      children: <Widget>[
        builder.buildEnumSliderOption<GTContrast>(
          title: const TS("config.appColors.contrast"),
          availableOptions: GTContrast.values,
          initialValue: data.contrast,
          onValueChange: (GTContrast newContrast) =>
              _option.setValue(_option.cachedValueNotNull().copyWith(newContrast: newContrast)),
          convertToTranslationKeys: (GTContrast contrast) => TS(switch (contrast) {
            GTContrast.DEFAULT => "input.default",
            GTContrast.MEDIUM => "input.medium",
            GTContrast.HIGH => "input.high",
          }),
        ),
        Row(
          children: <Widget>[
            FilledButton(
              onPressed: () {},
              child: Text(builder.translate(const TS("input.adjust", <String>["primary"]), context)),
            ),
            FilledButton(
              onPressed: () => _option.deleteValue(),
              child: Text(builder.translate(const TS("input.reset.to.default"), context)),
            ),
          ],
        ),
        builder.buildMultiSelection<WrappedBool>(
          title: TS.raw("test"),
          entries: testList,
          convertToTranslationKeys: (WrappedBool entry) => TS.raw(testList.indexOf(entry).toString()),
          isEntrySelected: (WrappedBool entry) => entry.value,
          onSelectionChanged: (WrappedBool entry, {required bool isNowSelected}) {
            entry.value = isNowSelected;
          },
        ),
      ],
    );
  }

  static bool _containsSearchCallback(BuildContext context, String upperCaseSearchString) {
    return true;
  }

  static AppColorsConfigOption get _option => MutableConfig.mutableConfig.appColors;
}

class WrappedBool {
  bool value;

  WrappedBool(this.value);
}
