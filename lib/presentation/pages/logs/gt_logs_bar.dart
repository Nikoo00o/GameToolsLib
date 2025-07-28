import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/enums/log_level.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/base/ui_helper.dart';
import 'package:game_tools_lib/presentation/pages/logs/gt_logs_page.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_drop_down_menu.dart';

/// The search + select bar for logs in the [GTLogsPage]
final class GTLogsBar extends GTBaseWidget {
  const GTLogsBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: _buildSearchContainer(context),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: _buildFilterDropDown(context),
        ),
      ],
    );
  }

  Widget _buildSearchContainer(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 40,
      child: TextField(
        onChanged: (String newSearchText) => UIHelper.modifySimpleValue<String>(context).value = newSearchText,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: translate(context, "page.logs.search"),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
          filled: true,
        ),
      ),
    );
  }

  Widget _buildFilterDropDown(BuildContext context) {
    return SimpleDropDownMenu<LogLevel>(
      label: "page.logs.level",
      values: LogLevel.values,
      initialValue: FixedConfig.fixedConfig.defaultUiLogLevel,
      onValueChange: (LogLevel? newLogLevel) {
        if (newLogLevel != null) {
          UIHelper.modifySimpleValue<LogLevel>(context).value = newLogLevel;
        }
      },
      colourTexts: (LogLevel level) => _getMaterialColor(context, level),
    );
  }

  static Color _getMaterialColor(BuildContext context, LogLevel level) =>
      LogLevel.getLogColor(level)!.getUIColor(context);
}
