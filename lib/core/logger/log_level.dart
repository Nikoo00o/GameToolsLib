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
}
