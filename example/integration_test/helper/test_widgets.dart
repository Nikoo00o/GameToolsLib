import 'package:flutter/material.dart';

final class TestApp extends StatelessWidget {
  final String title;
  final Widget child;

  const TestApp({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: title,
    theme: ThemeData(scaffoldBackgroundColor: Colors.white),
    home: Scaffold(body: child),
  );
}

abstract base class _TestPositionedPage extends StatelessWidget {
  List<Widget> buildStackChildren(BuildContext context, StateSetter setState);

  Widget buildContainer(int x, int y, int width, int height, Color color) => Positioned(
    left: x.toDouble(),
    top: y.toDouble(),
    child: Container(color: color, width: width.toDouble(), height: height.toDouble()),
  );

  Widget buildButton(int x, int y, VoidCallback callback, Text text) => Positioned(
    left: x.toDouble(),
    top: y.toDouble(),
    child: ElevatedButton(onPressed: callback, child: text),
  );

  Widget buildEditText(int x, int y, int width, int height, TextEditingController controller) => Positioned(
    left: x.toDouble(),
    top: y.toDouble(),
    child: SizedBox(
      width: width.toDouble(),
      height: height.toDouble(),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(border: OutlineInputBorder()),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) => Stack(children: buildStackChildren(context, setState)),
  );
}

final class TestColouredBoxes extends _TestPositionedPage {
  final TextEditingController _edit = TextEditingController(text: "");

  @override
  List<Widget> buildStackChildren(BuildContext context, StateSetter setState) {
    return <Widget>[
      buildContainer(0, 0, 100, 100, Colors.blue),
      // one more pixel to the top (because middle would be at 290.5),
      buildContainer(582, 290, 100, 100, Colors.yellow),
      // also one more to the top (because middle would be at 339.5),
      buildContainer(630, 338, 4, 4, Colors.red),
      buildContainer(1164, 581, 100, 100, Colors.purple),
      buildButton(25, 625, () => setState(() => _edit.text = "after button"), Text("set text field")),
      buildEditText(1030, 25, 200, 50, _edit),
    ];
  }
}
