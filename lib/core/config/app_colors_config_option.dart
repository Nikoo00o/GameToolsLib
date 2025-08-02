import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/enums/gt_contrast.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_app_theme.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder_types.dart';
import 'package:game_tools_lib/presentation/widgets/helper/changes/simple_change_notifier.dart';

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
         titleKey: "config.appColors",
         descriptionKey: "config.appColors.description",
       );

  static GTAppTheme? _createNewInstance(String? str) {
    return null; // todo: implement all
  }

  static String? _convertInstanceToString(GTAppTheme? data) {
    return null;
  }

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
          title: "config.appColors.contrast",
          availableOptions: GTContrast.values,
          initialValue: data.contrast,
          onValueChange: (GTContrast newValue) {
            Logger.verbose("Contrast: $newValue");
            // todo: set config value with config from builder with copywidth and replacing
          },
          convertToTranslationKeys: (GTContrast contrast) => switch (contrast) {
            GTContrast.DEFAULT => "input.default",
            GTContrast.MEDIUM => "input.medium",
            GTContrast.HIGH => "input.high",
          },
        ),

        builder.buildMultiSelection<WrappedBool>(
          title: "test",
          entries: testList,
          rows: 3,
          convertToTranslationKeys: (WrappedBool entry) => testList.indexOf(entry).toString(),
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
}

class WrappedBool {
  bool value;

  WrappedBool(this.value);
}
