import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/presentation/base/gt_base_page.dart';
import 'package:game_tools_lib/presentation/base/ui_helper.dart';
import 'package:game_tools_lib/presentation/pages/logs/gt_logs_bar.dart';
import 'package:game_tools_lib/presentation/pages/logs/gt_logs_view.dart';
import 'package:provider/single_child_widget.dart';

/// The default page to use to display the logs navigated to from [GTHome]
base class GTLogsPage extends GTBasePage {
  const GTLogsPage({
    super.key,
    super.backgroundImage,
    super.backgroundColor,
    super.pagePadding,
  });

  @override
  List<SingleChildWidget> buildProviders(BuildContext context) => <SingleChildWidget>[
    UIHelper.simpleProvider(createValue: (_) => FixedConfig.fixedConfig.defaultUiLogLevel),
    UIHelper.simpleProvider(createValue: (_) => ""),
  ];

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) =>
      buildAppBarDefaultTitle(context, "page.logs.title", buildBackButton: true, actions: <Widget>[const GTLogsBar()]);

  @override
  Widget buildBody(BuildContext context) {
    return const GTLogsView();
  }

  @override
  String get pageName => "GTLogsPage";
}
