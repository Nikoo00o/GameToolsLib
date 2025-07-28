import 'package:flutter/material.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_app_theme.dart';
import 'package:game_tools_lib/presentation/base/gt_base_page.dart';

/// Only for testing/debugging to see all material colors
base class GtTestMaterialColorsPage extends GTBasePage {
  const GtTestMaterialColorsPage({
    super.key,
    super.backgroundImage,
    super.backgroundColor,
    super.pagePadding,
  });

  @override
  Widget buildBody(BuildContext context) {
    final GTAppTheme theme = GameToolsConfig.baseConfig.appColors;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Theme(
          data: theme.getTheme(darkTheme: true),
          child: Builder(
            builder: (BuildContext context) => _buildButtons(context, "dark"),
          ),
        ),
        Theme(
          data: theme.getTheme(darkTheme: false),
          child: Builder(
            builder: (BuildContext context) => _buildButtons(context, "light"),
          ),
        ),
      ],
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) =>
      buildAppBarDefaultTitle(context, "Material Color Test", buildBackButton: true);

  Widget _buildButtons(BuildContext context, String theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
      color: colorScaffoldBackground(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FilledButton(
                onPressed: () {},
                child: Text("primary $theme"),
              ),
              FilledButton(
                onPressed: () {},
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(colorPrimaryContainer(context)),
                  foregroundColor: WidgetStateProperty.all(colorInverseSurface(context)),
                ),
                child: const Text("primary container"),
              ),
              FilledButton(
                onPressed: () {},
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(colorInversePrimary(context)),
                  foregroundColor: WidgetStateProperty.all(colorInverseSurface(context)),
                ),
                child: const Text("inverse"),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FilledButton(
                onPressed: () {},
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(colorSecondary(context)),
                  foregroundColor: WidgetStateProperty.all(colorOnSecondary(context)),
                ),
                child: Text("secondary $theme"),
              ),
              FilledButton(
                onPressed: () {},
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(colorSecondaryContainer(context)),
                  foregroundColor: WidgetStateProperty.all(colorOnSecondaryContainer(context)),
                ),
                child: const Text("secondary container"),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FilledButton(
                onPressed: () {},
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(colorTertiary(context)),
                  foregroundColor: WidgetStateProperty.all(colorOnTertiary(context)),
                ),
                child: Text("tertiary $theme"),
              ),
              FilledButton(
                onPressed: () {},
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(colorTertiaryContainer(context)),
                  foregroundColor: WidgetStateProperty.all(colorOnTertiaryContainer(context)),
                ),
                child: const Text("tertiary container"),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FilledButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(colorError(context)),
                      foregroundColor: WidgetStateProperty.all(colorOnError(context)),
                    ),
                    child: Text("error $theme"),
                  ),
                  FilledButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(colorErrorContainer(context)),
                      foregroundColor: WidgetStateProperty.all(colorOnErrorContainer(context)),
                    ),
                    child: const Text("error container"),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FilledButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(colorSurface(context)),
                      foregroundColor: WidgetStateProperty.all(colorOnSurface(context)),
                    ),
                    child: Text("surface $theme"),
                  ),
                  FilledButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(colorSurfaceContainerHighest(context)),
                      foregroundColor: WidgetStateProperty.all(colorOnSurfaceVariant(context)),
                    ),
                    child: const Text("surface variant"),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FilledButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(colorOutline(context)),
                      foregroundColor: WidgetStateProperty.all(colorOnInverseSurface(context)),
                    ),
                    child: Text("outline $theme"),
                  ),
                  FilledButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(colorOutlineVariant(context)),
                      foregroundColor: WidgetStateProperty.all(colorOnInverseSurface(context)),
                    ),
                    child: const Text("outline variant "),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  String get pageName => "GtTestMaterialColorsPage";
}
