import 'package:flutter/material.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';

/// Used to create a drop down menu for [Type] which is mostly used for enums.
/// You should provide the [initialValue] value and the list of [values] further up in the widget tree and then you
/// can receive updates when the value changes with [onValueChange]!
final class SimpleDropDownMenu<Type> extends GTBaseWidget {
  /// The list of available drop down options
  final List<Type> values;

  /// The current selected value (should be managed higher up the widget tree)
  final Type initialValue;

  /// The translation key to display on the menu
  final String label;

  /// Default would be 160
  final double width;

  /// Default would be 40
  final double height;

  /// Flutters default
  static const double defaultWidth = 184;

  /// Flutters default
  static const double defaultHeight = 48;

  /// Will be called when the user changed something with the drop down menu
  final void Function(Type? newValue) onValueChange;

  /// Optional to color the text of the individual entries!
  final Color Function(Type value)? colourTexts;

  const SimpleDropDownMenu({
    super.key,
    required this.label,
    required this.values,
    required this.initialValue,
    required this.onValueChange,
    this.colourTexts,
    this.width = 160,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<Type>(
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: width / 10),
        constraints: BoxConstraints.tight(Size(width, height)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      trailingIcon: Transform.translate(
        offset: Offset(0, (height - defaultHeight) / 2 + 4),
        child: Icon(Icons.arrow_drop_down),
      ),
      initialSelection: initialValue,
      requestFocusOnTap: true,
      label: Text(translate(context, label)),
      onSelected: onValueChange,
      dropdownMenuEntries: List<DropdownMenuEntry<Type>>.generate(
        values.length,
        (int index) {
          final Type value = values.elementAt(index);
          return DropdownMenuEntry<Type>(
            value: value,
            label: value.toString(),
            style: colourTexts != null ? MenuItemButton.styleFrom(foregroundColor: colourTexts!.call(value)) : null,
          );
        },
      ),
    );
  }
}
