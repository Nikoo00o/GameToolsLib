part of 'package:game_tools_lib/game_tools_lib.dart';

/// This is the base class that contains all [LogInputListener] (or subclasses) listeners on what event to add when a
/// specific log line shows up in the game log (for more, look at the docs of the [LogInputListener] as well).
///
/// Your subclass of this will be initialized in [GameToolsLib.initGameToolsLib] into [GameLogWatcher] and can either
/// directly provide the [_listeners] and [_gameLogFilePaths], or you can also just use the default class and pass
/// them to the default constructor.
///
/// In your sub class you can override [shouldLineBeSkipped] to filter out not needed lines. And [handleLastLine]
/// together with [delayForOldLines] if you want to modify the behaviour how to process old lines if the game was
/// already running for a while and this tool just started! And you may also override [additionalListeners] as an
/// alternative if you want (for an example you can also look at the [ExampleLogWatcher] that is used for testing.
/// Important: if your log file has a specific open/start signal for each session, then you can use
/// [onlyHandleLastLinesUntil] to only handle last lines until the line matches it and then stop (to avoid false
/// events), but per default it is null and [handleLastLine] is executed until it returns true.
///
/// You also don't have to decide on listeners in the constructor call and can use [addListener], or [removeListener]
/// later. If your game does not have a log file, then just use the [GameLogWatcher.empty] constructor. And you can
/// optionally also use [Module.getAdditionalInputListener] instead to provide additional log input listeners.
///
/// This is updated automatically at the end of the event loop of [GameToolsLib]!
///
/// Important: you might want to use multi language [JsonAsset]'s to store any strings that you search for because
/// the game log messages might be translated depending on the [GameToolsLib.gameLanguage]!
base class GameLogWatcher {
  final List<String>? _gameLogFilePaths;
  final List<LogInputListener> _listeners;
  File? _file;
  DateTime? _lastModified;
  int _currentPos = 0;

  /// used in [_didFileChange]
  int _lastSize = 0;

  /// used in [_didFileChange]
  int _skipTicks = 0;

  /// used in [_didFileChange]
  static const int _skipTicksOnDuplicate = 5;

  /// used in [_didFileChange]
  bool _lastChanged = false;

  /// Quick getter to get resulting path used for debugging
  String get readingFromPath => _file?.absolute.path ?? "";

  /// The [handleLastLine] with old lines on startup will only check lines until a line matches this listener if its
  /// not null. Per default its null and ignored, but it can be used to add a stop if your log file has a specific
  /// session start line it always prints! So [handleLastLine] will not be called if an earlier line succeeds the
  /// [LogInputListener.matchesLine] with this [onlyHandleLastLinesUntil] listener.
  final LogInputListener? onlyHandleLastLinesUntil;

  /// Can be overridden in your subclass to define the maximum amount of time it may take for the last log of the game
  /// to still call [handleLastLine] during [_init].
  ///
  /// Per default the game has to have added a log in the last minute for this to still call [handleLastLine] and if
  /// it took any longer, it won't and instead treat the game as just starting up after the tool.
  ///
  /// Important: the file modified time stamp only cares about seconds and will not have millisecond precision!
  Duration get delayForOldLines => const Duration(minutes: 1);

  /// If the game has no log file, then use [GameLogWatcher.empty] instead.
  /// [gameLogFilePaths] is a list of possible paths to the game log file (will use the most recent modified found file)
  /// and [listeners] can be your list of [LogInputListener] that you want to use, but can also be [null] and then
  /// added later with [addListener].
  GameLogWatcher({
    required List<String>? gameLogFilePaths,
    required List<LogInputListener>? listeners,
    this.onlyHandleLastLinesUntil,
  }) : _listeners = listeners ?? <LogInputListener>[],
       _gameLogFilePaths = gameLogFilePaths;

  /// Can be used if the game has no log file, otherwise use the default constructor
  GameLogWatcher.empty() : this(gameLogFilePaths: null, listeners: <LogInputListener>[]);

  /// This can be overridden in subclasses as an alternative to the listeners in the constructor or [addListener]
  /// calls. You can just return a list of listeners that will be added internally during [GameToolsLib.initGameToolsLib]
  List<LogInputListener> additionalListeners() => <LogInputListener>[];

  /// If a line should not be processed (for example overridden in a subclass to skip a pattern that would never
  /// contain logs). Per default only empty lines are skipped (which never arrive anyways, because empty lines are
  /// sorted out earlier)!
  bool shouldLineBeSkipped(String line) {
    return line.isEmpty;
  }

  /// If on startup the game already produces any logs since [delayForOldLines], then this will be called with the
  /// latest [lastListener] that would have been called before with its matching [line] (because the game has
  /// probably been running for a while longer). And it will be called multiple times with older listeners as long as
  /// this returns [false]. If this returns [true] then it signals that the current listener should be the last final
  /// one and this will no longer be called!
  ///
  /// You can override this to have different behaviour depending on the type of the [lastListener].
  /// Per default this just checks if [SimpleLogInputListener.shouldStopOldLineHandling] would be true and then stop
  /// so no older listeners will be processed (to avoid false positives)!
  /// You can also override the [delayForOldLines] for a different timeframe.
  ///
  /// Don't call [LogInputListener.processLine] in here, this will be done automatically in another iteration after
  /// this, but in reversed order (to preserve the correct order: oldest to newest log line!). But
  /// [LogInputListener.matchesLine] will be checked automatically before this method is called!
  ///
  /// Important: this might still call listeners that match the same line as [lastListener] even if this returns true
  /// here! (because that is controlled depending on the order the listeners are created and what their processLine
  /// returns)
  ///
  /// Important: this will not be called if a previous line matched the [onlyHandleLastLinesUntil] if its not null
  /// (to avoid false positives for too old events)!
  ///
  /// Important: this will be called during [GameToolsLib.runLoop] after [GameManager.onStart] and the current state
  /// will be [GameClosedState] at the current point only if it didn't change in the start of a custom game manager
  /// subclass!
  bool handleLastLine(LogInputListener lastListener, String line) {
    if (lastListener is SimpleLogInputListener && lastListener.shouldStopOldLineHandling) {
      return true;
    }
    return false;
  }

  /// Adds a new [listener] to the internal list of [_listeners].
  ///
  /// Important: this can only be called after [GameToolsLib.initGameToolsLib]
  void addListener(LogInputListener listener) {
    if (_gameLogFilePaths == null || _gameLogFilePaths.isEmpty) {
      throw ConfigException(message: "tried to add listener $listener, but GameLogWatcher has no game log file path");
    }
    _listeners.add(listener);
    Logger.verbose("Added $listener");
  }

  /// Removes the [listener] from the internal list of [_listeners]
  void removeListener(LogInputListener listener) {
    _listeners.remove(listener);
    Logger.verbose("Removed $listener");
  }

  /// Returns the the [GameLogWatcher._instance] if already set, otherwise throws a [ConfigException]
  static T logWatcher<T extends GameLogWatcher>() {
    if (_instance == null) {
      throw const ConfigException(message: "GameLogWatcher was not initialized yet ");
    } else if (_instance is T) {
      return _instance as T;
    } else {
      throw ConfigException(message: "Wrong type $T for $_instance");
    }
  }

  /// Concrete instance of this controlled by [GameToolsLib]
  static GameLogWatcher? _instance;

  /// This is called automatically from [GameToolsLib.initGameToolsLib] to initialize this
  Future<bool> _init(List<LogInputListener> additionalListenerFromModules) async {
    if (_gameLogFilePaths == null || _gameLogFilePaths.isEmpty) {
      if (_listeners.isNotEmpty) {
        Logger.error("GameLogWatcher was not given a path to a game log file, but it was given LogInputListener's!");
        return false;
      } else {
        Logger.verbose("GameLogWatcher was not given a path to a game log file, so skipping processing log");
        return true;
      }
    }
    for (final String path in _gameLogFilePaths) {
      final File file = File(path);
      if (await file.exists()) {
        final DateTime newLastModified = await file.lastModified();
        if (_lastModified == null || newLastModified.isAfter(_lastModified!)) {
          _lastModified = newLastModified;
          _file = file;
        }
      }
    }
    if (_file == null) {
      Logger.error("GameLogWatcher can't find a game log file with paths: $_gameLogFilePaths");
    } else {
      final String? path = _file?.absolute.path;
      _listeners.addAll(additionalListeners());
      _listeners.addAll(additionalListenerFromModules);
      Logger.verbose("GameLogWatcher initialized with game log file path: $path and log listeners: $_listeners");
    }
    return _file != null;
  }

  /// returns if there was a listener for the line. if [shouldLineBeSkipped] returns true, this returns false
  bool _processLine(String line) {
    try {
      if (shouldLineBeSkipped(line)) {
        Logger.spam("Skipped line with size ", line.length);
        return false;
      }
      bool processedOnce = false;
      for (int i = 0; i < _listeners.length; ++i) {
        final LogInputListener listener = _listeners.elementAt(i);
        if (listener.matchesLine(line)) {
          if (listener.processLine(line)) {
            Logger.spam("Removed log line: ", line, " in listener ", listener);
            return true;
          }
          processedOnce = true;
        }
      }
      if (processedOnce == false) {
        Logger.spam("Could not find a matching LogInputListener for log line ", line);
        return false;
      } else {
        return true;
      }
    } catch (e, s) {
      Logger.error("Error processing log line", e, s);
      return true;
    }
  }

  /// Returns if the [_file] was modified since the last call to this (returns false if file or last modified are null).
  ///
  /// If the file changed last time, but not anymore, then an additional [_maxChecksAfterNoChange] checks are done
  /// with the size of the file to see if something was missed (fetch lines will continue checking empty lines after) !
  Future<bool> _didFileChange() async {
    if (_file != null && _lastModified != null) {
      DateTime newLastModified = await _file!.lastModified();
      final bool changed = _lastModified!.isBefore(newLastModified);
      if (changed && _lastChanged) {
        _skipTicks = _skipTicksOnDuplicate;
        _lastChanged = false;
        return false;
      }

      final int newSize = await _file!.length();
      if (changed == false && newSize != _lastSize) {
        _skipTicks = _skipTicksOnDuplicate;
        newLastModified = DateTime(1000);
      }
      _lastSize = newSize;
      _lastModified = newLastModified;
      _lastChanged = changed;
      return changed;
    }
    return false;
  }

  /// called after [GameManager.onStart] to process old lines if the game was already running longer.
  /// calls [handleLastLine] until it returns true. It will stop when a line matches [onlyHandleLastLinesUntil] if
  /// its not null! Also first skips lines with [shouldLineBeSkipped]!
  /// Important: the real execution will be done in the correct oder from oldest to newest, but first the check with
  /// [handleLastLine] will be in order form newest to oldest!
  Future<void> _handleOldLastLines() async {
    if (_file != null) {
      _lastModified = await _file!.lastModified(); // update to current last modified time and pos!
      _currentPos = await _file!.length();

      final DateTime oldest = DateTime.now().subtract(delayForOldLines); // only seconds precision
      if (oldest.millisecondsSinceEpoch - _lastModified!.millisecondsSinceEpoch >= 1000) {
        Logger.verbose("Did not parse old log lines, because modified $_lastModified is before $oldest");
        return;
      }
      int endPos = _currentPos;
      bool done = false;

      final List<String> linesToHandle = <String>[];
      while (endPos > 0 && !done) {
        // first read previous line
        final (String line, int newPos) = await FileUtils.readFileLineAtPosBackwards(file: _file!, endPos: endPos);
        if (onlyHandleLastLinesUntil?.matchesLine(line) ?? false) {
          Logger.spam("Handling old log lines stopped at onlyHandleLastLinesUntil: ", line);
          done = true; // if explicit stop is set, then stop when it succeeds
          break;
        }
        if (line.isNotEmpty && !shouldLineBeSkipped(line)) {
          linesToHandle.insert(0, line); // now add line to handling BUT REVERSE ORDER!
          for (final LogInputListener listener in _listeners) {
            if (listener.matchesLine(line) && handleLastLine(listener, line)) {
              Logger.spam("Handling old log lines was stopped by listener ", listener, " at line ", line);
              done = true; // completely done if the [handleLastLine] returns true
              break;
            }
          }
        }
        endPos = newPos;
      }

      int skippedLines = 0;
      bool wasHandled = false;
      for (final String line in linesToHandle) {
        for (int i = 0; i < _listeners.length; ++i) {
          final LogInputListener listener = _listeners.elementAt(i);
          if (listener.matchesLine(line)) {
            Logger.spam("Handling old log line \"", line, "\" in listener ", listener);
            wasHandled = true;
            if (listener.processLine(line)) {
              break;
            }
          }
        }
        if (wasHandled == false) {
          skippedLines++; // wasHandled check for debug log which lines were executed
        }
        wasHandled = false;
      }

      Logger.verbose("Skipped $skippedLines old log lines (handled rest). Modified $_lastModified was after $oldest");
    }
  }

  /// called and awaited periodically at the end of the event loop to process new lines and calls [_processLine]
  Future<void> _fetchNewLines() async {
    if (_skipTicks > 0) {
      _skipTicks--;
      return;
    }
    if (await _didFileChange()) {
      final (List<String> newLines, int bytes) = await FileUtils.readFileAtPosInLines(file: _file!, pos: _currentPos);
      newLines.removeWhere((String line) => line.isEmpty);
      if (newLines.isEmpty) {
        Logger.spam("GameLogWatcher got empty log lines from last change, adding delay for next change");
        _skipTicks = _skipTicksOnDuplicate;
      } else {
        Logger.spam("GameLogWatcher got ", newLines.length, " new log lines at pos ", _currentPos);
        _currentPos += bytes;
      }
      for (final String line in newLines) {
        _processLine(line);
      }
    }
  }
}
