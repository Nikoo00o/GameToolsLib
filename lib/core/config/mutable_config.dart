import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/enums/log_level.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/locale_extension.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/domain/entities/base/model.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_config.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

part 'package:game_tools_lib/core/config/mutable_config_option.dart';

part 'package:game_tools_lib/core/config/mutable_config_option_types.dart';

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
/// Look at [getConfigurableOptions] which you can optionally override depending on which config options you want
/// to be able to be modified in the UI. Those will also be loaded once automatically on startup in
/// [loadAllConfigurableOptions].
base class MutableConfig {
  /// The current [logLevel] of the logger. All logs with a higher value than this will be ignored and only
  /// the more important logs with a lower [LogLevel] will be printed and stored!
  /// Default is [LogLevel.SPAM] to log everything!
  final LogLevelConfigOption logLevel = LogLevelConfigOption(key: "config.logLevel", defaultValue: LogLevel.SPAM);

  /// Controls if the ui is displayed as dark, or light theme
  final BoolConfigOption useDarkTheme = BoolConfigOption(key: "config.useDarkTheme", defaultValue: true);

  /// The current language which is null per default and will return the system language if its null.
  /// But if the current system language is not supported, then internally this will fallback to the first entry of
  /// [FixedConfig.supportedLocales]!
  /// Important: use [LocaleConfigOption.activeLocale] to access the locale that is used in the app!
  final LocaleConfigOption currentLocale = LocaleConfigOption(key: "config.currentLocale");

  /// Controls how the window names will be matched ([false] = window title only has to contain the [GameWindow.name].
  /// Otherwise if [true] it has to be exactly the same). Used for [GameWindow], default is [false].
  final BoolConfigOption alwaysMatchGameWindowNamesEqual = BoolConfigOption(
    key: "config.alwaysMatchGameWindowNamesEqual",
    defaultValue: false,
    updateCallback: _updateGameWindowConfigValues,
  );

  /// This is a debug variable to print out all opened windows if set to true. Used for [GameWindow], default is
  /// [false].
  final BoolConfigOption debugPrintGameWindowNames = BoolConfigOption(
    key: "config.debugPrintGameWindowNames",
    defaultValue: false,
    updateCallback: _updateGameWindowConfigValues,
  );

  /// You can override this to return references to those config options you want to be able to modify in the UI!
  ///
  /// Remember to also add the config options from here if you want to by calling the super method and then add your
  /// own config options like for example:
  ///
  /// ```dart
  /// @override
  /// getConfigurableOptions() =>  <MutableConfigOption<dynamic>> \[
  /// ...super.getConfigurableOptions(), BoolConfigOption(key: ""), StringConfigOption(key: "")
  /// \];
  /// ```
  List<MutableConfigOption<dynamic>> getConfigurableOptions() => <MutableConfigOption<dynamic>>[
    logLevel,
    useDarkTheme,
    debugPrintGameWindowNames,
    alwaysMatchGameWindowNamesEqual,
  ];

  /// This will be called automatically at the end of [GameToolsLib.initGameToolsLib] to load all
  /// [getConfigurableOptions] and also update the listeners/callbacks!
  Future<void> loadAllConfigurableOptions() async {
    for (final MutableConfigOption<dynamic> option in getConfigurableOptions()) {
      await option.getValue(updateListeners: true);
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
