import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:game_tools_lib/core/config/app_colors_config_option.dart';
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/config/locale_config_option.dart';
import 'package:game_tools_lib/core/enums/log_level.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/domain/entities/base/model.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_config.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_app_theme.dart';
import 'package:game_tools_lib/presentation/pages/debug/gt_debug_page.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder_group.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder_model_example.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder_types.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_helper_mixin.dart';

part 'package:game_tools_lib/core/config/mutable_config_option.dart';

part 'package:game_tools_lib/core/config/mutable_config_option_types.dart';

part 'package:game_tools_lib/core/config/mutable_config_option_group.dart';

/// Base class storing all mutable config values which are dynamically stored in a local storage file and may change
/// during the runtime of the application. The members should always be final objects (like [logLevel])! If you want
/// to override default values in sub classes look at [ExampleMutableConfig])
///
/// For more info (and an example) look at the general documentation of [GameToolsConfig]
///
/// Here the config values are stored as getters of a subtype of [MutableConfigOption]: [BoolConfigOption],
/// [IntConfigOption], [DoubleConfigOption], [StringConfigOption], [EnumConfigOption],
/// And for more complex data [ModelConfigOption] with your model type!
/// But if you want to use custom options with complete freedom, then use [CustomConfigOption] (rarely needed)!
///
/// Access the values async with [MutableConfigOption.getValue] at least once (afterwards you could also access the
/// cached value in a sync way with [MutableConfigOption.cachedValue]!
///
/// Remember for initialization of your mutable config members, you can not access anything in the constructor, so if
/// you need to reply on other config options, etc, use [MutableConfigOption.onInit]!
///
/// Look at [getConfigurableOptions] which you can optionally override depending on which config options you want
/// to be able to be modified in the UI. Those will also be loaded once automatically on startup in
/// [loadAllConfigurableOptions]. Important: access those from the outside cached with [configurableOptions] instead!
base class MutableConfig {
  /// The current [logLevel] of the logger. All logs with a higher value than this will be ignored and only
  /// the more important logs with a lower [LogLevel] will be printed and stored!
  /// Default is [LogLevel.SPAM] to log everything!
  final LogLevelConfigOption logLevel = LogLevelConfigOption(titleKey: "config.logLevel", defaultValue: LogLevel.SPAM);

  /// Controls if the ui is displayed as dark, or light theme
  final BoolConfigOption useDarkTheme = BoolConfigOption(titleKey: "config.useDarkTheme", defaultValue: true);

  /// The current language which is null per default and will return the system language if its null.
  /// But if the current system language is not supported, then internally this will fallback to the first entry of
  /// [FixedConfig.supportedLocales]!
  /// Important: use [LocaleConfigOption.activeLocale] to access the locale that is used in the app!
  final LocaleConfigOption currentLocale = LocaleConfigOption(titleKey: "config.currentLocale");

  /// You should override this to customize the colors of your app in regards to the material 3 theme!
  /// https://m3.material.io/styles/color/system/how-the-system-works#094adbe5-d41e-49b4-8dff-906d6094668d
  final AppColorsConfigOption appColors = AppColorsConfigOption(
    defaultValue: const GTAppTheme.seed(seedColor: Color(0xff004A95), baseSuccessColor: Colors.green),
  );

  /// Controls how the window names will be matched ([false] = window title only has to contain the [GameWindow.name].
  /// Otherwise if [true] it has to be exactly the same). Used for [GameWindow], default is [false].
  /// Per default this is only included in the [GTDebugPage] and not in [getConfigurableOptions]!
  final BoolConfigOption alwaysMatchGameWindowNamesEqual = BoolConfigOption(
    titleKey: "config.alwaysMatchGameWindowNamesEqual",
    descriptionKey: "config.alwaysMatchGameWindowNamesEqual.description",
    defaultValue: true,
    updateCallback: _updateGameWindowConfigValues,
  );

  /// This is a debug variable to print out all opened windows if set to true. Used for [GameWindow], default is
  /// [false].
  /// Per default this is only included in the [GTDebugPage] and not in [getConfigurableOptions]!
  final BoolConfigOption debugPrintGameWindowNames = BoolConfigOption(
    titleKey: "config.debugPrintGameWindowNames",
    descriptionKey: "config.debugPrintGameWindowNames.description",
    defaultValue: false,
    updateCallback: _updateGameWindowConfigValues,
  );

  /// You can override this to return references to those config options you want to be able to modify in the UI!
  ///
  /// Important: you can group your config options except [ModelConfigOption] and [CustomConfigOption] with
  /// [MutableConfigOptionGroup] and only use those inside of them! If you use any other config option except model
  /// and custom outside of a group, they will automatically be put in the group "Other"!
  ///
  /// Remember to also add the config options from here if you want to by calling the super method and then add your
  /// own config options like for example:
  ///
  /// ```dart
  /// @override
  /// getConfigurableOptions() =>  <MutableConfigOption<dynamic>> \[
  /// ...super.getConfigurableOptions(), ModelConfigOption(...), MutableConfigOptionGroup(StringConfigOption(...))
  /// \];
  /// ```
  ///
  /// To access those from the outside use the cached [configurableOptions] instead!
  List<MutableConfigOption<dynamic>> getConfigurableOptions() => <MutableConfigOption<dynamic>>[
    MutableConfigOptionGroup(
      titleKey: "page.settings.group.general",
      configOptions: <MutableConfigOption<dynamic>>[
        logLevel,
        useDarkTheme,
        currentLocale,
        appColors,
      ],
    ),
  ];

  /// Used to return the cached [getConfigurableOptions]
  List<MutableConfigOption<dynamic>> get configurableOptions {
    _configurableOptions ??= getConfigurableOptions();
    return UnmodifiableListView<MutableConfigOption<dynamic>>(_configurableOptions!);
  }

  /// Cache for [getConfigurableOptions]
  List<MutableConfigOption<dynamic>>? _configurableOptions;

  /// This will be called automatically at the end of [GameToolsLib.initGameToolsLib] to load all
  /// [getConfigurableOptions] by loading their values without updating listeners and calling [MutableConfigOption.onInit]
  /// on them! Important: from the outside, use the cached [configurableOptions] instead!
  Future<void> loadAllConfigurableOptions() async {
    for (final MutableConfigOption<dynamic> option in configurableOptions) {
      await option.getValue(updateListeners: false);
      await option.onInit();
      Logger.verbose("Loaded configurable option $option");
    }
  }

  /// Direct reference to the current instance of this
  static MutableConfig get mutableConfig => GameToolsConfig.baseConfig.mutable;

  /// Used for both [alwaysMatchGameWindowNamesEqual] and [debugPrintGameWindowNames] callbacks to update native code.
  /// Also waits [FixedConfig.tinyDelayMS] maximum afterwards!
  static Future<void> _updateGameWindowConfigValues(_) async {
    GameWindow.updateConfigVariables(
      alwaysMatchEqual: await mutableConfig.alwaysMatchGameWindowNamesEqual.valueNotNull(),
      printWindowNames: await mutableConfig.debugPrintGameWindowNames.valueNotNull(),
    );
    await Utils.delayMS(FixedConfig.fixedConfig.tinyDelayMS.y);
  }
}
