import 'package:flutter/material.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';

/// Wrapper for [Wrap] with [FilterChip] with a list of [entries] of type [T] to display a multi selection of those
/// entries!
class SimpleMultiSelect<T> extends StatefulWidget {
  /// The available options for the slider (should be static / const, or created outside of the build method!)
  final List<T> entries;

  /// Callback to convert the [entry] to a string to display for the fields
  final String Function(T entry) labelForEntry;

  /// Callback to return some inner status bool of the [entry] that stores if it is selected or not
  final bool Function(T entry) isEntrySelected;

  /// Callback when the selection status of an entry changes (contains the new selection status in the callback)
  final void Function(T entry, {required bool isNowSelected}) onSelectionChanged;

  const SimpleMultiSelect({
    super.key,
    required this.entries,
    required this.labelForEntry,
    required this.isEntrySelected,
    required this.onSelectionChanged,
  });

  @override
  State<SimpleMultiSelect<T>> createState() => _SimpleMultiSelectState<T>();
}

class _SimpleMultiSelectState<T> extends State<SimpleMultiSelect<T>> with GTBaseWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: widget.entries.map((T entry) {
        return FilterChip(
          label: Text(translate(context, widget.labelForEntry(entry))),
          selected: widget.isEntrySelected(entry),
          onSelected: (bool selected) {
            setState(() {
              widget.onSelectionChanged(entry, isNowSelected: selected);
            });
          },
        );
      }).toList(),
    );
  }
}
