import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/enums/input/input_enums.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/pages/hotkeys/gt_hotkey_field.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_grouped_builders_extension.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_card.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_drop_down_menu.dart';

/// Subclasses of this are only for the custom and model config options, or for config option groups to also build
/// the label in the navigation bar with [buildGroupLabel]. [buildContent] still depends on the sub class.
base class HotkeyGroupBuilder with GTBaseWidget implements GTGroupBuilderInterface {
  final String groupLabel;
  final List<BaseInputListener<dynamic>> inputListener;

  const HotkeyGroupBuilder({
    required this.groupLabel,
    required this.inputListener,
  });

  /// Builds a Menu structure in addition to [buildContent]!
  @override
  NavigationRailDestination buildGroupLabel(BuildContext context) {
    return NavigationRailDestination(
      padding: const EdgeInsets.symmetric(vertical: 4),
      icon: const Icon(Icons.keyboard_arrow_right),
      selectedIcon: const Icon(Icons.keyboard_double_arrow_right),
      label: Text(translate(context, groupLabel)),
    );
  }

  Widget defaultContentTile(BaseInputListener<dynamic> listener, Widget trailingWidget) {
    return SimpleCard(
      titleKey: listener.configLabel,
      descriptionKey: listener.configLabelDescription,
      trailingActions: trailingWidget,
    );
  }

  Widget buildKeyInputListener(BuildContext context, KeyInputListener listener) {
    return defaultContentTile(
      listener,
      GTHotkeyField(
        initialValue: listener.currentKey,
        onChanged: (BoardKey? key) => listener.storeKey(key),
      ),
    );
  }

  Widget buildMouseInputListener(BuildContext context, MouseInputListener listener) {
    final List<MouseKey?> options = List<MouseKey?>.of(MouseKey.values);
    return defaultContentTile(
      listener,
      SimpleDropDownMenu<MouseKey?>(
        height: 40,
        maxWidth: 250,
        label: "page.hotkeys.mouse.info",
        values: options..add(null),
        initialValue: listener.currentKey,
        onValueChange: (MouseKey? newKey) => listener.storeKey(newKey),
        translationKeys: (MouseKey? key) => switch (key) {
          MouseKey.LEFT => "page.hotkeys.mouse.left",
          MouseKey.RIGHT => "page.hotkeys.mouse.right",
          MouseKey.MIDDLE => "page.hotkeys.mouse.middle",
          _ => "page.hotkeys.mouse.none",
        },
      ),
    );
  }

  @override
  Widget buildProviderWithContent(BuildContext context) {
    return ListView.builder(
      itemCount: inputListener.length,
      itemBuilder: (BuildContext context, int index) {
        final BaseInputListener<dynamic> listener = inputListener.elementAt(index);
        if (listener is KeyInputListener) {
          return buildKeyInputListener(context, listener);
        } else if (listener is MouseInputListener) {
          return buildMouseInputListener(context, listener);
        }
        throw ConfigException(message: "Error, wrong listener type $listener");
      },
    );
  }

  @override
  String get groupName => groupLabel;
}
