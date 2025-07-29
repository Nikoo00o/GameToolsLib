import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/enums/gt_contrast.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_base_page.dart';
import 'package:game_tools_lib/presentation/pages/debug/gt_debug_status.dart';

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
        const Spacer(),
        Row(
          children: <Widget>[
            const Spacer(),
            Text("Material Button Colors: ", style: textTitleLarge(context).copyWith(color: colorPrimary(context))),
            const Spacer(),
            _materialThemedContainer(true),
            const Spacer(),
            _materialThemedContainer(false),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) =>
      buildAppBarDefaultTitle(context, "page.debug.title", buildBackButton: true);

  Widget _materialThemedContainer(bool isDark) {
    return Theme(
      data: GameToolsConfig.baseConfig.appColors.getTheme(darkTheme: isDark, contrast: GTContrast.DEFAULT),
      child: Builder(
        builder: (BuildContext context) => _materialButtons(context, isDark ? "dark" : "light"),
      ),
    );
  }

  Widget _materialButtons(BuildContext context, String theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
      color: colorScaffoldBackground(context),
      child: Column(
        children: <Widget>[
          Row(
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
            ],
          ),
          Row(
            children: <Widget>[
              FilledButton(
                onPressed: () {},
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(colorInversePrimary(context)),
                  foregroundColor: WidgetStateProperty.all(colorInverseSurface(context)),
                ),
                child: const Text("prim inverse"),
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text("elevated"),
              ),
              OutlinedButton(
                onPressed: () {},
                child: const Text("outlined"),
              ),
            ],
          ),
          Row(
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
                child: const Text("secondary container (tonal)"),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              FilledButton(
                onPressed: () {},
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(colorTertiary(context)),
                  foregroundColor: WidgetStateProperty.all(colorOnTertiary(context)),
                ),
                child: const Text("tertiary (filled like others)"),
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
            children: <Widget>[
              Row(
                children: <Widget>[
                  FilledButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(colorError(context)),
                      foregroundColor: WidgetStateProperty.all(colorOnError(context)),
                    ),
                    child: const Text("error"),
                  ),
                  FilledButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(colorErrorContainer(context)),
                      foregroundColor: WidgetStateProperty.all(colorOnErrorContainer(context)),
                    ),
                    child: const Text("error cont"),
                  ),
                  const FilledButton(
                    onPressed: null,
                    child: Text("disabled primary"),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Row(
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
                  TextButton(
                    onPressed: () {},
                    child: const Text("text but"),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Row(
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
  String get pageName => "GTDebugPage";
}
