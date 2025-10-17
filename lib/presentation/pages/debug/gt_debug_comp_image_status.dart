import 'dart:async';
import 'package:flutter/material.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/compare_image.dart';
import 'package:game_tools_lib/presentation/pages/debug/gt_debug_page.dart';

/// Only for testing/debugging used in [GTDebugPage]. Rebuilds every second to check current status
final class GTDebugCompImageStatus extends StatefulWidget {
  final String path;
  final CompareImage element;

  const GTDebugCompImageStatus({super.key, required this.path, required this.element});

  @override
  State<GTDebugCompImageStatus> createState() => _GTDebugCompImageStatusState();
}

final class _GTDebugCompImageStatusState extends State<GTDebugCompImageStatus> {
  Timer? _timer;
  late Future<bool> _contained = widget.element.isShown();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), updateCheck);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void updateCheck(Timer _) {
    _contained = widget.element.isShown();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _contained,
      builder: (BuildContext context, AsyncSnapshot<bool> snap) {
        late final String info;
        if (snap.hasData) {
          info = (snap.data ?? false) ? "Is Shown" : "Not Visible";
        } else {
          info = "Not Visible";
        }
        return Row(
          children: <Widget>[
            Expanded(child: Text("${widget.path} ")),
            const SizedBox(width: 20),
            const Text(":"),
            const SizedBox(width: 20),
            Text(info),
          ],
        );
      },
    );
  }
}
