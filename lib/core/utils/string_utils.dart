import 'dart:convert';

import 'package:game_tools_lib/core/utils/list_utils.dart';

/// Helper functions for strings like [getRandomBytesAsString] or [toStringPretty]
abstract final class StringUtils {
  /// Returns a String of [length] with character values from 0 to 255
  static String getRandomBytesAsString(int length) => String.fromCharCodes(ListUtils.getRandomBytes(length));

  /// Returns a String with [length] bytes which are base64 url encoded.
  /// So the length of the string will be bigger!
  static String getRandomBytesAsBase64String(int length) => base64UrlEncode(ListUtils.getRandomBytes(length));

  /// Tries to split the [input] into a list of strings containing the lines. If input is only one line, or empty,
  /// then the list will only have input itself as elements!
  /// Also if a line break is at the start, or at the end, it will count as an extra empty line!
  static List<String> splitIntoLines(String input) {
    final bool defaultLineBreak = input.contains("\n");
    final bool extraLineBreak = input.contains("\r\n");
    if (defaultLineBreak) {
      String toSplit = input;
      if (extraLineBreak) {
        toSplit = toSplit.replaceAll("\r\n", "\n");
      }
      return toSplit.split("\n").toList();
    } else if (extraLineBreak) {
      return input.split("\r\n").toList();
    }
    return <String>[input];
  }

  /// Returns a pretty string for an [object] with the [propertiesOfObject] which maps String description keys to
  /// the member variables of the object!
  static String toStringPretty(Object object, Map<String, Object?> propertiesOfObject) {
    final StringBuffer buffer = StringBuffer();
    if (object is String) {
      buffer.writeln("\n$object {");
    } else {
      buffer.writeln("\n${object.runtimeType} {");
    }
    propertiesOfObject.forEach((String key, Object? value) {
      buffer.write("  $key : ");
      final String valueString = value?.toString() ?? "null";
      if (valueString.startsWith("\n")) {
        _printInnerObject(buffer, valueString);
      } else if (value is List<dynamic>) {
        _printInnerList(buffer, valueString);
      } else {
        buffer.writeln("$valueString,");
      }
    });
    buffer.write("}");
    return buffer.toString();
  }

  /// Returns if [source] contains [needle] at [offset] (length added to index of source)
  static bool containsAtOffset(int offset, String source, String needle) {
    if (offset >= source.length || needle.isEmpty) {
      return false;
    }
    for (int i = 0; i < needle.length; ++i) {
      if (source[i + offset] != needle[i]) {
        return false;
      }
    }
    return true;
  }

  static void _printInnerObject(StringBuffer buffer, String value) {
    final String valueString = value.substring(1); // remove the line break
    final List<String> innerLogs = splitIntoLines(valueString);
    buffer.writeln(innerLogs.first); // first line should not have spaces added
    for (int i = 1; i < innerLogs.length - 1; ++i) {
      buffer.writeln("  ${innerLogs.elementAt(i)}");
    }
    buffer.writeln("  ${innerLogs.last},");
  }

  static void _printInnerList(StringBuffer buffer, String value) {
    final List<String> lines = splitIntoLines(value);
    buffer.writeln(lines.first);
    if (lines.length == 1) {
      return; // empty lists
    }
    for (int i = 1; i < lines.length - 1; ++i) {
      buffer.writeln("    ${lines.elementAt(i)}");
    }
    if (lines.last.length == 2) {
      buffer.writeln("    ${lines.last.substring(0, 1)}");
      buffer.writeln("  ${lines.last.substring(1)},");
    } else {
      buffer.writeln("  ${lines.last}");
    }
  }
}
