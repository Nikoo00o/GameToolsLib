import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/enums/log_level.dart';
import 'package:game_tools_lib/core/logger/custom_logger.dart';
import 'package:game_tools_lib/core/logger/log_message.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/base/ui_helper.dart';
import 'package:game_tools_lib/presentation/pages/logs/gt_logs_page.dart';
import 'package:game_tools_lib/presentation/pages/logs/gt_logs_view.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_drop_down_menu.dart';
import 'package:game_tools_lib/presentation/widgets/helper/simple_search_container.dart';

/// The search + select bar for logs in the [GTLogsPage]
final class GTLogsBar extends StatelessWidget with GTBaseWidget {
  const GTLogsBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: SimpleSearchContainer(hintTextKey: "page.logs.search"),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: _buildFilterDropDown(context),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: IconButton(
            tooltip: translate(context, "page.logs.copy.to.clipboard"),
            onPressed: () => _onCopyToClipboard(context),
            icon: const Icon(Icons.copy),
          ),
        ),
      ],
    );
  }

  Future<void> _onCopyToClipboard(BuildContext context) async {
    final CustomLogger? logger = Logger.instance as CustomLogger?;
    if (logger != null) {
      final String searchText = UIHelper.modifySimpleValue<String>(context).value;
      final LogLevel logLevel = UIHelper.modifySimpleValue<LogLevel>(context).value;
      final List<LogMessage> messages = GTLogsView.filterLogMessages(logger.changeValue, logLevel, searchText);
      if (messages.isNotEmpty) {
        final StringBuffer data = StringBuffer();
        for (final LogMessage message in messages) {
          data.write(message.toString());
          data.write(message.buildDelimiter(chars: 100, withNewLines: true));
        }
        await InputManager.setClipboard(data.toString());
        if (context.mounted) {
          showToast(context, "page.logs.copy.to.clipboard.done");
        }
      }
    }
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
