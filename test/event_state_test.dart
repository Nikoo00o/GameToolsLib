import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_tools_lib/core/enums/event/game_event_group.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_event.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_game_manager.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_state.dart';
import 'package:game_tools_lib/domain/game/input/log_input_listener.dart';
import 'package:game_tools_lib/domain/game/states/game_closed_state.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

import 'helper/test_helper.dart';

Future<void> main() async {
  await TestHelper.runDefaultTests(
    testGroups: <String, TestFunction>{
      "GameLogWatcher": _testGameLogWatcher,
    },
  );

  await TestHelper.runOrderedTests(
    parentDescription: "Event_State_Tests",
    testGroups: <String, TestFunction>{
      "State": _testStates,
      "Event": _testEvents,
    },
  );
}

void _testStates() {
  testO("Normal game manager run", () async {
    expect(tGm.startStopCounter, 0, reason: "gm should be reset correctly");
    final Future<void> loop = GameToolsLib.runLoop(app: null); // not awaited
    await Utils.delayMS(16); // need 2 longer delays here because of internal on start await and then loop...
    await Utils.delayMS(16);
    expect(GameToolsLib.currentState is GameClosedState, true, reason: "first state is game closed");
    expect(tGm.startStopCounter, 1, reason: "gm on start call");
    expect(tGm.updateCounter > 0, true, reason: "gm onUpdate also called");
    final ExampleGameManager gm = tGm; // instance is null later
    await GameToolsLib.close();
    await loop; // closing, then awaiting loop, then checking on stop
    expect(gm.startStopCounter, -1, reason: "gm on stop call");
  });

  testO("Not calling runLoop", () async {
    expect(tGm.startStopCounter, 0, reason: "gm should be reset correctly");
    await Utils.delayMS(16);
    await Utils.delayMS(16);
    expect(GameToolsLib.currentState is GameClosedState, true, reason: "first state is game closed");
    expect(tGm.startStopCounter, 0, reason: "gm on start not called");
    expect(tGm.updateCounter, 0, reason: "gm onUpdate also not called");
  });

  testO("Testing periodic updates", () async {
    expect(tGm.startStopCounter, 0, reason: "gm should be reset correctly");
    final Future<void> loop = GameToolsLib.runLoop(app: null);
    await Utils.delayMS(16);
    await Utils.delayMS(16);
    final int next = tGm.updateCounter + 1000;
    await tGm.changeState(ExampleState());
    expect(GameToolsLib.currentState is ExampleState, true, reason: "state is changed");
    expect(eState.startStopCounter, 1, reason: "start called on new state");
    expect(eState.updateCounter >= 0 && eState.updateCounter <= 1, true, reason: "one, or no update yet");
    expect(tGm.updateCounter >= next - 1 && tGm.updateCounter <= next + 1, true, reason: "gm state change update");
    final int updatesManager = tGm.updateCounter + 6;
    final int updatesState = eState.updateCounter + 6;
    await Utils.delayMS(75);
    await Utils.delayMS(76);
    expect(tGm.updateCounter >= updatesManager - 1 && tGm.updateCounter <= updatesManager + 1, true, reason: "gm up");
    expect(eState.updateCounter >= updatesState - 1 && eState.updateCounter <= updatesState + 1, true, reason: "st up");
    final ExampleState st = eState; // instance is null later
    await GameToolsLib.close();
    await loop;
    expect(st.startStopCounter, -1, reason: "state on stop call");
  });
}

void _testEvents() {
  testO("Instant event workflow", () async {
    expect(tGm.startStopCounter, 0, reason: "gm should be reset correctly");
    unawaited(GameToolsLib.runLoop(app: null));
    await Utils.delayMS(16); // need 2 longer delays here because of internal on start await and then loop...
    await Utils.delayMS(16);
    final ExampleEvent event = ExampleEvent(isInstant: true);
    tGm.addEvent(event);
    expect(GameToolsLib.events.isEmpty, true, reason: "instant event should not be added");
    await Utils.delayMS(25);
    expect(event.updateCounter, 1, reason: "update instant");
    expect(event.startStopCounter, -1, reason: "start and close instant");
  });

  testO("Delayed event workflow", () async {
    expect(tGm.startStopCounter, 0, reason: "gm should be reset correctly");
    unawaited(GameToolsLib.runLoop(app: null));
    await Utils.delayMS(16); // need 2 longer delays here because of internal on start await and then loop...
    await Utils.delayMS(16);
    final ExampleEvent event = ExampleEvent(isInstant: false, groups: GameEventGroup.group3 | GameEventGroup.group6);
    tGm.addEvent(event);
    expect(GameToolsLib.events.length, 1, reason: "1 delayed event");
    expect(event.startStopCounter, 0, reason: "no start");
    expect(event.updateCounter, 0, reason: "no update");
    await Utils.delayMS(30); // first wait until first call
    expect(event.startStopCounter, 1, reason: "as soon as possible called start");
    expect(event.updateCounter, 1, reason: "as soon as possible one update");
    await Utils.delayMS(30); // added to delay above (wait for second call after delay of 45 ms)
    expect(event.startStopCounter, 1, reason: "45ms delay no stop called yet");
    expect(event.updateCounter, 11, reason: "45ms delay second update");
    await Utils.delayMS(40); // added to delay above (wait for third call after delay of 90 ms)
    expect(event.startStopCounter, 1, reason: "90ms delay no stop called yet");
    expect(event.updateCounter, 12, reason: "90ms delay last update");
    await Utils.delayMS(50); // added to delay above (wait for remove call after delay of 135 ms)
    expect(event.updateCounter, 12, reason: "135ms delay no update");
    expect(event.startStopCounter, -1, reason: "135ms delay closed now");
    expect(GameToolsLib.events.length, 0, reason: "135ms delay events also empty");
  });

  testO("Delayed event find and state change test", () async {
    expect(tGm.startStopCounter, 0, reason: "gm should be reset correctly");
    unawaited(GameToolsLib.runLoop(app: null));
    await Utils.delayMS(16); // need 2 longer delays here because of internal on start await and then loop...
    await Utils.delayMS(16);
    final ExampleEvent event = ExampleEvent(isInstant: false, groups: GameEventGroup.group3 | GameEventGroup.group6);
    tGm.addEvent(event);
    tGm.addEvent(event); // don't add twice
    expect(GameToolsLib.events.length, 1, reason: "1 delayed event");
    expect(GameToolsLib.getEventByType<ExampleEvent>().length, 1, reason: "1 event by type");
    expect(GameToolsLib.getEventByType<String>().length, 0, reason: "0 wrong type");
    expect(GameToolsLib.getEventByGroup(GameEventGroup.group1).length, 0, reason: "0 wrong group");
    expect(GameToolsLib.getEventByGroup(GameEventGroup.group3).length, 1, reason: "1 correct group");
    expect(GameToolsLib.getEventByGroup(GameEventGroup.group6).length, 1, reason: "1 correct group 2");
    await tGm.changeState(ExampleState());
    expect(event.updateCounter >= 1000, true, reason: "state change should instantly update event");
  });
}

