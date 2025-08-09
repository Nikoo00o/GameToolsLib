import 'package:flutter/widgets.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/presentation/base/gt_base_page.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigation_page.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder_group.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_builder_types.dart';
import 'package:game_tools_lib/presentation/pages/settings/config_option_helper_mixin.dart';

/// This is used for [ConfigOptionHelperMixin.buildNewPageOption] and just builds a new page with navigate back app
/// bar that calls [ConfigOptionBuilder.buildProviderWithContent] on [configOption] to display the config options.
///
/// It is used for [ConfigOptionBuilderCustom] and [ConfigOptionBuilderModel] when they are used inside of a
/// [ConfigOptionBuilderGroup]!
///
/// Per default this also overrides [buildAppBar] to show the [MutableConfigOption.title] and a back button!
/// And this overrides [buildPaddedBody] to build the content with different padding!
base class ConfigOptionBuilderNewPage<CT> extends GTBasePage {
  /// The config option for which the new page is build
  final MutableConfigOption<CT> configOption;

  const ConfigOptionBuilderNewPage({
    super.key,
    super.backgroundImage,
    super.backgroundColor,
    super.pagePadding,
    required this.configOption,
  });

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) =>
      buildAppBarDefaultTitle(configOption.title, context, buildBackButton: true);

  @override
  Widget buildBody(BuildContext context) {
    return configOption.builder!.buildProviderWithContent(context, calledFromInnerGroup: false);
  }

  @override
  Widget buildPaddedBody(BuildContext context, Color? backgroundColor, DecorationImage? backgroundImage) {
    Color? finalBackgroundColor = backgroundColor;
    if (backgroundImage == null && backgroundColor == null) {
      finalBackgroundColor = colorScaffoldBackground(context);
    }
    return Container(
      margin: GTNavigationPage.innerNavPadding,
      padding: pagePadding,
      decoration: BoxDecoration(
        image: backgroundImage,
        color: finalBackgroundColor,
        borderRadius: const BorderRadius.all(
          Radius.circular(12.0),
        ),
      ),
      child: buildBody(context),
    );
  }

  @override
  Color? getScaffoldBackgroundColor(BuildContext context) => colorSurfaceContainer(context);

  @override
  String get pageName => configOption.title.identifier;
}
