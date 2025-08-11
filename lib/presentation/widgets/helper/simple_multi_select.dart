import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';

/// Wrapper for [Wrap] with [FilterChip] with a list of [entries] of type [T] to display a multi selection of those
/// entries! It is displayed under an expandable expansion tile of a card with the [title]!
class SimpleMultiSelect<T> extends StatefulWidget {
  /// The title to be translated of this card displayed on the left
  final TranslationString title;

  /// Optional under the [title]
  final TranslationString? description;

  /// The available options for the slider (should be static / const, or created outside of the build method!)
  final List<T> entries;

  /// Callback to convert the [entry] to a string to display for the fields
  final TranslationString Function(T entry) labelForEntry;

  /// Callback to return some inner status bool of the [entry] that stores if it is selected or not
  final bool Function(T entry) isEntrySelected;

  /// Callback when the selection status of an entry changes (contains the new selection status in the callback)
  final void Function(T entry, {required bool isNowSelected}) onSelectionChanged;

  const SimpleMultiSelect({
    super.key,
    required this.title,
    this.description,
    required this.entries,
    required this.labelForEntry,
    required this.isEntrySelected,
    required this.onSelectionChanged,
  });

  @override
  State<SimpleMultiSelect<T>> createState() => _SimpleMultiSelectState<T>();
}

class _SimpleMultiSelectState<T> extends State<SimpleMultiSelect<T>> with GTBaseWidget {
  bool _expanded = false;

  Widget buildExpandedContent(BuildContext context) {
    return Wrap(
      spacing: 5.0,
      runSpacing: 5.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: widget.entries.map((T entry) {
        return FilterChip(
          label: Text(translate(widget.labelForEntry(entry), context)),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey<String>(widget.title.identifier),
      child: ExpansionTile(
        collapsedShape: const ContinuousRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        childrenPadding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
        title: Text(translate(widget.title, context), style: textTitleMedium(context)),
        subtitle: widget.description != null
            ? Text(
                translate(widget.description!, context),
                style: textBodySmall(context).copyWith(color: colorOnSurfaceVariant(context)),
              )
            : null,
        trailing: Icon(_expanded ? Icons.arrow_drop_down_circle : Icons.arrow_drop_down),
        children: <Widget>[buildExpandedContent(context)],
        onExpansionChanged: (bool expanded) {
          setState(() {
            _expanded = expanded;
          });
        },
      ),
    );
  }
}
