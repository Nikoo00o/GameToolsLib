import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';

/// Builds a button that opens a dialog to pick a color
class SimpleColorPicker extends StatefulWidget {
  /// The color which this should modify (to display the current color)
  final Color colorToShow;

  /// Not translated name of the color that is adjusted here
  final String colorName;

  final ValueChanged<Color> onColorChange;

  const SimpleColorPicker({super.key, required this.colorToShow, required this.colorName, required this.onColorChange});

  @override
  State<SimpleColorPicker> createState() => _SimpleColorPickerState();
}

class _SimpleColorPickerState extends State<SimpleColorPicker> with GTBaseWidget {
  /// The inner current color which is selected / picked in the dialog (but updated when this is build with a
  /// different color!)
  late Color pickerColor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    pickerColor = widget.colorToShow;
  }

  void _pickedColor(Color color) {
    setState(() => pickerColor = color);
  }

  Widget buildDialog(BuildContext context) {
    return AlertDialog(
      title: Text(translate(TS("input.adjust", <String>[widget.colorName]), context)),
      content: SingleChildScrollView(
        child: ColorPicker(
          paletteType: PaletteType.hueWheel,
          pickerColor: pickerColor,
          onColorChanged: _pickedColor,
          enableAlpha: false,
        ),
        // Use Material color picker:
        //
        // child: MaterialPicker(
        //   pickerColor: pickerColor,
        //   onColorChanged: changeColor,
        //   showLabel: true, // only on portrait mode
        // ),
        //
        // Use Block color picker:
        //
        // child: BlockPicker(
        //   pickerColor: currentColor,
        //   onColorChanged: changeColor,
        // ),
        //
        // child: MultipleChoiceBlockPicker(
        //   pickerColors: currentColors,
        //   onColorsChanged: changeColors,
        // ),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: Text(translate(const TS("input.done"), context)),
          onPressed: () {
            widget.onColorChange(pickerColor);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  void openDialog(BuildContext context) {
    showDialog(context: context, builder: buildDialog);
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => openDialog(context),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => widget.colorToShow,
        ),
      ),
      child: Text(
        translate(TS("input.adjust", <String>[widget.colorName]), context),
        style: TextStyle(color: widget.colorToShow.luminance > 0.5 ? Colors.black : Colors.white),
      ),
    );
  }
}
