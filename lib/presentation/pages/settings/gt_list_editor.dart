import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/core/utils/utils.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_text_field.dart';

/// A card with an expansion tile that expands to reveal a list of cards of children of type [T] and options to
/// add/edit/remove the list of [elements]. Mostly used for [ConfigOptionBuilder]
///
/// You can also build custom widgets for the left part of the element cards with [buildElement].
///
/// For an example look at [GTListEditorInt] which has default behaviour for a list of int elements
base class GTListEditor<T> extends StatefulWidget {
  /// The elements to display in this list option which will be modified internally!
  final List<T> elements;

  /// Optional callback that gets called after add/delete/edit of elements!
  final VoidCallback? onChange;

  /// Translation key for the title of this list editor displayed over all elements on the other side of the
  /// add/expand buttons
  final TranslationString title;

  /// Optional description under the [title]
  final TranslationString? description;

  /// If this is false, then the edit button will not be build for each element of [elements].
  /// This should be the case if your [buildElement] function also has some part that can edit the element!
  final bool buildEditButton;

  /// If this is false, then the edit button will not be build for each element of [elements].
  /// This should be the case if you dont want your elements to be deleted!
  final bool buildDeleteButton;

  /// If this is false, then the top add button will not be build. Otherwise per default it will be build when expanded!
  final bool buildAddButton;

  /// This can be used to build custom widgets for the left part of the row that is build for each card of the
  /// [elements]. If this is null, then a default "Element $elementNumber: [T.toString]" [Text] will be build for
  /// each child! The [elementNumber] is the not zero based index of the elements (from 1 to size)
  final Widget Function(BuildContext context, T element, int elementNumber)? buildElement;

  /// This builds the body of the dialog to create a new element, or edit an element. The dialog always has the title
  /// "Edit element $elementNumber", or "Create element $elementNumber" with the button options "Ok" and "Cancel" at
  /// the bottom.
  ///
  /// The [oldElement] is either the element to edit if its not null, or otherwise a new element should be created on
  /// created.
  ///
  /// And after changes to data, you should call [onElementUpdate] with a cached, or new element (which you created
  /// and will be added to the list automatically after you are done!). Its of the type [GTListOnElementUpdate]
  ///
  /// The [elementNumber] is the not zero based index (1 to size for edit, size+1 for create) and is ignored most of
  /// the times.
  final Widget Function(
    BuildContext context,
    T? oldElement,
    int elementNumber,
    GTListOnElementUpdate<T> onElementUpdate,
  )
  buildCreateOrEditDialog;

  /// Optional builder method to build the top bar when expanded (per default this is null and builds nothing when not
  /// expanded and otherwise only the add button to add a new item!). Important: there will always be a sizedbox
  /// with 16 px and then the dropdown icon on the right of your returned list! This can be used to prevent new
  /// elements from being added! To control if the add button should be build, use [buildAddButton]! If expanded is
  /// false this can just return null! The [rebuild] method can be called after state changes in own buttons!
  // ignore: avoid_positional_boolean_parameters
  final List<Widget>? Function(BuildContext context, bool isExpanded, VoidCallback rebuild)? buildTopActions;

  /// Optional callback which if not null will be called instead of opening the dialog when a new element should be
  /// created after pressing the add button. This is useful to use with [buildEditButton] being false, but
  /// [buildDeleteButton] being true and the [buildElement] building all edit functionality with widgets and the add
  /// button should only add a new empty element. The elementNumber is the not zero based index for the new element
  /// (so current length + 2)
  final Future<T> Function(int elementNumber)? customCreateNewElement;

  /// Can optionally be set to set a fixed max height instead of expanding to the max available height like the
  /// default null would. For example 500
  final double? maxHeight;

  const GTListEditor({
    super.key,
    required this.elements,
    this.onChange,
    required this.title,
    this.description,
    this.buildEditButton = true,
    this.buildDeleteButton = true,
    this.buildAddButton = true,
    this.buildElement,
    required this.buildCreateOrEditDialog,
    this.buildTopActions,
    this.customCreateNewElement,
    this.maxHeight,
  });

  @override
  State<GTListEditor<T>> createState() => _GTListEditorState<T>();
}

