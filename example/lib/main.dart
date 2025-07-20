import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_event.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_app.dart';
import 'package:game_tools_lib/presentation/pages/gt_home.dart';
import 'package:game_tools_lib/presentation/pages/logs/gt_logs_page.dart';
import 'package:provider/provider.dart';

// todo: create template with either template as prefix or "my" for the different overrides

/// this should be unawaited, used for periodic tests
Future<void> _constantRebuilds(StateSetter setState, int millisecondDelay) async {
  while (true) {
    await Utils.delay(Duration(milliseconds: millisecondDelay));
    setState(() {});
  }
}

/// Used for quick tests/debugging on button click
Future<void> _testSomething() async {}

final class ExampleHome extends GTHome {
  Future<void>? _builder;

  ExampleHome({
    super.key,
    super.backgroundImage,
    super.backgroundColor,
    super.pagePadding,
  });

  bool test(BuildContext context) {
    final BoolConfigOption loc1 = context.watch<BoolConfigOption>();
    return loc1.cachedValueNotNull();
  }

  @override
  Widget buildBody(BuildContext context) {
    Logger.info("rebuild example home2");
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        //_builder ??= _constantRebuilds(setState, 50);
        final bool windowFound = GameToolsLib.mainGameWindow.updateAndGetOpen();
        String windowText = "window ${GameToolsLib.mainGameWindow.name} found: $windowFound";
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
              FilledButton(onPressed: () => GameToolsLib.mainGameWindow.moveMouse(0, 0), child: Text("move mouse")),
              SizedBox(height: 5),
              FilledButton.tonal(onPressed: () => InputManager.keyPress(BoardKey.ctrlC), child: Text("copy to clip")),
              SizedBox(height: 5),
              OutlinedButton(onPressed: _testSomething, child: Text("Test Something")),
              ElevatedButton(
                onPressed: () {
                  final BoolConfigOption darkTheme = MutableConfig.mutableConfig.useDarkTheme;
                  darkTheme.setValue(!darkTheme.cachedValueNotNull());
                },
                child: Text("Change Dark theme"),
              ),
              TextButton(
                onPressed: () {
                  final LocaleConfigOption locale = MutableConfig.mutableConfig.currentLocale;
                  locale.setValue(locale.activeLocale == Locale("de") ? Locale("en") : Locale("de"));
                },
                child: Text("Change Locale"),
              ),
              SizedBox(height: 5),
              Text("oem1: ${InputManager.isKeyDown(BoardKey.oem1)}"),
              Text("oem2: ${InputManager.isKeyDown(BoardKey.oem2)}"),
              Text("oem3: ${InputManager.isKeyDown(BoardKey.oem3)}"),
              Text("oem4: ${InputManager.isKeyDown(BoardKey.oem4)}"),
              Text("oem5: ${InputManager.isKeyDown(BoardKey.oem5)}"),
              Text("oem6: ${InputManager.isKeyDown(BoardKey.oem6)}"),
              Text("oem7: ${InputManager.isKeyDown(BoardKey.oem7)}"),
              SizedBox(height: 5),
              Text("Was run from tests: ${FileUtils.wasRunFromTests}"),
              SizedBox(height: 5),
              Text("Translate 1: ${translate(context, "empty.1")}"),
              SizedBox(height: 5),
              Text("Translate 2: ${translate(context, "empty.3")}"),
              TextButton(
                onPressed: () {
                  pushPage(context, GTLogsPage());
                },
                child: Text("Navigate to logs"),
              ),
            ],
          ),
        );
      },
    );
  }
}

String get testFolder => FileUtils.combinePath(<String>[FileUtils.getLocalFilePath("test"), "test_data"]);

String testFile(String fileName) => FileUtils.combinePath(<String>[testFolder, fileName]);

Future<void> main() async {
  final bool init = await GameToolsLib.useExampleConfig(
    isCalledFromTesting: FileUtils.wasRunFromTests,
    windowName: "Snipping Tool",
  );
  if (init == false) {
    return; // todo: show some error ui?
  }
  GameToolsLib.gameManager().addInputListener(
    KeyInputListener(
      configLabel: "h",
      createEventCallback: () => ExampleEvent(isInstant: false),
      alwaysCreateNewEvents: true,
      defaultKey: BoardKey.h,
    ),
  );
  GameToolsLib.gameManager().addInputListener(
    KeyInputListener(
      configLabel: "ctrlC",
      createEventCallback: () => ExampleEvent(isInstant: false),
      alwaysCreateNewEvents: true,
      defaultKey: BoardKey.ctrlC,
    ),
  );

  await GameToolsLib.runLoop(
    app: GTApp(startPage: ExampleHome()),
  );
}
