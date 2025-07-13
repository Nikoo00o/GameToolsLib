import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/data/game/game_window.dart';
import 'package:game_tools_lib/data/native/native_window.dart';
import 'package:game_tools_lib/domain/entities/model.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

/// this should be unawaited
Future<void> _constantRebuilds(StateSetter setState, int millisecondDelay) async {
  while (true) {
    await Utils.delay(Duration(milliseconds: millisecondDelay));
    setState(() {});
  }
}

class ExampleApp extends StatelessWidget {
  Future<void>? _rebuilder;
  final bool init;

  ExampleApp({required this.init});

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        _rebuilder ??= _constantRebuilds(setState, 50);
        final bool windowFound = GameToolsLib.mainGameWindow.isWindowOpen();
        String windowText = "Initialized $init, window ${GameToolsLib.mainGameWindow.name} found: $windowFound";
        if (windowFound) {
          windowText = "$windowText at Pos ${GameToolsLib.mainGameWindow.getWindowBounds()}";
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(windowText),
              SizedBox(height: 5),
              Text("Display Cursor Pos: ${InputManager.displayMousePos}"),
              SizedBox(height: 5),
              if (windowFound) Text("Window Cursor Pos: ${GameToolsLib.mainGameWindow.windowMousePos}"),
              SizedBox(height: 5),
              if (windowFound) Text("Pixel Colour: ${InputManager.getPixelAtCursor(GameToolsLib.mainGameWindow)}"),
              SizedBox(height: 5),
              ElevatedButton(onPressed: () => GameToolsLib.mainGameWindow.moveMouse(0, 0), child: Text("move mouse")),
              SizedBox(height: 5),
              Text("oem1: ${InputManager.isKeyDown(BoardKey.oem1)}"),
              Text("oem2: ${InputManager.isKeyDown(BoardKey.oem2)}"),
              Text("oem3: ${InputManager.isKeyDown(BoardKey.oem3)}"),
              Text("oem4: ${InputManager.isKeyDown(BoardKey.oem4)}"),
              Text("oem5: ${InputManager.isKeyDown(BoardKey.oem5)}"),
              Text("oem6: ${InputManager.isKeyDown(BoardKey.oem6)}"),
              Text("oem7: ${InputManager.isKeyDown(BoardKey.oem7)}"),
            ],
          ),
        );
      },
    );
  }
}

Future<void> main() async {
  final bool init = await GameToolsLibHelper.useExampleConfig(isCalledFromTesting: true, windowName: "Snipping Tool");

  runApp(
    MaterialApp(
      home: Scaffold(
        body: ExampleApp(init: init),
      ),
    ),
  );
}
