import 'dart:io';
import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/data/game/game_window.dart';
import 'package:game_tools_lib/domain/entities/model.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

/// this should be unawaited
Future<void> _constantRebuilds(StateSetter setState, int millisecondDelay) async {
  while (true) {
    await Future<void>.delayed(Duration(milliseconds: millisecondDelay));
    /*
    await GameToolsLib.mainGameWindow.moveMouse(
      GameToolsLib.mainGameWindow.getWindowBounds().size.x ~/ 2,
      GameToolsLib.mainGameWindow.getWindowBounds().size.y ~/ 2,
    );
    */
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
              Text("Display Cursor Pos: ${GameWindow.displayMousePos}"),
              SizedBox(height: 5),
              if (windowFound) Text("Window Cursor Pos: ${GameToolsLib.mainGameWindow.windowMousePos}"),
              SizedBox(height: 5),
              if (windowFound) Text("Pixel Colour: ${GameToolsLib.mainGameWindow.getPixelAtCursor()}"),
              SizedBox(height: 5),
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
