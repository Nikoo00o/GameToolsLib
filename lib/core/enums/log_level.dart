import 'package:game_tools_lib/core/logger/log_color.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

/// The type of the log entry (a lower level is more important)
enum LogLevel {
  /// 0
  ERROR,

  /// 1
  WARN,

  /// 2
  INFO,

  /// 3
  DEBUG,

  /// 4
  VERBOSE,

  /// 5
  SPAM;

  @override
  String toString() {
    return name;
  }

  factory LogLevel.fromString(String data) {
    return values.firstWhere((LogLevel element) => element.name == data);
  }

  /// This can return null if the logger instance is null and otherwise it uses [Logger.addColorForConsole]
  static LogColor? getLogColor(LogLevel level)  => Logger.instance?.addColorForConsole(level);
}
