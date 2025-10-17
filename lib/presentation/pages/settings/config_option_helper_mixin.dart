import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder_new_page.dart';
import 'package:game_tools_lib/presentation/pages/settings/gt_list_editor.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_card.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_drop_down_menu.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_multi_select.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_slider.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_text_field.dart';

/// Provides useful helper methods to build the widgets of a [ConfigOptionBuilder] for the config options with for
/// example [defaultContentTile], [buildBoolOption], etc
base mixin ConfigOptionHelperMixin<T> on ConfigOptionBuilder<T> {
  /// Can be used in [ConfigOptionBuilder.buildContent] to build a list tile with the description and title if they
  /// are not null by using [SimpleCard] with the [configOption] and then adding additional actions on the right with
  /// [trailingWidget]!
  Widget defaultContentTile(Widget trailingWidget) {
    return SimpleCard(
      title: configOption.title,
      description: configOption.description,
      trailingActions: trailingWidget,
    );
  }

  /// Builds a list tile with a switch to the right. [null] in [initialData] will leave the switch toggled off initially
  Widget buildBoolOption({
    required TranslationString title,
    TranslationString? description,
    required bool? initialData,
    required ValueChanged<bool> onChanged,
  }) {
    return SimpleCard(
      title: title,
      description: description,
      trailingActions: Switch(
        value: initialData ?? false,
        onChanged: onChanged,
      ),
    );
  }

  /// Builds a list tile with a text field for text. [null] in [initialData] will leave the text field empty!
  Widget buildStringOption({
    required TranslationString title,
    TranslationString? description,
    required String? initialData,
    required ValueChanged<String> onChanged,
  }) {
    return SimpleCard(
      title: title,
      description: description,
      trailingActions: SimpleTextField<String>(
        width: 280,
        initialValue: initialData ?? "",
        onChanged: onChanged,
      ),
    );
  }

  /// Builds a list tile with a text field for numbers. [null] in [initialData], or [onChanged] means an empty text
  /// field!
  Widget buildIntOption({
    required TranslationString title,
    TranslationString? description,
    required int? initialData,
    required ValueChanged<int?> onChanged,
  }) {
    return SimpleCard(
      title: title,
      description: description,
      trailingActions: SimpleTextField<int>(
        width: 140,
        initialValue: initialData?.toString() ?? "",
        onChanged: (String newValue) => onChanged.call(newValue.isEmpty ? null : int.parse(newValue)),
      ),
    );
  }

  /// Builds a list tile with a text field for doubles. [null] in [initialData], or [onChanged] means an empty text
  /// field!
  Widget buildDoubleOption({
    required TranslationString title,
    TranslationString? description,
    required double? initialData,
    required ValueChanged<double?> onChanged,
  }) {
    return SimpleCard(
      title: title,
      description: description,
      trailingActions: SimpleTextField<double>(
        width: 140,
        initialValue: initialData?.toString() ?? "",
        onChanged: (String newValue) =>
            onChanged.call(newValue.isEmpty ? null : double.parse(newValue.replaceAll(',', '.'))),
      ),
    );
  }

  /// Builds a list tile with a drop down menu (which looks like a text field). Alternative would be [buildEnumSliderOption].
  ///
  /// [availableOptions] should be static, or const, or created/stored outside of the build method!
  Widget buildEnumOption<ET>({
    required TranslationString title,
    TranslationString? description,
    required List<ET> availableOptions,
    required ET initialValue,
    required void Function(ET? newValue) onValueChange,
    required TranslationString Function(ET value)? convertToTranslationKeys,
  }) {
    return SimpleCard(
      title: title,
      description: description,
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

  /// Builds a list tile with a slider as an alternative to [buildEnumOption], but here the type [ET] must be a non
  /// nullable enum!
  ///
  /// [availableOptions] should be static, or const, or created/stored outside of the build method!
  Widget buildEnumSliderOption<ET extends Enum>({
    required TranslationString title,
    TranslationString? description,
    required List<ET> availableOptions,
    required ET initialValue,
    required void Function(ET newValue) onValueChange,
    required TranslationString Function(ET value)? convertToTranslationKeys,
  }) {
    return SimpleCard(
      title: title,
      description: description,
      trailingActions: SizedBox(
        width: 450,
        child: SimpleSlider<ET>(
          initialIndex: initialValue.index,
          entries: availableOptions,
          labelForEntry: (ET option) => convertToTranslationKeys?.call(option) ?? TS.raw(option.name),
          onValueChanged: onValueChange,
        ),
      ),
    );
  }

  /// Builds a list tile with a wrap of selectable [entries] on the right side. The label to display for the entries
  /// will be translated from [convertToTranslationKeys].
  ///
  /// And the individual objects of type [LT] should have some internal bool to store if they are selected or not
  /// which should be returned in the [isEntrySelected] callback. The [onSelectionChanged] callback will then be
  /// called if the selection changes for one of the entries!
  ///
  /// [entries] should be static, or const, or created/stored outside of the build method!
  Widget buildMultiSelection<LT>({
    required TranslationString title,
    TranslationString? description,
    required List<LT> entries,
    required TranslationString Function(LT entry) convertToTranslationKeys,
    required bool Function(LT entry) isEntrySelected,
    required void Function(LT entry, {required bool isNowSelected}) onSelectionChanged,
  }) {
    return SimpleMultiSelect<LT>(
      title: title,
      description: description,
      entries: entries,
      labelForEntry: convertToTranslationKeys,
      isEntrySelected: isEntrySelected,
      onSelectionChanged: onSelectionChanged,
    );
  }

  /// Builds a list tile with only [title] and [description] of the [option] of type [CT] and a link to a new page
  /// which will open [ConfigOptionBuilderNewPage].
  ///
  /// Of course this could also be overridden in sub classes to return different sub classes of
  /// [ConfigOptionBuilderNewPage] instead
  Widget buildNewPageOption<CT>(MutableConfigOption<CT> option, BuildContext context) {
    return SimpleCard(
      title: option.title,
      description: option.description,
      trailingActions: const Icon(Icons.open_in_new),
      onTap: () {
        Logger.spam("Opening config option ", option, " on new page");
        Navigator.push<dynamic>(
          context,
          MaterialPageRoute<dynamic>(
            builder: (BuildContext context) {
              return ConfigOptionBuilderNewPage<CT>(configOption: option);
            },
          ),
        );
      },
    );
  }

  /// Builds a list tile which is expandable and contains list options below with [GTListEditor].
  ///
  /// Important: the list of [elements] will be modified internally, but [onChange] will be called after every update!
  /// And it should be static, or const, or created/stored outside of the build method!
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
    required TranslationString title,
    TranslationString? description,
    bool buildEditButtons = true,
    required List<LT> elements,
    VoidCallback? onChange,
    Widget Function(BuildContext context, LT element, int elementNumber)? buildElement,
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
          title: title,
          description: description,
          buildEditButtons: buildEditButtons,
          elements: elements as List<int>,
          onChange: onChange,
        );
      } else {
        throw ConfigException(message: "buildListOption was not given a buildCreateOrEditDialog for type $LT");
      }
    }
    return GTListEditor<LT>(
      title: title,
      description: description,
      buildEditButtons: buildEditButtons,
      elements: elements,
      onChange: onChange,
      buildElement: buildElement,
      buildCreateOrEditDialog: buildCreateOrEditDialog,
    );
  }

  /// Builds a column with the [MutableConfigOption.title] from [configOption] as the title at the top
  /// (optional [MutableConfigOption.description] if not null as well) and the [children] as a list view below that.
  /// So it is used to group up together other options from above!
  Widget buildMultiOptionsWithTitle({
    required BuildContext context,
    required List<Widget> children,
  }) {
    return Column(
      children: <Widget>[
        Text(
          configOption.title.tl(context),
          style: textTitleLarge(context).copyWith(color: colorPrimary(context)),
          textAlign: TextAlign.center,
        ),
        if (configOption.description != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 8, 0),
              child: Text(
                configOption.description!.tl(context),
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
