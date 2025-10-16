import 'package:game_tools_lib/core/enums/event/game_event_priority.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

/// This is the base class for all listeners of [GameLogWatcher] that react to new game log lines and add new events in
/// reaction to them. Either extend from this, or create objects of [SimpleLogInputListener] if you don't need custom
/// logic and just need to regex match the log line and create a new object of a subtype of [GameEvent] depending on
/// the data.
///
/// If you need more custom control, you can override [matchesLine] and [processLine] from this.
///
/// This does not relate to the [BaseInputListener]! This is updated automatically at the end of the event loop of
/// [GameToolsLib]!
abstract base class LogInputListener {
  /// This will be called first when the [GameLogWatcher] is processing a game log line and it should return if this
  /// listener matches and should be executed for the [line] with [processLine].
  bool matchesLine(String line);

  /// This should do the work of adding a new event with [addEvent] with the data of [line].
  /// And then it should return true if the [line] should be removed and no longer be processed by other listeners
  /// (which should be the default). Otherwise if false, other listeners will also have this method called with the
  /// same line.
  bool processLine(String line);

  /// Helper method to add a new event to the internal event queue by just calling [GameToolsLib.addEvent].
  void addEvent(GameEvent event) => GameToolsLib.addEvent(event);

  @override
  String toString() => "$runtimeType()";
}

/// This is a simplified version for [LogInputListener] which you can use by looking at the documentation of the
/// constructor of this [SimpleLogInputListener]!
///
/// You will build a regex to match your line and then just return a matching event for it which will automatically
/// be added to the internal event queue!
///
/// [processLine] will always return true here to not call any other listeners and will use the [regex] to match with
/// what data [createEvent] will be called (the data can also be null if no data from the log is needed). And then it
/// just adds the event created to the event queue.
///
/// For very quick non-async actions that need no event, use [SimpleLogInputListener.instant] instead of a [GameEvent]
/// with [GameEventPriority.INSTANT]!
final class SimpleLogInputListener extends LogInputListener {
  /// The internal regular expression that will be matched against the lines. It has a capturing group for each part
  /// (target data, match before, match after)
  ///
  /// Example for match for a log like: `LOG_TIME [LOGLEVEL] : TARGET_MESSAGE - END.`
  /// Here your first part would be: `r".*] : "` and your last part would be `r" - END\."` (constructor params)
  /// And the resulting regex would be: `r"^.*] : (.*) - END\.$"`
  /// And like this the [createEvent] would receive "TARGET_MESSAGE"
  ///
  /// It would be good to store the regex strings in multi language [JsonAsset]'s if the game log messages are
  /// translated!
  late final RegExp regex;

  /// This callback should create a new subclass object of [GameEvent] which will then be added internally to the
  /// event queue! Important the searched data string parameter will be the characters of the line that is between
  /// the matched start and end regexes. It may also be empty if there is no data needed from the log!
  /// Of course this may also return null and then no event will be added!
  final GameEvent? Function(String searchedData) createEvent;

  /// This will internally build the [regex] as looking for a line that starts with [matchBeforeRegex] and ends with
  /// [matchAfterRegex]. Then the text in between those will be passed to your [createEvent] as the search data! That
  /// regex will then be matched against the lines. If the optional end [matchAfterRegex] is null, then it will be
  /// ignored at treat the search data as the rest of the line!
  ///
  /// Remember to not use any of the following characters in your regex strings: "^", "$", "(", ")" and also dont use
  /// any ".*" in the direction of your target search data! For an example what to use in your regex, look at the
  /// docs of [regex] and [createEvent]! And also remember to use a raw string and escape special characters
  /// like brackets in your regex like for example r"\[te.*st\]"
  ///
  /// The [createEvent] should just create a new object of a [GameEvent] subclass which will then internally be added
  /// to the event queue!
  SimpleLogInputListener({
    required String matchBeforeRegex,
    required String? matchAfterRegex,
    required this.createEvent,
  }) {
    final StringBuffer buf = StringBuffer(r"^");
    buf.write(matchBeforeRegex);
    buf.write(r"(.*)");
    if (matchAfterRegex != null) {
      buf.write(matchAfterRegex);
      buf.write(r"$");
    }
    regex = RegExp(buf.toString());
  }

  /// Similar to the default constructor this will internally build the [regex] as looking for a line that starts with
  /// [matchBeforeRegex] and ends with [matchAfterRegex]. Then the text in between those will be passed to your
  /// [createEvent] as the search data! That  regex will then be matched against the lines. If the optional end
  /// [matchAfterRegex] is null, then it will be ignored at treat the search data as the rest of the line!
  ///
  /// Remember to not use any of the following characters in your regex strings: "^", "$", "(", ")" and also dont use
  /// any ".*" in the direction of your target search data! For an example what to use in your regex, look at the
  /// docs of [regex] and [createEvent]! And also remember to use a raw string and escape special characters
  /// like brackets in your regex like for example r"\[te.*st\]"
  ///
  /// Here there is no [GameEvent] to be created and instead [quickAction] will be called with your searched data string
  /// parameter which will be the characters of the line that is between the matched start and end regexes. It may
  /// also be empty if there is no data needed from the log!
  /// This should only be used for very quick non-async actions instead of using [GameEvent] with
  /// [GameEventPriority.INSTANT]!
  factory SimpleLogInputListener.instant({
    required String matchBeforeRegex,
    required String? matchAfterRegex,
    required void Function(String searchedData) quickAction,
  }) {
    GameEvent? createEvent(String searchedData) {
      Logger.spamPeriodic(
        _instantLog,
        "SimpleLogInputListener quick action called with before ",
        matchBeforeRegex,
        " after ",
        matchAfterRegex,
        " and search data ",
        searchedData,
      );
      quickAction.call(searchedData);
      return null;
    }

    return SimpleLogInputListener(
      matchBeforeRegex: matchBeforeRegex,
      matchAfterRegex: matchAfterRegex,
      createEvent: createEvent,
    );
  }

  static final SpamIdentifier _instantLog = SpamIdentifier();

  @override
  bool matchesLine(String line) => regex.hasMatch(line);

  @override
  bool processLine(String line) {
    final RegExpMatch? match = regex.firstMatch(line);
    if (match == null) {
      Logger.spam("SimpleLogInputListener regex ", regex, " did not have a match with ", line);
    }
    final int groupCount = match?.groupCount ?? 0;
    final String? data = groupCount == 1 ? match?.group(1) : null;
    final GameEvent? event = createEvent.call(data ?? "");
    if (event != null) {
      addEvent(event);
    }
    return true;
  }

  @override
  String toString() => "SimpleLogInputListener(regex: ${regex.pattern} )";
}