// these tests can be run at the same time, because they don't affect static variables
void _testGameLogWatcher() {
  const String initialContent =
      "l4\r\nskip\n\nl5\n0000/00/00 00:00:00 0000000000 ffffffff [INFO Client 00000] : You have entered Some Area.";

  testD("Error initialize with no file path", () async {
    final ExampleLogWatcher lw = ExampleLogWatcher(
      gameLogFilePaths: <String>["INVALID_FILE"],
      listeners: <LogInputListener>[],
    );
    expect(await lw.manualInit(), false, reason: "init fail without path");
  });

  testD("With too much delay, old logs should not be added", () async {
    final String logFile = testFile("write_test_2.txt");
    final ExampleLogWatcher lw = ExampleLogWatcher(
      gameLogFilePaths: <String>[logFile],
      listeners: null,
    );
    await FileUtils.deleteFile(logFile);
    await FileUtils.writeFile(logFile, initialContent);
    await Utils.delayMS(2100); // file timestamp only counts seconds
    expect(await lw.manualInit(), true, reason: "init success");
    expect(lw.additionalListenerData.isEmpty, true, reason: "old logs should have taken too long");
    await lw.manualUpdate();
    expect(lw.additionalListenerData.isEmpty, true, reason: "also new logs should be produced");
    await FileUtils.deleteFile(logFile);
  });

  testD("Small delay should add old logs and now also test new logs", () async {
    final String logFile = testFile("write_test_1.txt");
    bool l4 = false;
    bool l5 = false;
    bool l6 = false;
    final ExampleLogWatcher lw = ExampleLogWatcher(
      gameLogFilePaths: <String>[logFile],
      listeners: <LogInputListener>[
        SimpleLogInputListener(
          matchBeforeRegex: "l",
          matchAfterRegex: "4",
          createEvent: (String data) {
            if (data.isEmpty) {
              l4 = true;
            }
            return null;
          },
        ),
        SimpleLogInputListener(
          matchBeforeRegex: "l",
          matchAfterRegex: "5",
          createEvent: (String data) {
            if (data.isEmpty) {
              l5 = true;
            }
            return null;
          },
        ),
        SimpleLogInputListener(
          matchBeforeRegex: "l",
          matchAfterRegex: "6",
          createEvent: (String data) {
            if (data.isEmpty && l5 == true) {
              l6 = true; // should be called in correct order
            }
            return null;
          },
        ),
      ],
    );
    await FileUtils.deleteFile(logFile);
    await FileUtils.writeFile(logFile, initialContent);
    await Utils.delayMS(999); // because milliseconds are not counted, a full second is still fine
    expect(await lw.manualInit(), true, reason: "init success");
    expect(l5, true, reason: "old lines parse last only");
    expect(l4 || l6, false, reason: "old don't parse others"); // old lines should be parsed here
    expect(lw.additionalListenerData, "Some Area", reason: "old also parse correct data");

    l4 = false;
    l5 = false;
    l6 = false;
    await Utils.delayMS(1100); // file timestamp only counts seconds
    await FileUtils.addToFile(
      logFile,
      "l5\r\nskip\n\nl6\n0000/00/00 00:00:00 0000000000 ffffffff [INFO Client 00000] : You have entered 시험 Area.",
    );
    await lw.manualUpdate();
    expect(l5, true, reason: "first parse first");
    expect(l6, true, reason: "then parse second");
    expect(lw.additionalListenerData, "시험 Area", reason: "but also parse correct data");

    l5 = false;
    l6 = false;
    await Utils.delayMS(1100);
    await FileUtils.addToFile(logFile, "\r\nl5");
    await lw.manualUpdate();
    expect(l5, true, reason: "parse first");
    expect(l6, false, reason: "but not second");
    await FileUtils.deleteFile(logFile);
  });
}
