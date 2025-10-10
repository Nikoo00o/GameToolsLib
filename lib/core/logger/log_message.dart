import 'package:game_tools_lib/core/enums/log_level.dart';
import 'package:game_tools_lib/core/logger/custom_logger.dart';
import 'package:game_tools_lib/core/logger/log_color.dart';
import 'package:game_tools_lib/core/utils/string_utils.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

/// Used for each message of [Logger].
/// The [toString] will just call [getSensitiveString] with an empty list!
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

  /// Used in [getSensitiveString] to convert the sensitive data part.
  /// It removes all occurrences of exactly each element of [sensitiveDataToRemove] until the next special character
  /// like " " space or "\n" line break by adding "*" for each character after the element of [sensitiveDataToRemove].
  ///
  /// Important: if your sensitive data is separated with a space " " from your string of [sensitiveDataToRemove] then
  /// you have to include that space of course inside of your string of [sensitiveDataToRemove].
  ///
  /// For example "Password: MY_PASSWORD " in a log message with the sensitive data string "Password: " would result in
  /// "Password: *********** " in the log file.
  static void writeSensitiveMessage(StringBuffer output, String message, List<String> sensitiveDataToRemove) {
    bool blackout = false;
    for (int i = 0; i < message.length; ++i) {
      for (final String key in sensitiveDataToRemove) {
        if (StringUtils.containsAtOffset(i, message, key)) {
          if (blackout) {
            for (int s = 0; s < key.length; ++s) {
              output.write("*");
            }
          } else {
            output.write(key);
          }
          blackout = true;
          i += key.length;
          break;
        }
      }
      if (blackout) {
        final String char = message[i];
        if (char == "\n" || char == " ") {
          blackout = false;
          output.write(message[i]);
        } else {
          output.write("*");
        }
      } else {
        output.write(message[i]);
      }
    }
  }

  /// For logging to storage, this receives the [CustomLogger.sensitiveDataToRemove] list to not log sensitive data
  /// and uses [writeSensitiveMessage].
  String getSensitiveString({required List<String> sensitiveDataToRemove}) {
    final StringBuffer buffer = StringBuffer();
    buffer.write("$_formattedTime $level: ");
    if (message != null) {
      if (sensitiveDataToRemove.isNotEmpty && message!.isNotEmpty) {
        writeSensitiveMessage(buffer, message!, sensitiveDataToRemove);
      } else {
        buffer.write(message);
      }
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

  @override
  String toString() => getSensitiveString(sensitiveDataToRemove: <String>[]);

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
