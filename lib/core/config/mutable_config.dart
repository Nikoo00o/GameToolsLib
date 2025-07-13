import 'dart:async';
import 'dart:convert';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/logger/log_level.dart';
import 'package:game_tools_lib/data/game/game_window.dart';
import 'package:game_tools_lib/domain/entities/model.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

part 'package:game_tools_lib/core/config/mutable_config_option.dart';

/// Base class storing all mutable config values which are dynamically stored in a local storage file
///
/// For more info (and an example) look at the general documentation of [GameToolsConfig]
///
/// Here the config values are stored as getters of a subtype of [_MutableConfigOption]: [BoolConfigOption],
/// [IntConfigOption], [DoubleConfigOption], [StringConfigOption], [LogLevelConfigOption]
/// And for more complex data [ModelConfigOption] with your model type!
/// But if you want to use custom options with complete freedom, then use [CustomConfigOption] (rarely needed)!
///
/// Access the values async with [_MutableConfigOption.getValue] at least once (afterwards you could also access the
/// cached value in a sync way with [_MutableConfigOption.cachedValue]!
///
/// Look at [configurableOptions] which you can optionally override depending on which config options you want
/// to be able to be modified in the UI.
base class MutableConfig {
  /// The current [logLevel] of the logger. All logs with a higher value than this will be ignored and only
  /// the more important logs with a lower [LogLevel] will be printed and stored!
  /// Default is [LogLevel.SPAM] to log everything!
  LogLevelConfigOption get logLevel => LogLevelConfigOption(key: "Log Level", defaultValue: LogLevel.SPAM);

  /// Like [logLevel], but this here should instead constraint which logs are able to be logged into the UI 
  LogLevelConfigOption get uiLogLevel => LogLevelConfigOption(key: "UI Log Level", defaultValue: LogLevel.DEBUG);

  /// Controls how the window names will be matched ([false] = window title only has to contain the [GameWindow.name].
  /// Otherwise if [true] it has to be exactly the same). Used for [GameWindow], default is [false].
  BoolConfigOption get alwaysMatchGameWindowNamesEqual => BoolConfigOption(
    key: "Always Match GameWindow Names Equal",
    defaultValue: false,
    updateCallback: _updateGameWindowConfigValues,
  );

  /// This is a debug variable to print out all opened windows if set to true. Used for [GameWindow], default is
  /// [false].
  BoolConfigOption get debugPrintGameWindowNames => BoolConfigOption(
    key: "Debug Print GameWindow Names",
    defaultValue: false,
    updateCallback: _updateGameWindowConfigValues,
  );

  /// Used for both [alwaysMatchGameWindowNamesEqual] and [debugPrintGameWindowNames] callbacks to update native code.
  static Future<void> _updateGameWindowConfigValues(_) async {
    GameWindow.updateConfigVariables(
      alwaysMatchEqual: await mutableConfig.alwaysMatchGameWindowNamesEqual.valueNotNull(),
      printWindowNames: await mutableConfig.debugPrintGameWindowNames.valueNotNull(),
    );
  }

  /// You can override this to return references to those config options you want to be able to modify in the UI!
  ///
  /// When overriding this, you have avoid using types, because you cant access [_MutableConfigOption]. So you have
  /// to use the following (remember to use super if you want to include the config options from this):
  /// ```dart
  /// get configOptions =>  \[...super.configOptions, BoolConfigOption(key: ""), StringConfigOption(key: "")\];
  /// ```
  // todo: implement ui for it
  List<_MutableConfigOption<dynamic>> get configurableOptions => <_MutableConfigOption<dynamic>>[
    logLevel,
    alwaysMatchGameWindowNamesEqual,
    debugPrintGameWindowNames,
    alwaysMatchGameWindowNamesEqual,
  ];

  /// Reference to the current instance of this
  static MutableConfig get mutableConfig => GameToolsConfig.baseConfig.mutable;
}
