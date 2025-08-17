import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';

/// Used to create a drop down menu for the type [T] which is mostly used for enums.
/// You should provide the [initialValue] value and the list of [values] further up in the widget tree and then you
/// can receive updates when the value changes with [onValueChange]!
final class SimpleDropDownMenu<T> extends StatelessWidget with GTBaseWidget {
  /// The list of available drop down options
  final List<T> values;

  /// The current selected value (should be managed higher up the widget tree)
  final T initialValue;

  /// The translation key to display on the menu
  final TranslationString? label;

  /// Default would be 160 (but the result may also be smaller)
  final double maxWidth;

  /// Default would be 40
  final double height;

  /// Pads the content from the left and right (default is 16)
  final double horizontalPadding;

  /// Flutters default
  static const double defaultWidth = 184;

  /// Flutters default
  static const double defaultHeight = 48;

  /// Will be called when the user changed something with the drop down menu
  final void Function(T? newValue) onValueChange;

  /// Optional to color the text of the individual entries!
  final Color Function(T value)? colourTexts;

  /// Optional to return a matching translation keys for the enum type [value] to display them instead of just
  /// calling toString on them!
  final TranslationString Function(T value)? translationKeys;

  const SimpleDropDownMenu({
    super.key,
    this.label,
    required this.values,
    required this.initialValue,
    required this.onValueChange,
    this.colourTexts,
    this.translationKeys,
    this.maxWidth = 160,
    this.height = 40,
    this.horizontalPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<T>(
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        constraints: BoxConstraints.tight(Size(maxWidth, height)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      trailingIcon: Transform.translate(
        offset: Offset(0, (height - defaultHeight) / 2 + 4),
        child: const Icon(Icons.arrow_drop_down),
      ),
      initialSelection: initialValue,
      requestFocusOnTap: true,
      label: label == null ? null : Text(translate(label!, context)),
      onSelected: onValueChange,
      dropdownMenuEntries: List<DropdownMenuEntry<T>>.generate(
        values.length,
        (int index) {
          final T value = values.elementAt(index);
          return DropdownMenuEntry<T>(
            value: value,
            label: translationKeys != null ? translate(translationKeys!.call(value), context) : value.toString(),
            style: colourTexts != null ? MenuItemButton.styleFrom(foregroundColor: colourTexts!.call(value)) : null,
          );
        },
      ),
    );
  }
}
