import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/locale_extension.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_event.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_app.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/pages/debug/gt_debug_page.dart';

/// Used in [GTDebugPage] and constantly rebuilds and refreshes!
class GTDebugStatus extends StatefulWidget {
  static const int rebuildEveryMS = 80;

  const GTDebugStatus({super.key});

  @override
  State<GTDebugStatus> createState() => _GTDebugStatusState();
}

class _GTDebugStatusState extends State<GTDebugStatus> with GTBaseWidget {
  Timer? _timer;

  TextEditingController controller = TextEditingController();

  /// called inside of setState
  void _rebuild() {}

  GameWindow get window => GameToolsLib.mainGameWindow;

  GameToolsConfigBaseType get config => GameToolsLib.baseConfig;

  void _updateColorText(Color? color) {
    if (color != null) {
      String text = color.rgb.substring(6);
      text = text.substring(0, text.length - 1);
      if (controller.text != text) {
        controller.text = text;
      }
    }
  }

  Widget _buildColorWidget(BuildContext context, Color? color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Text("Color at cursor in window: "),
        const SizedBox(width: 4),
        Material(
          shape: const Border(
            right: BorderSide(
              width: 1,
              color: Colors.red,
            ),
            left: BorderSide(
              width: 1,
              color: Colors.green,
            ),
            bottom: BorderSide(
              width: 1,
              color: Colors.blue,
            ),
            top: BorderSide(
              width: 1,
              color: Colors.yellow,
            ),
          ),
          child: Container(
            height: 25,
            width: 80,
            color: color,
            child: color == null ? const Center(child: Text("is null")) : null,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          height: 26,
          width: 250,
          child: TextField(
            controller: controller,
            maxLines: 1,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              isCollapsed: true,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOpen = window.isOpen;
    final Color? color = isOpen ? InputManager.getPixelAtCursor(window) : null;
    _updateColorText(color);
    return Column(
      children: <Widget>[
        Text("Main GameWindow: ${window.name} at pos ${isOpen ? window.getWindowBounds().toStringAsPos() : "null"}"),
        Text("Is Open: $isOpen"),
        Text("Has Focus: ${window.hasFocus}"),
        Text("Display Cursor Pos: ${InputManager.displayMousePos}"),
        Text("Window Cursor Pos: ${isOpen ? window.windowMousePos : "null"}"),
        _buildColorWidget(context, color),
        const SizedBox(height: 15),
        Text(
          "Recognized test dir (should only be true when debugging from IDE): ${FileUtils.wasRunFromTests} and "
          "test database (should always be false): ${GameToolsLib.database is HiveDatabaseMock}",
        ),
        Text("Current database dir: ${config.databaseFolder}"),
        const SizedBox(height: 2),
        Text(
          "Current locale directories (from asset folders from all packages and self) for ${GTApp.currentLocale?.fileName}:",
        ),
        Text(config.localeFolders.join("\n")),
        const SizedBox(height: 2),
        Text("Press \"A\" and this should be true: ${InputManager.isKeyDown(BoardKey.a)}"),
        Text("And if you press \"CTRL+A\" to test event and clipboard, this should be true: $didEventAndClipboardWork"),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: GTDebugStatus.rebuildEveryMS), (Timer timer) {
      if (mounted) {
        setState(() {
          _rebuild();
        });
      }
    });
    didEventAndClipboardWork = null;
    GameToolsLib.gameManager().addInputListener(listener);
  }

  static final KeyInputListener listener = KeyInputListener(
    configLabel: "page.debug.status.test.listener",
    createEventCallback: () => ExampleEvent(isInstant: false, additionalWorkInStep1: _testEventAndClipboard),
    alwaysCreateNewEvents: true,
    defaultKey: BoardKey.ctrlA,
    eventCreateCondition: () => true,
  );

  static Future<void> _testEventAndClipboard() async {
    try {
      final String userData = await InputManager.getClipboard();
      await InputManager.setClipboard("12345");
      final String myData = await InputManager.getClipboard();
      await InputManager.setClipboard(userData); // with an instant event the user could still override his clipboard
      // if he is spamming the button!
      didEventAndClipboardWork = myData == "12345";
    } catch (_) {
      didEventAndClipboardWork = false;
    }
  }

  static bool? didEventAndClipboardWork;

  @override
  void dispose() {
    _timer?.cancel();
    GameToolsLib.gameManager().removeInputListener(listener);
    super.dispose();
  }
}
