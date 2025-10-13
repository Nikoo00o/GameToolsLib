import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/pages/debug/gt_debug_page.dart';

/// Used in [GTDebugPage] and constantly rebuilds and refreshes a part of this!
class GTDebugStatus extends StatefulWidget {
  static const int rebuildEveryMS = 80;

  const GTDebugStatus({super.key});

  @override
  State<GTDebugStatus> createState() => _GTDebugStatusState();
}

class _GTDebugStatusState extends State<GTDebugStatus> with GTBaseWidget {
  Timer? _timer;

  TextEditingController controller = TextEditingController();

  GameWindow get window => GameToolsLib.mainGameWindow;

  GameToolsConfigBaseType get config => GameToolsLib.baseConfig;

  Color? oldColor;

  void _updateColorText(Color? color) {
    if (color != null) {
      String text = color.rgb.substring(6);
      text = text.substring(0, text.length - 1);
      if (controller.text != text && window.isOpen && window.hasFocus) {
        controller.text = text;
      }
      if (color != oldColor) {
        setState(() {
          // full rebuild on color change!
        });
      }
    }
    oldColor = color;
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
          Text("Main GameWindow: ${window.name} at pos ${isOpen ? window.getWindowBounds().toStringAsPos() : "null"}"),
          const SizedBox(height: 2),
          Text(
            "Is Open: $isOpen   And Has Focus: ${window.hasFocus}.        Running from IDE: ${FileUtils.wasRunFromTests}",
          ),
          const SizedBox(height: 2),
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) => buildWithState(context, setState, isOpen),
          ),
        ],
      ),
    );
  }

  StateSetter? _stateSetter;

  //ignore: avoid_positional_boolean_parameters
  Widget buildWithState(BuildContext context, StateSetter setState, bool isOpen) {
    _stateSetter = setState;
    return Column(
      children: <Widget>[
        Text(
          "Display Cursor Pos: ${InputManager.displayMousePos} and Window Cursor Pos: ${isOpen ? window.windowMousePos : "null"}",
        ),
        _buildColorWidget(context, oldColor),
      ],
    );
  }

  void _rebuildState(Timer timer) {
    if (mounted) {
      // performance reason: check color periodically and in update setstate if changed
      final Color? color = window.isOpen ? InputManager.getPixelAtCursor(window) : null;
      _updateColorText(color);
      _stateSetter?.call(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: GTDebugStatus.rebuildEveryMS), _rebuildState);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
