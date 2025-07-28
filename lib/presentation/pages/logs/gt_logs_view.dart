import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/enums/log_level.dart';
import 'package:game_tools_lib/core/logger/custom_logger.dart';
import 'package:game_tools_lib/core/logger/log_message.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/base/ui_helper.dart';
import 'package:game_tools_lib/presentation/pages/logs/gt_logs_page.dart';
import 'package:game_tools_lib/presentation/widgets/helper/changes/simple_change_listener.dart';

/// Used in [GTLogsPage] to display the complete logs view!
final class GTLogsView extends StatelessWidget with GTBaseWidget {
  const GTLogsView({super.key});

  @override
  Widget build(BuildContext context) {
    final CustomLogger? logger = Logger.instance as CustomLogger?;
    if (logger == null) {
      return const SizedBox();
    }
    return SimpleChangeListener<List<LogMessage>>(builder: listCallback, streamToListenTo: logger);
  }

  Widget listCallback(BuildContext context, List<LogMessage> logMessages, Widget? outerChild) {
    return UIHelper.simpleConsumer(
      builder: (BuildContext context, LogLevel maxLogLevel, Widget? innerChild) {
        return UIHelper.simpleConsumer(
          builder: (BuildContext context, String searchString, Widget? innerChild) {
            return buildInnerList(context, logMessages, maxLogLevel, searchString);
          },
        );
      },
    );
  }

  /// Convert logs from data layer to logs that can be displayed in the ui
  static List<LogMessage> filterLogMessages(List<LogMessage> logMessages, LogLevel maxLogLevel, String searchString) {
    final List<LogMessage> searchedMessages = List<LogMessage>.of(logMessages);
    final String searchLower = searchString.toLowerCase();
    searchedMessages.removeWhere((LogMessage msg) {
      final String? lower = msg.message?.toLowerCase();
      if (msg.canLog(maxLogLevel) == false) {
        return true;
      }
      return lower == null || (searchLower.isNotEmpty && lower.contains(searchLower) == false);
    });
    return searchedMessages;
  }

  Widget buildInnerList(BuildContext context, List<LogMessage> logMessages, LogLevel maxLogLevel, String searchString) {
    final List<LogMessage> searchedMessages = filterLogMessages(logMessages, maxLogLevel, searchString);
    return ListView.builder(
      itemCount: searchedMessages.length,
      itemBuilder: (BuildContext context, int index) {
        final LogMessage logMessage = searchedMessages.elementAt(searchedMessages.length - index - 1);
        return GTLogMessageView(logMessage: logMessage);
      },
    );
  }
}

/// Builds a card displaying the [logMessage]
final class GTLogMessageView extends StatelessWidget with GTBaseWidget {
  final LogMessage logMessage;

  const GTLogMessageView({super.key, required this.logMessage});

  static Color _getMaterialColor(BuildContext context, LogLevel level) =>
      LogLevel.getLogColor(level)!.getUIColor(context);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          child: Text(
            logMessage.toString(),
            style: textBodyMedium(context).copyWith(color: _getMaterialColor(context, logMessage.level)),
          ),
        ),
      ),
    );
  }
}
