import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/data/native/native_image.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_event.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_app.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/canvas_overlay_element.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/overlay_element.dart';
import 'package:game_tools_lib/presentation/pages/logs/gt_logs_page.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigation_page.dart';
import 'package:provider/provider.dart';

// todo: create template with either template as prefix or "my" for the different overrides

/// Used for quick tests/debugging on button click
Future<void> _testOverlay() async {
  final OverlayElement someElement1 = OverlayElement.forPos(
    x: 10,
    y: 10,
    width: 100,
    height: 200,
    identifier: TS.raw("overlay.example.1"),
  );
  someElement1.visible = !someElement1.visible;

  final CanvasOverlayElement someElement2 = CanvasOverlayElement.forPos(
    x: 200,
    y: 200,
    width: 150,
    height: 250,
    identifier: TS.raw("overlay.example.2"),
    color: Colors.green,
  );
  someElement2.visible = !someElement2.visible;

  Logger.info("Example overlay test: $someElement1 and $someElement2");
}

final class ExamplePage extends GTNavigationPage {
  const ExamplePage({
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
          windowText = "$windowText with size ${GameToolsLib.mainGameWindow.updateAndGetSize()}";
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 5),
              Text(windowText),
              SizedBox(height: 5),
              FilledButton(onPressed: () => GameToolsLib.mainGameWindow.moveMouse(0, 0), child: Text("move mouse")),
              SizedBox(height: 5),
              FilledButton.tonal(
                onPressed: () async {
                  final NativeImage img = await GameToolsLib.mainGameWindow.getFullImage();
                  if (context.mounted) {
                    await img.showImageDialog(context);
                  }
                },
                child: Text("Screenshot"),
              ),
              SizedBox(height: 5),
              OutlinedButton(onPressed: _testOverlay, child: Text("Test Something")),
              SizedBox(height: 5),
              Text("oem1: ${InputManager.isKeyDown(BoardKey.oem1)}"),
              Text("oem2: ${InputManager.isKeyDown(BoardKey.oem2)}"),
              Text("oem3: ${InputManager.isKeyDown(BoardKey.oem3)}"),
              Text("oem4: ${InputManager.isKeyDown(BoardKey.oem4)}"),
              Text("oem5: ${InputManager.isKeyDown(BoardKey.oem5)}"),
              Text("oem6: ${InputManager.isKeyDown(BoardKey.oem6)}"),
              Text("oem7: ${InputManager.isKeyDown(BoardKey.oem7)}"),
              SizedBox(height: 5),
              Text("Translate: ${TS("empty.3").tl(context)}"),
              SizedBox(height: 5),
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

  @override
  TranslationString get navigationLabel => TS.raw("Example Page");

  @override
  IconData get navigationNotSelectedIcon => Icons.add;

  @override
  IconData get navigationSelectedIcon => Icons.add_rounded;

  @override
  String get pageName => "ExamplePage";
}

String get testFolder => FileUtils.combinePath(<String>[FileUtils.getLocalFilePath("test"), "test_data"]);

String testFile(String fileName) => FileUtils.combinePath(<String>[testFolder, fileName]);

Future<void> main() async {
  final bool init = await GameToolsLib.useExampleConfig(
    isCalledFromTesting: false,
    windowName: "Snipping Tool",
  );
  if (init == false) {
    Logger.error("Could not init lib");
    return; // todo: show some error ui?
  }
  GameToolsLib.gameManager().addInputListener(
    KeyInputListener(
      configLabel: TS.raw("Example def h"),
      createEventCallback: () => ExampleEvent(isInstant: true),
      alwaysCreateNewEvents: true,
      defaultKey: BoardKey.h,
    ),
  );
  GameToolsLib.gameManager().addInputListener(
    KeyInputListener(
      configLabel: TS.raw("Copy with ctrlC"),
      createEventCallback: () => ExampleEvent(isInstant: true),
      alwaysCreateNewEvents: true,
      defaultKey: BoardKey.ctrlC,
    ),
  );

  GameToolsLib.gameManager().addInputListener(
    KeyInputListener(
      configLabel: const TS.empty(),
      createEventCallback: () => ExampleEvent(isInstant: false),
      alwaysCreateNewEvents: true,
      defaultKey: BoardKey.a,
    ),
  );

  GameToolsLib.gameManager().addInputListener(
    KeyInputListener(
      configLabel: TS.raw("Should be Key B"),
      configLabelDescription: TS.raw(
        "Must be set later. test test test test test test test test test test test test test "
        "test test test test test test test test ",
      ),
      configGroupLabel: TS.raw("test"),
      createEventCallback: () => ExampleEvent(isInstant: false),
      alwaysCreateNewEvents: true,
      defaultKey: null,
    ),
  );

  GameToolsLib.gameManager().addInputListener(
    KeyInputListener(
      configLabel: TS.raw("Some nice action"),
      configGroupLabel: TS.raw("test"),
      createEventCallback: () => ExampleEvent(isInstant: false),
      alwaysCreateNewEvents: true,
      defaultKey: BoardKey.c,
    ),
  );

  await GameToolsLib.runLoop(
    app: GTApp(
      additionalNavigatorPages: <GTNavigationPage>[ExamplePage()],
    ),
  );
}
