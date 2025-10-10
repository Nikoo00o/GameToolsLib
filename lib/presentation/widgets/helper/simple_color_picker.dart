import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';

/// Builds a button that opens a dialog to pick a color
class SimpleColorPicker extends StatefulWidget {
  /// The color which this should modify (to display the current color)
  final Color colorToShow;

  /// To be translated name of the color that is adjusted here (for custom colors its "color.custom.1", ...
  final TranslationString colorName;

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
      title: Text(TS.combineS(<TS>[const TS("input.adjust"), widget.colorName], context)),
      content: SingleChildScrollView(
        child: ColorPicker(
          paletteType: PaletteType.hueWheel,
          pickerColor: pickerColor,
          onColorChanged: _pickedColor,
          enableAlpha: false,
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: Text(const TS("input.done").tl(context)),
          onPressed: () {
            widget.onColorChange(pickerColor);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  void openDialog(BuildContext context) {
    showDialog<dynamic>(context: context, builder: buildDialog);
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
        TS.combineS(<TS>[const TS("input.adjust"), widget.colorName], context),
        style: TextStyle(color: widget.colorToShow.luminance > 0.5 ? Colors.black : Colors.white),
      ),
    );
  }
}
