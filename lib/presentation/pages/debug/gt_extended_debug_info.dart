import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/file_utils.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/domain/game/helper/example/example_event.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/pages/debug/gt_debug_page.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Used in [GTDebugPage] and constantly rebuilds and refreshes a part of this!
class GtExtendedDebugInfo extends StatefulWidget {
  static const int rebuildEveryMS = 80;

  const GtExtendedDebugInfo({super.key});

  @override
  State<GtExtendedDebugInfo> createState() => _GtExtendedDebugInfoState();
}

class _GtExtendedDebugInfoState extends State<GtExtendedDebugInfo> with GTBaseWidget {
  Timer? _timer;

  TextEditingController controller = TextEditingController();

  GameWindow get window => GameToolsLib.mainGameWindow;

  GameToolsConfigBaseType get config => GameToolsLib.baseConfig;

  Widget buildAssetInfo(BuildContext context) {
    final List<String> assetDirs = List<String>.of(GameToolsConfig.baseConfig.staticAssetFolders);
    assetDirs.insert(0, GameToolsConfig.resourceFolderPath); // root path to project "data" first
    final String baseAssetPath = FileUtils.parentPath(assetDirs.last); // last one is always direct asset dir of app
    final List<String> simplePaths = assetDirs.map((String path) {
      return path.substring(baseAssetPath.length);
    }).toList();
    simplePaths.removeAt(0); // not the resource
    void openAssetsFoldersInExplorer() {
      for (final String assets in assetDirs) {
        Logger.verbose("Opening $assets");
        launchUrlString("file://$assets");
      }
    }

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            const Spacer(),
            Text("Base resource data directory: ${GameToolsConfig.resourceFolderPath}"),
            const Spacer(),
            FilledButton(onPressed: openAssetsFoldersInExplorer, child: const Text("Open all Assets")),
            const Spacer(),
          ],
        ),
        Center(child: Text("And all asset directories from $baseAssetPath are:\n${simplePaths.join("\n")}")),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(12.0),
        ),
        color: colorSurfaceContainerLow(context),
      ),
      child: Column(
        children: <Widget>[
          Text("Current database dir: ${GameToolsLib.database is HiveDatabaseMock ? "null" : config.databaseFolder}"),
          const SizedBox(height: 2),
          Text(
            "Accessing game paths: ${GameLogWatcher.logWatcher().readingFromPath}, ${GameToolsLib.gameConfigLoader<GameConfigLoader?>()?.filePath}",
          ),
          const SizedBox(height: 2),
          buildAssetInfo(context),
          const SizedBox(height: 2),
          StatefulBuilder(builder: buildWithState),
        ],
      ),
    );
  }

  StateSetter? _stateSetter;

  Widget buildWithState(BuildContext context, StateSetter setState) {
    _stateSetter = setState;
    return Column(
      children: <Widget>[
        Text("Press \"A\" and this should be true: ${InputManager.isKeyDown(BoardKey.a)}"),
        Text(
          "And if you press \"CTRL+A\" to test event and clipboard, this should be true: $didEventAndClipboardWork",
        ),
      ],
    );
  }

  void _rebuildState(Timer timer) {
    if (mounted) {
      _stateSetter?.call(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: GtExtendedDebugInfo.rebuildEveryMS), _rebuildState);
    didEventAndClipboardWork = null;
    GameToolsLib.gameManager().addInputListener(listener);
  }

  static final KeyInputListener listener = KeyInputListener(
    configLabel: const TS("page.debug.status.test.listener"),
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
