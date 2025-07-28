part of 'package:game_tools_lib/game_tools_lib.dart';

/// Example used for testing
final class ExampleLogWatcher extends GameLogWatcher {
  /// Compare area name for testing
  String additionalListenerData = "";

  ExampleLogWatcher({required super.gameLogFilePaths, required super.listeners});

  Future<bool> manualInit() async {
    final bool result = await super._init();
    if (result == false) {
      return false;
    }
    await super._handleOldLastLines();
    return true;
  }

  Future<void> manualUpdate() async => super._fetchNewLines();

  @override
  Duration get delayForOldLines => const Duration(seconds: 1);

  @override
  List<LogInputListener> additionalListeners() => <LogInputListener>[
    // filter line: "0000/00/00 00:00:00 0000000000 ffffffff [INFO Client 00000] : You have entered Some Area."
    SimpleLogInputListener(
      matchBeforeRegex: r".*\[INFO Client .*\] : You have entered ",
      matchAfterRegex: r"\.",
      createEvent: (String data) {
        additionalListenerData = data;
        return null;
      },
    ),
  ];

  @override
  bool shouldLineBeSkipped(String line) {
    return line.isEmpty || line == "skip"; // ignore line that says "skip"
  }

  @override
  bool handleLastLine(LogInputListener lastListener, String line) {
    lastListener.processLine(line);
    if (lastListener is SimpleLogInputListener && lastListener.regex.pattern == r"^l(.*)5$") {
      return true; // for testing don't process everything and skip after "l5" is found!
    }
    return false;
  }
}