base class _GTListEditorState<T> extends State<GTListEditor<T>> with GTBaseWidget {
  bool _expanded = false;

  Future<T?> dialog(BuildContext outerContext, T? oldElement, int elementNumber) async {
    T? cachedElement;
    void onElementUpdate(T updatedElement) {
      cachedElement = updatedElement;
    }

    final bool? success = await showDialog<bool>(
      context: outerContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final String titleKey = oldElement != null ? "input.edit.element" : "input.create.element";
        return AlertDialog(
          title: Text(TS(titleKey, <String>[elementNumber.toString()]).tl(dialogContext)),
          content: widget.buildCreateOrEditDialog(dialogContext, oldElement, elementNumber, onElementUpdate),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                const TS("input.cancel").tl(dialogContext),
                style: TextStyle(color: colorError(dialogContext)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                const TS("input.ok").tl(dialogContext),
                style: TextStyle(color: colorSuccess(dialogContext)),
              ),
            ),
          ],
        );
      },
    );
    if (success != true) {
      cachedElement = null;
    }
    return cachedElement;
  }

  Future<void> onCreate(int index) async {
    late final T? newElement;
    if (widget.customCreateNewElement != null) {
      newElement = await widget.customCreateNewElement!.call(index + 1);
    } else {
      newElement = await dialog(context, null, index + 1);
    }
    setState(() {
      if (newElement != null) {
        widget.elements.add(newElement);
        widget.onChange?.call();
      }
    });
  }

  Future<void> onEdit(T oldElement, int index) async {
    final T? newElement = await dialog(context, oldElement, index + 1);
    setState(() {
      if (newElement != null) {
        widget.elements[index] = newElement;
        widget.onChange?.call();
      }
    });
  }

  void onDelete(T element, int index) {
    setState(() {
      widget.elements.removeAt(index);
      widget.onChange?.call();
    });
  }

  Widget buildElement(BuildContext context, T element, int index) {
    final int number = index + 1;
    return widget.buildElement?.call(context, element, number) ??
        Text(TS("input.show.element", <String>[number.toString(), element.toString()]).tl(context));
  }

  Widget _editB(BuildContext context, T element, int i) => IconButton(
    onPressed: () => onEdit(element, i),
    icon: const Icon(Icons.edit),
    tooltip: const TS("input.edit").tl(context),
    color: colorSecondary(context),
  );

  Widget _delB(BuildContext context, T element, int i) => IconButton(
    onPressed: () => onDelete(element, i),
    icon: const Icon(Icons.delete),
    tooltip: const TS("input.delete").tl(context),
    color: colorError(context),
  );

  Widget buildEditButtons(BuildContext context, T element, int i) {
    if (widget.buildEditButton && widget.buildEditButton) {
      return Row(
        children: <Widget>[
          _editB(context, element, i),
          const SizedBox(width: 6),
          _delB(context, element, i),
        ],
      );
    } else if (widget.buildEditButton) {
      return _editB(context, element, i);
    } else if (widget.buildDeleteButton) {
      return _delB(context, element, i);
    } else {
      return const SizedBox();
    }
  }

  List<Widget> buildChildren(BuildContext context) {
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < widget.elements.length; i++) {
      final T element = widget.elements.elementAt(i);
      children.add(
        Card.filled(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(child: buildElement(context, element, i)),
                buildEditButtons(context, element, i),
              ],
            ),
          ),
        ),
      );
    }

    late final Widget child;
    if (widget.maxHeight != null) {
      child = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight!),
        child: SingleChildScrollView(
          child: Column(
            children: children,
          ),
        ),
      );
    } else {
      child = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight),
            child: SingleChildScrollView(
              child: Column(
                children: children,
              ),
            ),
          );
        },
      );
    }
    return <Widget>[child];
  }

  void _updateCallback() => setState(() {});

  Widget buildTopBar(BuildContext context) {
    final List<Widget>? children = widget.buildTopActions?.call(context, _expanded, _updateCallback);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (children != null) ...children,
        if (widget.buildAddButton && _expanded)
          IconButton(
            onPressed: () => onCreate(widget.elements.length),
            icon: const Icon(Icons.add_circle_sharp),
            tooltip: const TS("input.add").tl(context),
            color: colorSuccess(context),
          ),
        const SizedBox(width: 16),
        Icon(_expanded ? Icons.arrow_drop_down_circle : Icons.arrow_drop_down),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey<String>(widget.title.identifier),
      child: ExpansionTile(
        collapsedBackgroundColor: widget.elements.isEmpty
            ? null
            : colorSurfaceContainer(context).blend(colorPrimaryContainer(context), 0.15),
        collapsedShape: const ContinuousRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        childrenPadding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
        title: Text(widget.title.tl(context), style: textTitleMedium(context)),
        subtitle: widget.description != null
            ? Text(
                widget.description!.tl(context),
                style: textBodySmall(context).copyWith(color: colorOnSurfaceVariant(context)),
              )
            : null,
        trailing: buildTopBar(context),
        children: buildChildren(context),
        onExpansionChanged: (bool expanded) {
          setState(() {
            _expanded = expanded;
          });
        },
      ),
    );
  }
}

/// Helper typedef for [GTListEditor]
typedef GTListOnElementUpdate<T> = void Function(T updatedElement);

/// Example for [GTListEditor] with a list of [int]
final class GTListEditorInt extends GTListEditor<int> {
  GTListEditorInt({
    super.key,
    required super.elements,
    super.onChange,
    required super.title,
    super.description,
    super.buildEditButton,
    super.buildDeleteButton,
    super.maxHeight,
  }) : super(
         buildCreateOrEditDialog:
             (BuildContext context, int? oldElement, int elementNumber, GTListOnElementUpdate<int> update) {
               return SimpleTextField<int>(
                 autofocus: true,
                 width: 140,
                 initialValue: oldElement?.toString() ?? "",
                 onChanged: (String newValue) => update.call(int.parse(newValue)),
               );
             },
       );
}

/// Example for [GTListEditor] with a list of [String]
final class GTListEditorString extends GTListEditor<String> {
  GTListEditorString({
    super.key,
    required super.elements,
    super.onChange,
    required super.title,
    super.description,
    super.buildEditButton,
    super.buildDeleteButton,
    super.maxHeight,
  }) : super(
         buildCreateOrEditDialog:
             (BuildContext context, String? oldElement, int elementNumber, GTListOnElementUpdate<String> update) {
               return SimpleTextField<String>(
                 autofocus: true,
                 width: 140,
                 initialValue: oldElement?.toString() ?? "",
                 onChanged: (String newValue) => update.call(newValue),
               );
             },
       );
}
