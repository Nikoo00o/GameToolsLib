import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/enums/log_level.dart';
import 'package:game_tools_lib/core/logger/log_message.dart';
import 'package:game_tools_lib/core/utils/file_utils.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/widgets/helper/changes/simple_change_stream.dart';
import 'package:intl/intl.dart' show DateFormat;

/// Your own logger classes can extend this.
///
/// This will also provide the option to listen to new logs from the ui with [SimpleChangeStream].
base class CustomLogger extends Logger with SimpleChangeStream<List<LogMessage>> {
  /// Will always remove 10% of the latest logs
  static int maxLogsToKeepForUI = 1000;

  CustomLogger() {
    initSimpleChangeStream(<LogMessage>[]); // important: init
  }

  /// Can be overridden in the subclass to log the final log message string into the console in different ways.
  ///
  /// The default is just a call to [debugPrint]
  @override
  void logToConsole(String logMessage) {
    if (fixedConfig?.logIntoConsole ?? false) {
      debugPrint(logMessage);
    }
  }

  /// Can be overridden in the subclass for different logging widgets
  @override
  void logToUi(LogMessage logMessage) {
    if (fixedConfig?.logIntoUI ?? false) {
      sendToUi(logMessage);
    }
  }

  void sendToUi(LogMessage logMessage) {
    changeValue.add(logMessage);
    if (changeValue.length >= maxLogsToKeepForUI) {
      changeValue.removeRange(0, maxLogsToKeepForUI ~/ 10 + 1);
    }
    addEvent(); // uses SimpleChangeStream
  }

  /// Can be overridden in the subclass to store the final log message in a file.
  ///
  /// Important: the call to this method will not be awaited, but it will be synchronized, so that only ever one log call
  /// is writing to it at the same time!
  ///
  /// The default is just a call to do nothing
  @override
  Future<void> logToStorage(LogMessage logMessage) async {
    if (fixedConfig?.logIntoStorage ?? false) {
      try {
        final String date = DateFormat("yyyy-MM-dd").format(DateTime.now());
        final String path = FileUtils.combinePath(<String>[Logger.config!.logFolder, "$date.txt"]);
        await FileUtils.addToFile(path, logMessage.toString());
        final String delimiter = String.fromCharCodes(List<int>.generate(100, (int index) => "-".codeUnits.first));
        await FileUtils.addToFile(path, "\n$delimiter\n");
      } catch (e, s) {
        final StartupLogger fallback = StartupLogger();
        await fallback.log("Error logging to storage:", LogLevel.ERROR, e, s);
      }
    }
  }

  @protected
  /// Nullable static getter used internally to return the fixed config instance
  static FixedConfig? get fixedConfig => Logger.config?.fixed;
}

/// Used on Startup, because it will never log to storage, but always to console and ui!
final class StartupLogger extends CustomLogger {
  StartupLogger();

  @override
  void logToConsole(String logMessage) {
    debugPrint(logMessage);
  }

  @override
  void logToUi(LogMessage logMessage) {
    sendToUi(logMessage);
  }

  @override
  Future<void> logToStorage(LogMessage logMessage) async {}

  @override
  LogLevel get logLevel => LogLevel.SPAM;
}
