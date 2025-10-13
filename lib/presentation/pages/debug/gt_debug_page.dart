import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/presentation/base/gt_base_page.dart';
import 'package:game_tools_lib/presentation/pages/debug/gt_debug_status.dart';
import 'package:game_tools_lib/presentation/pages/debug/gt_extended_debug_info.dart';

/// Only for testing/debugging to see all material colors
base class GTDebugPage extends GTBasePage {
  const GTDebugPage({
    super.key,
    super.backgroundImage,
    super.backgroundColor,
    super.pagePadding,
  });

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: <Widget>[
        const GTDebugStatus(),
        Padding(
          padding: const EdgeInsetsGeometry.symmetric(horizontal: 120),
          child: MutableConfig.mutableConfig.alwaysMatchGameWindowNamesEqual.builder.buildProviderWithContent(
            context,
            calledFromInnerGroup: false,
          ),
        ),
        Padding(
          padding: const EdgeInsetsGeometry.symmetric(horizontal: 120),
          child: MutableConfig.mutableConfig.debugPrintGameWindowNames.builder.buildProviderWithContent(
            context,
            calledFromInnerGroup: false,
          ),
        ),
        const GtExtendedDebugInfo(),
      ],
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) =>
      buildAppBarDefaultTitle(const TS("page.debug.title"), context, buildBackButton: true);

  @override
  String get pageName => "GTDebugPage";
}
