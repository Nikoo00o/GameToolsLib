import 'package:flutter/material.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';

/// Wrapper for [Slider] with a list of [entries] of type [T] to display a slider that slides from first to last element
class SimpleSlider<T> extends StatefulWidget {
  /// Zero base index of the first value of [entries] to display before the slider is active
  final int initialIndex;

  /// The available options for the slider (should be static / const, or created outside of the build method!)
  final List<T> entries;

  /// Callback to convert the [entry] to a string to display when the slider is at that position
  final String Function(T entry) labelForEntry;

  /// Callback when the slider was moved which contains the entry at that position
  final ValueChanged<T> onValueChanged;

  const SimpleSlider({
    super.key,
    required this.initialIndex,
    required this.entries,
    required this.labelForEntry,
    required this.onValueChanged,
  });

  @override
  State<SimpleSlider<T>> createState() => _SimpleSliderState<T>();
}

class _SimpleSliderState<T> extends State<SimpleSlider<T>> with GTBaseWidget {
  /// Has to be double because of the [Slider]
  late double index;

  List<T> get entries => widget.entries;

  int get maxValue => entries.length - 1;

  T get currentEntry => entries.elementAt(index.round());

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Slider(
      year2023: false,
      value: index,
      max: maxValue.toDouble(),
      divisions: maxValue,
      label: translate(context, widget.labelForEntry(currentEntry)),
      onChanged: (double value) {
        setState(() => index = value);
        widget.onValueChanged(currentEntry);
      },
    );
  }
}
