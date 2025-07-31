import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder.dart';
import 'package:game_tools_lib/presentation/pages/settings/gt_list_editor.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_card.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_drop_down_menu.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_text_field.dart';

/// Provides useful helper methods to build the widgets of a [ConfigOptionBuilder] for the config options with for
/// example [defaultContentTile], [buildBoolOption], etc
base mixin ConfigOptionHelperMixin<T> on ConfigOptionBuilder<T> {
  /// Can be used in [ConfigOptionBuilder.buildContent] to build a list tile with the description and title if they
  /// are not null by using [SimpleCard] with the [configOption] and then adding additional methods on the right with
  /// [trailingWidget]!
  Widget defaultContentTile(Widget trailingWidget) {
    return SimpleCard(
      titleKey: configOption.titleKey,
      descriptionKey: configOption.descriptionKey,
      trailingActions: trailingWidget,
    );
  }

  /// Builds a list tile with a bool option
  Widget buildBoolOption({
    required String title,
    String? description,
    required bool initialData,
    required ValueChanged<bool> onChanged,
  }) {
    return SimpleCard(
      titleKey: title,
      descriptionKey: description,
      trailingActions: Switch(
        value: initialData,
        onChanged: onChanged,
      ),
    );
  }

  /// Builds a list tile with a string option
  Widget buildStringOption({
    required String title,
    String? description,
    required String initialData,
    required ValueChanged<String> onChanged,
  }) {
    return SimpleCard(
      titleKey: title,
      descriptionKey: description,
      trailingActions: SimpleTextField<String>(
        width: 280,
        initialValue: initialData,
        onChanged: onChanged,
      ),
    );
  }

  /// Builds a list tile with an int option
  Widget buildIntOption({
    required String title,
    String? description,
    required int initialData,
    required ValueChanged<int> onChanged,
  }) {
    return SimpleCard(
      titleKey: title,
      descriptionKey: description,
      trailingActions: SimpleTextField<int>(
        width: 140,
        initialValue: initialData.toString(),
        onChanged: (String newValue) => onChanged.call(int.parse(newValue)),
      ),
    );
  }

  /// Builds a list tile with a double option
  Widget buildDoubleOption({
    required String title,
    String? description,
    required double initialData,
    required ValueChanged<double> onChanged,
  }) {
    return SimpleCard(
      titleKey: title,
      descriptionKey: description,
      trailingActions: SimpleTextField<double>(
        width: 140,
        initialValue: initialData.toString(),
        onChanged: (String newValue) => onChanged.call(double.parse(newValue.replaceAll(',', '.'))),
      ),
    );
  }

  /// Builds a list tile with an enum option
  Widget buildEnumOption<ET>({
    required String title,
    String? description,
    required List<ET> availableOptions,
    required ET initialValue,
    required void Function(ET? newValue) onValueChange,
    required String Function(ET value)? convertToTranslationKeys,
  }) {
    return SimpleCard(
      titleKey: title,
      descriptionKey: description,
      trailingActions: SimpleDropDownMenu<ET>(
        height: 40,
        maxWidth: 250,
        values: availableOptions,
        initialValue: initialValue,
        onValueChange: onValueChange,
        translationKeys: convertToTranslationKeys,
      ),
    );
  }

  /// Builds a list tile with a list option which uses [GTListEditor].
  ///
  /// Important: the list of [elements] will be modified internally, but [onChange] will be called after every update!
  ///
  /// [buildElement] is optional to build custom widgets for the left part of the row that is build for each card of
  /// the list [elements]! Otherwise a default "Element $elementNumber: [LT.toString]" [Text] will be build for each
  /// child. For default types [int], or [String] this will be ignored if [buildCreateOrEditDialog] is null.
  ///
  /// Also Important: the [buildCreateOrEditDialog] must only be not null for [LT] not being [int], or [String]
  /// (because otherwise a default one will be used. and then it's used to build the dialog content when creating a
  /// new element of the list, or editing one. The dialog has the title "Edit element $elementNumber", or "Create
  /// element $elementNumber" with the button options "Ok" and "Cancel" at the bottom.
  /// The [oldElement] is either the element to edit if its not null, or otherwise a new element should be created on
  /// created.
  /// And after changes to data, you should call [onElementUpdate] with a cached, or new element (which you created
  /// and will be added to the list automatically after you are done!). Its of the type [GTListOnElementUpdate]
  /// The [elementNumber] is the not zero based index (1 to size for edit, size+1 for create) and is ignored most of
  /// the times.
  Widget buildListOption<LT>({
    required String title,
    String? description,
    bool buildEditButtons = true,
    required List<LT> elements,
    VoidCallback? onChange,
    Widget Function(LT element, int elementNumber)? buildElement,
    Widget Function(
      BuildContext context,
      LT? oldElement,
      int elementNumber,
      GTListOnElementUpdate<LT> onElementUpdate,
    )?
    buildCreateOrEditDialog,
  }) {
    if (buildCreateOrEditDialog == null) {
      if (buildElement != null) {
        Logger.warn(
          "buildListOption's buildElement was not null, but buildCreateOrEditDialog was for type $LT and title $title",
        );
      }
      if (LT == int) {
        return GTListEditorInt(
          titleKey: title,
          descriptionKey: description,
          buildEditButtons: buildEditButtons,
          elements: elements as List<int>,
          onChange: onChange,
        );
      } else {
        throw ConfigException(message: "buildListOption was not given a buildCreateOrEditDialog for type $LT");
      }
    }
    return GTListEditor<LT>(
      titleKey: title,
      descriptionKey: description,
      buildEditButtons: buildEditButtons,
      elements: elements,
      onChange: onChange,
      buildElement: buildElement,
      buildCreateOrEditDialog: buildCreateOrEditDialog!,
    );
  }

  /// Builds a column with the [MutableConfigOption.titleKey] from [configOption] as the title at the top
  /// (optional [MutableConfigOption.descriptionKey] if not null as well) and the [children] as a list view below that.
  Widget buildMultiOptionsWithTitle({
    required BuildContext context,
    required List<Widget> children,
  }) {
    return Column(
      children: <Widget>[
        Text(
          translate(context, configOption.titleKey),
          style: textTitleLarge(context).copyWith(color: colorPrimary(context)),
          textAlign: TextAlign.center,
        ),
        if (configOption.descriptionKey != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 8, 0),
              child: Text(
                translate(context, configOption.descriptionKey!),
                textAlign: TextAlign.left,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textBodyMedium(context).copyWith(color: colorSecondary(context)),
              ),
            ),
          ),
        const SizedBox(height: 25),
        Expanded(child: ListView(children: children)),
      ],
    );
  }
}
