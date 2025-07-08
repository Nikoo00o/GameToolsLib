import 'package:flutter/foundation.dart';
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/logger/log_level.dart';
import 'package:game_tools_lib/core/logger/log_message.dart';
import 'package:game_tools_lib/core/utils/file_utils.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:intl/intl.dart' show DateFormat;

/// Your own logger classes can extend this
base class CustomLogger extends Logger {
  CustomLogger();

  static FixedConfig get fixedConfig => GameToolsLib.config().fixed;

  /// Can be overridden in the subclass to log the final log message string into the console in different ways.
  ///
  /// The default is just a call to [debugPrint]
  @override
  void logToConsole(String logMessage) {
    if (fixedConfig.logIntoConsole) {
      debugPrint(logMessage);
    }
  }

  /// Can be overridden in the subclass for different logging widgets
  @override
  void logToUi(LogMessage logMessage) {
    if (fixedConfig.logIntoUI) {
      // todo: implement
    }
  }

  /// Can be overridden in the subclass to store the final log message in a file.
  ///
  /// Important: the call to this method will not be awaited, but it will be synchronized, so that only ever one log call
  /// is writing to it at the same time!
  ///
  /// The default is just a call to do nothing
  @override
  Future<void> logToStorage(LogMessage logMessage) async {
    if (fixedConfig.logIntoStorage) {
      try {
        final String date = DateFormat("yyyy-MM-dd").format(DateTime.now());
        final String path = FileUtils.combinePath(<String>[fixedConfig.logFolder, "$date.txt"]);
        await FileUtils.addToFileAsync(path, logMessage.toString());
        final String delimiter = String.fromCharCodes(List<int>.generate(100, (int index) => "-".codeUnits.first));
        await FileUtils.addToFileAsync(path, "\n$delimiter\n");
      } catch (_) {
        //ignored
      }
    }
  }
}

/// Used on Startup
final class StartupLogger extends Logger {
  StartupLogger();

  @override
  void logToConsole(String logMessage) {
    debugPrint(logMessage);
  }

  @override
  void logToUi(LogMessage logMessage) {}

  @override
  Future<void> logToStorage(LogMessage logMessage) async {}

  @override
  LogLevel get logLevel => LogLevel.VERBOSE;
}
