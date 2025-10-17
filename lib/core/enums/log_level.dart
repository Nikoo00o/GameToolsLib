import 'package:game_tools_lib/core/logger/log_color.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

/// The type of the log entry (a lower level is more important)
enum LogLevel {
  /// 0: very important critical errors that happened (and also presents in overlay in a bottom toast message)
  ERROR,

  /// 1: maybe something wrong or unusual happened
  WARN,

  /// 2: very important and not often used to present stuff to the user that they otherwise would not notice (and
  /// also presents in overlay in a bottom toast message)
  PRESENT,

  /// 3: rarely used for important information for the user
  INFO,

  /// 4: useful information at a slower pace and more important for debugging
  DEBUG,

  /// 5: medium pace information and not that needed like extended debug information
  VERBOSE,

  /// 6: very high frequency useless information (mostly not shown in ui, or not saved in storage)
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
