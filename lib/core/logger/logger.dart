part of 'package:game_tools_lib/game_tools_lib.dart';

/// Logger subclasses should override [logToConsole] with the preferred way to log into the console. But extend from
/// [CustomLogger] instead of this.
///
/// Before the static methods of the logger are used, the instance needs to be initialised with [initLoggerInstance]
/// which is done automatically!
///
/// Subclasses can also override [logToStorage] if the logs should be stored, or [addColorForConsole] to add different
/// color strings to the log messages in the console.
///
/// Use static methods [error], [warn], [present], [info], [verbose], [debug] and [spam]
abstract base class Logger {
  static const LogColor VERBOSE_COLOR = LogColor(128, 191, 255); // light blue
  static const LogColor DEBUG_COLOR = LogColor(166, 77, 255); // magenta
  static const LogColor INFO_COLOR = LogColor(128, 255, 128); // light green
  static const LogColor PRESENT_COLOR = LogColor(0, 255, 191); // cyan
  static const LogColor WARN_COLOR = LogColor(255, 255, 0); // yellow
  static const LogColor ERROR_COLOR = LogColor(255, 0, 0); // red
  static const LogColor _RESET_COLOR = LogColor(255, 255, 255); // white

  static const int consoleBufferSize = 1000;

  static Logger? _instance;

  static final Lock _lock = Lock();

  /// Nullable static getter used internally to return the config
  @protected
  static GameToolsConfigBaseType? get config => GameToolsConfig._instance;

  /// Converted from [SpamIdentifier] and contains the next time this is allowed to log
  static final Map<int, DateTime> _spamIdentifier = <int, DateTime>{};

  /// The current [LogLevel] of the logger. All logs with a higher value than this will be ignored and only the more
  /// important logs with a lower [LogLevel] will be printed and stored!
  /// Set it to [LogLevel.SPAM] to log everything (default if no config is set)!
  LogLevel get logLevel => config?.mutable.logLevel.cachedValue() ?? LogLevel.SPAM;

  /// Only set during tests to prevent logging to storage and ui
  bool _isTesting = false;

  Logger();

  /// Has to be called at the start of the main function to enable logging with a subclass of Logger.
  ///
  /// Don't call this manually, this will be called automatically from [GameToolsLib.initGameToolsLib]!
  static void initLoggerInstance(Logger instance) {
    if (_instance != null) {
      verbose("Overriding old logger instance $_instance with $instance");
    }
    _instance = instance;
  }

  /// The current custom logger instance which also may be null
  static Logger? get instance => _instance;

  /// Returns null, or [instance] as [T]
  static T? instanceOfSubType<T>() => _instance is T ? _instance as T : null;

  /// Very important critical errors that happened (and also presents in overlay in a bottom toast message)
  /// Does not await the [log] call with its synchronized write to storage if enabled
  static void error(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialised");
    _instance?.log(message, LogLevel.ERROR, error, stackTrace);
  }

  /// Maybe something wrong or unusual happened.
  /// Does not await the [log] call with its synchronized write to storage if enabled
  static void warn(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialised");
    _instance?.log(message, LogLevel.WARN, error, stackTrace);
  }

  /// Very important and not often used to present stuff to the user that they otherwise would not notice (and
  /// also presents in overlay in a bottom toast message).
  /// Does not await the [log] call with its synchronized write to storage if enabled
  static void present(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialised");
    _instance?.log(message, LogLevel.PRESENT, error, stackTrace);
  }

  /// Rarely used for important information for the user.
  /// Does not await the [log] call with its synchronized write to storage if enabled
  static void info(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialised");
    _instance?.log(message, LogLevel.INFO, error, stackTrace);
  }

  /// Useful information at a slower pace and more important for debugging
  /// Does not await the [log] call with its synchronized write to storage if enabled
  static void debug(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialised");
    _instance?.log(message, LogLevel.DEBUG, error, stackTrace);
  }

  /// Medium pace information and not that needed like extended debug information
  /// Does not await the [log] call with its synchronized write to storage if enabled
  static void verbose(String? message, [Object? error, StackTrace? stackTrace]) {
    assert(_instance != null, "logger not initialised");
    _instance?.log(message, LogLevel.VERBOSE, error, stackTrace);
  }

  /// Very high frequency useless information (mostly not shown in ui, or not saved in storage).
  /// Special log function: takes dynamic parts that will be put together to a string internally only if spam is
  /// enabled for performance reasons. Also does not await the [log] call with its synchronized write to storage.
  /// If you only want to log once every few milliseconds, then use [spamPeriodic]!
  static void spam(Object? p1, [Object? p2, Object? p3, Object? p4, Object? p5, Object? p6, Object? p7]) {
    assert(_instance != null, "logger not initialised");
    if (_instance?.canLog(LogLevel.SPAM) ?? false) {
      _writeSpam(p1, p2, p3, p4, p5, p6, p7, DateTime.now());
    }
  }

  /// Like [spam], but only logs once every few milliseconds for heavy spam.
  /// This requires a [identifier] that is used to track the delay for different locations calling it.
  /// So you should create a static final object of [SpamIdentifier] that you use for this (never recreate it at
  /// every call!!!)
  static void spamPeriodic(
    SpamIdentifier identifier,
    Object? p1, [
    Object? p2,
    Object? p3,
    Object? p4,
    Object? p5,
    Object? p6,
    Object? p7,
  ]) {
    // no assert here, because it can be called from finalizer and logger might not be initialized yet?!
    if (_instance?.canLog(LogLevel.SPAM) ?? false) {
      final DateTime now = DateTime.now();
      final DateTime? nextTime = _spamIdentifier[identifier.identifier];
      if (nextTime?.isBefore(now) ?? true) {
        _writeSpam(p1, p2, p3, p4, p5, p6, p7, now);
        if (identifier.delay.inMilliseconds > 0) {
          _spamIdentifier[identifier.identifier] = now.add(identifier.delay);
        }
      }
    }
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

  /// Per default awaits [debugPrintDone] and the internal [_lock] (should be called at the end of the program when
  /// shutting down!
  ///
  static Future<void> waitForLoggingToBeDone() async {
    await debugPrintDone;
    await _lock.synchronized(() {});
  }

  /// The main log method that is called by the static log methods. will log to console, storage, etc...
  Future<void> log(String? message, LogLevel level, Object? error, StackTrace? stackTrace) async {
    if (canLog(level) == false) {
      return;
    }
    return _log(
      LogMessage(
        message: message,
        level: level,
        error: error?.toString(),
        stackTrace: stackTrace?.toString(),
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _log(LogMessage logMessage) async {
    _wrapLog(convertLogMessageToConsole(logMessage), logMessage.level).forEach(logToConsole);
    addConsoleDelimiter(logMessage);
    if (_isTesting == false) {
      logToUi(logMessage);
      await _lock.synchronized(() => logToStorage(logMessage)); // the static log methods will not await this,
      // so it has to be synchronized!
    }
  }

  /// Adds a delimiter between the logs. can also be overridden in sub classes.
  void addConsoleDelimiter(LogMessage message) {
    logToConsole(message.buildDelimiter(chars: 80, withNewLines: false));
  }

  List<String> convertLogMessageToConsole(LogMessage logMessage) {
    final List<String> output = <String>[];
    final List<String> input = StringUtils.splitIntoLines(logMessage.toString());
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

  // ignore: unused_element
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
      case LogLevel.PRESENT:
        color = PRESENT_COLOR;
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

  @override
  String toString() {
    return '$runtimeType(logLevel: $logLevel)';
  }

  static void _writeSpam(
    Object? p1,
    Object? p2,
    Object? p3,
    Object? p4,
    Object? p5,
    Object? p6,
    Object? p7,
    DateTime now,
  ) {
    final StringBuffer buf = StringBuffer();
    if (p1 != null) buf.write(p1);
    if (p2 != null) buf.write(p2);
    if (p3 != null) buf.write(p3);
    if (p4 != null) buf.write(p4);
    if (p5 != null) buf.write(p5);
    if (p6 != null) buf.write(p6);
    if (p7 != null) buf.write(p7);
    _instance!._log(LogMessage(level: LogLevel.SPAM, timestamp: now, message: buf.toString()));
  }
}

/// Used to call [Logger.spamPeriodic], but must be created as a static final object and not in every call!!!!!!
/// If [delay] is null, then [FixedConfig.logPeriodicSpamDelayMS] will be used!
final class SpamIdentifier {
  /// Incremented automatically
  final int identifier;

  /// The delay after each call
  final Duration delay;

  static int _identifierCounter = 0;

  /// If [delay] is null, then [FixedConfig.logPeriodicSpamDelayMS] will be used!
  SpamIdentifier([Duration? delay])
    : identifier = _identifierCounter++,
      delay = delay ?? Duration(milliseconds: FixedConfig.fixedConfig.logPeriodicSpamDelayMS);

  @override
  int get hashCode => identifier.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SpamIdentifier && identifier == other.identifier;

  @override
  String toString() => "SpamIdentifier($identifier: $delay)";
}
