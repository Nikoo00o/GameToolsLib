import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/pages/hotkeys/hotkey_group_builder.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_grouped_builders_extension.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigation_page.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder.dart';
import 'package:provider/provider.dart';

/// A [GTNavigationPage] that contains all config options from [MutableConfig.getConfigurableOptions] by using
/// [GTGroupedBuildersExtension] with [HotkeyGroupBuilder] as the type to use the builders for the config options
/// and [GTHotkeyGroupIndex] for the index which is also provided for [Consumer]'s further down the widget tree!
///
/// This builds an internal config group navigation bar to navigate through the [MutableConfigOptionGroup],
/// [ModelConfigOption] and [CustomConfigOption] of [MutableConfig.getConfigurableOptions] in [buildBody]'s
/// [buildGroupLabels]. Then the individual config options on the right part of a page are build with
/// [buildCurrentGroupOptions] by using the [ConfigOptionBuilder] subclasses!
base class GTHotkeysPage extends GTNavigationPage
    with GTGroupedBuildersExtension<HotkeyGroupBuilder, GTHotkeyGroupIndex> {
  /// For the remaining hotkeys with no group
  static const TranslationString otherGroup = TS("page.hotkeys.group.other");

  GTHotkeysPage({
    super.key,
    super.backgroundImage,
    super.backgroundColor,
    super.pagePadding,
  }) {
    builders = <HotkeyGroupBuilder>[];
    final UnmodifiableListView<BaseInputListener<dynamic>> listeners = GameToolsLib.gameManager().getInputListeners();
    Logger.spam("Building GTHotkeysPage options: ", listeners);
    // ignore: prefer_const_constructors
    final HotkeyGroupBuilder otherBuilder = HotkeyGroupBuilder(
      groupLabel: otherGroup,
      inputListener: <BaseInputListener<dynamic>>[],
    );
    for (final BaseInputListener<dynamic> listener in listeners) {
      if (listener.isConfigurable) {
        final TranslationString? groupLabel = listener.configGroupLabel;
        if (groupLabel != null) {
          _addToBuilderGroup(groupLabel, listener);
        } else {
          otherBuilder.inputListener.add(listener);
        }
      } else {
        Logger.spam("Input Listener ", listener, " did not contain a config label so its not configurable");
      }
    }
    if (otherBuilder.inputListener.isNotEmpty) {
      builders.add(otherBuilder);
    }
  }

  void _addToBuilderGroup(TranslationString groupLabel, BaseInputListener<dynamic> listener) {
    for (final HotkeyGroupBuilder builder in builders) {
      if (builder.groupLabel == groupLabel) {
        builder.inputListener.add(listener);
        return;
      }
    }
    builders.add(HotkeyGroupBuilder(groupLabel: groupLabel, inputListener: <BaseInputListener<dynamic>>[listener]));
  }

  @override
  String get pageName => "GTHotkeysPage";

  @override
  TranslationString get navigationLabel => const TS("page.hotkeys.title");

  @override
  IconData get navigationNotSelectedIcon => Icons.keyboard_alt_outlined;

  @override
  IconData get navigationSelectedIcon => Icons.keyboard_alt;

  @override
  GTHotkeyGroupIndex createIndexSubclass(BuildContext context) => GTHotkeyGroupIndex(0);
}

/// The specific subclass used for [GTHotkeysPage] to provide the current hotkey group index
final class GTHotkeyGroupIndex extends GTGroupIndex {
  GTHotkeyGroupIndex(super.value);
}
