import 'package:game_tools_lib/core/enums/log_level.dart';
import 'package:game_tools_lib/core/logger/log_color.dart';
import 'package:game_tools_lib/core/utils/string_utils.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

final class LogMessage {
  final String? message;
  final LogLevel level;
  final DateTime timestamp;
  final String? error;
  final String? stackTrace;

  /// Only print these first stack trace lines and not spam the log with the full stack trace.
  /// They are taken from beginning and end!
  static const int stackTraceLines = 16;

  const LogMessage({
    this.message,
    required this.level,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });

  String get _formattedTime {
    final String hour = timestamp.hour.toString().padLeft(2, "0");
    final String minutes = timestamp.minute.toString().padLeft(2, "0");
    final String second = timestamp.second.toString().padLeft(2, "0");
    final String millisecond = timestamp.millisecond.toString().padLeft(3, "0");
    return "$hour:$minutes:$second.$millisecond";
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer();
    buffer.write("$_formattedTime $level: ");
    if (message != null) {
      buffer.write(message);
    }
    if (error != null) {
      buffer.write("\nException: $error");
    }
    if (stackTrace != null) {
      final String stackTraceText = stackTrace!.toString();
      final List<String> lines = StringUtils.splitIntoLines(stackTraceText);
      if (lines.length > stackTraceLines) {
        _write(lines.take(stackTraceLines ~/ 2), buffer);
        _write(lines.sublist(lines.length - stackTraceLines ~/ 2), buffer);
      } else {
        _write(lines, buffer);
      }
    }
    return buffer.toString();
  }

  /// If [withNewLines] is true, then at the start and end a new line character is added after the [chars] amount of
  /// "-" characters
  String buildDelimiter({required int chars, required bool withNewLines}) {
    final String delimiter = String.fromCharCodes(List<int>.generate(chars, (int index) => "-".codeUnits.first));
    return withNewLines ? "\n$delimiter\n" : delimiter;
  }

  void _write(Iterable<String> lines, StringBuffer buffer) {
    for (final String line in lines) {
      buffer.write("\n$line");
    }
  }

  /// If this log [level] could be logged for the [targetLevel]!
  bool canLog(LogLevel targetLevel) => level.index <= targetLevel.index;

  /// This can return null if the logger instance is null and otherwise it uses [Logger.addColorForConsole]
  LogColor? getLogColor() => LogLevel.getLogColor(level);
}
