part of 'package:game_tools_lib/game_tools_lib.dart';

/// Logger subclasses should override [logToConsole] with the preferred way to log into the console.
///
/// Before the static methods of the logger are used, the instance needs to be initialised with [initLogger]!
///
/// Subclasses can also override [logToStorage] if the logs should be stored, or [addColorForConsole] to add different
/// color strings to the log messages in the console.
abstract base class Logger {
  static const LogColor VERBOSE_COLOR = LogColor(128, 191, 255); // light blue
  static const LogColor DEBUG_COLOR = LogColor(166, 77, 255); // magenta
  static const LogColor INFO_COLOR = LogColor(128, 255, 128); // light green
  static const LogColor WARN_COLOR = LogColor(255, 255, 0); // yellow
  static const LogColor ERROR_COLOR = LogColor(255, 0, 0); // red
  static const LogColor _RESET_COLOR = LogColor(255, 255, 255); // white

  static const int consoleBufferSize = 1000;

  static Logger? _instance;

  static final Lock _lock = Lock();

  /// The current [LogLevel] of the logger. All logs with a higher value than this will be ignored and only the more
  /// important logs with a lower [LogLevel] will be printed and stored!
  /// Set it to [LogLevel.VERBOSE] to log everything!
  LogLevel get logLevel => GameToolsLib.config().mutable.logLevel.cachedValue() ?? LogLevel.VERBOSE;

  /// Only set during tests to prevent logging to storage and ui
  bool _isTesting = false;

  Logger();

  /// Has to be called at the start of the main function to enable logging with a subclass of Logger
  static void _initLogger(Logger instance) {
    if (_instance != null) {
      verbose("Overriding old logger instance $_instance with $instance");
    }
    _instance = instance;
  }

  /// does not await the [log] call with its synchronized write to storage if enabled
  static void error(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialised");
    _instance?.log(message, LogLevel.ERROR, error, stackTrace);
  }

  /// does not await the [log] call with its synchronized write to storage if enabled
  static void warn(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialised");
    _instance?.log(message, LogLevel.WARN, error, stackTrace);
  }

  /// does not await the [log] call with its synchronized write to storage if enabled
  static void info(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialised");
    _instance?.log(message, LogLevel.INFO, error, stackTrace);
  }

  /// does not await the [log] call with its synchronized write to storage if enabled
  static void debug(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialised");
    _instance?.log(message, LogLevel.DEBUG, error, stackTrace);
  }

  /// does not await the [log] call with its synchronized write to storage if enabled
  static void verbose(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialised");
    _instance?.log(message, LogLevel.VERBOSE, error, stackTrace);
  }

  static void spam(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialised");
    _instance?.log(message, LogLevel.SPAM, error, stackTrace);
  }

  /// Returns if the current [logLevel] is set high enough, so that the [targetLevel] would be logged into the console and
  /// storage!
  ///
  /// This can be used for performance improvement to prevent execution of some logging code!
  bool canLog(LogLevel targetLevel) => targetLevel.index <= logLevel.index;

  /// returns the current log level of the logger
  static LogLevel get currentLogLevel {
    assert(_instance != null, "logger not initialised");
    return _instance!.logLevel;
  }

  /// The main log method that is called by the static log methods. will log to console, storage, etc...
  Future<void> log(String? message, LogLevel level, Object? error, StackTrace? stackTrace) async {
    if (canLog(level) == false) {
      return;
    }
    final LogMessage logMessage = LogMessage(
      message: message,
      level: level,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
      timestamp: DateTime.now(),
    );
    _wrapLog(convertLogMessageToConsole(logMessage), level).forEach(logToConsole);
    addConsoleDelimiter();
    if (_isTesting == false) {
      logToUi(logMessage);
      await _lock.synchronized(() => logToStorage(logMessage)); // the static log methods will not await this,
      // so it has to be synchronized!
    }
  }

  /// Adds a delimiter between the logs. can also be overridden in sub classes.
  void addConsoleDelimiter() {
    logToConsole(String.fromCharCodes(List<int>.generate(80, (int index) => "-".codeUnits.first)));
  }

  List<String> convertLogMessageToConsole(LogMessage logMessage) {
    final List<String> output = <String>[];
    final List<String> input = logMessage.toString().split("\n");
    for (final String line in input) {
      final StringBuffer buff = StringBuffer();
      buff.write(addColorForConsole(logMessage.level).toString());
      buff.write(line);
      buff.write(_RESET_COLOR.toString());
      output.add(buff.toString());
    }
    return output;
  }

  /// Wraps the log for the console
  List<String> _wrapLog(List<String> logLines, LogLevel logLevel) {
    final List<String> output = <String>[];
    for (final String line in logLines) {
      output.addAll(RegExp(".{1,$consoleBufferSize}").allMatches(line).map((Match match) => match.group(0)!).toList());
    }
    //_padMultipleLines(output, logLevel); // optional padding log lines
    return output;
  }

  void _padMultipleLines(List<String> output, LogLevel logLevel) {
    for (int i = 1; i < output.length; ++i) {
      final StringBuffer out = StringBuffer();
      final int count = "00:00:00.000 ".length + logLevel.toString().length + ": ".length;
      for (int c = 0; c < count; ++c) {
        out.write(" ");
      }
      out.write(output[i]);
      output[i] = out.toString();
    }
  }

  /// This can also be overridden in a subclass to provide different [LogColor]'s for the [LogLevel]
  LogColor addColorForConsole(LogLevel level) {
    LogColor? color;
    switch (level) {
      case LogLevel.ERROR:
        color = ERROR_COLOR;
        break;
      case LogLevel.WARN:
        color = WARN_COLOR;
        break;
      case LogLevel.INFO:
        color = INFO_COLOR;
        break;
      case LogLevel.DEBUG:
        color = DEBUG_COLOR;
        break;
      case LogLevel.VERBOSE:
        color = VERBOSE_COLOR;
        break;
      case LogLevel.SPAM:
        color = _RESET_COLOR;
        break;
    }
    return color;
  }

  /// returns the matching log color of the log message. returns null if there is no logger instance
  static LogColor? getLogColorForMessage(LogMessage logMessage) {
    return _instance?.addColorForConsole(logMessage.level);
  }

  @override
  String toString() {
    return '$runtimeType{logLevel: $logLevel}';
  }

  /// Can be overridden in the subclass to log the final log message string into the console in different ways.
  ///
  /// The default is just a call to [debugPrint]
  void logToConsole(String logMessage);

  /// Can be overridden in the subclass for different logging widgets
  void logToUi(LogMessage logMessage);

  /// Can be overridden in the subclass to store the final log message in a file.
  ///
  /// Important: the call to this method will not be awaited, but it will be synchronized, so that only ever one log call
  /// is writing to it at the same time!
  ///
  /// The default is just a call to do nothing
  Future<void> logToStorage(LogMessage logMessage);
}
