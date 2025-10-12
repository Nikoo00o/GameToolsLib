import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/domain/game/update_checker.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/pages/home/gt_home_page.dart';
import 'package:url_launcher/url_launcher.dart';

/// Uses [UpdateChecker] to display a widget mostly used in [GTHomePage] to check for updates every
/// [updateEveryMinutes].
final class GTVersionCheck extends StatefulWidget {
  /// Per default 15
  static const int updateEveryMinutes = 15;

  const GTVersionCheck({super.key});

  @override
  State<GTVersionCheck> createState() => _GTVersionCheckState();
}

final class _GTVersionCheckState extends State<GTVersionCheck> with GTBaseWidget {
  Timer? timer;
  String? myVersion;
  String? newVersion;
  String? changeLog;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(minutes: GTVersionCheck.updateEveryMinutes), updateCheck);
    unawaited(updateCheck(timer!));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  /// Called every [GTVersionCheck.updateEveryMinutes] from internal timer
  Future<void> updateCheck(Timer timer) async {
    try {
      myVersion ??= await _checker.getMyVersion();
      newVersion = await _checker.getNewestVersion();
      changeLog = await _checker.getChangelog();
      Logger.debug("Checked Versions. Current installed: $myVersion, Newest available: $newVersion");
    } catch (e, s) {
      newVersion = null;
      Logger.error("Error checking version", e, s);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (myVersion == null) {
      return const SizedBox();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(TranslationString("page.update.current", <String>[myVersion!]).tl(context)),
        const SizedBox(width: 25),
        buildUpdateIndicator(context),
      ],
    );
  }

  Widget buildUpdateIndicator(BuildContext context) {
    if (newVersion == null || newVersion!.isEmpty || myVersion!.isEmpty) {
      return Text(
        const TranslationString("page.update.error").tl(context),
        style: TextStyle(color: colorError(context)),
      );
    } else if (newVersion == myVersion) {
      return Text(
        const TranslationString("page.update.none").tl(context),
        style: TextStyle(color: colorSuccess(context)),
      );
    } else {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: colorErrorContainer(context),
          foregroundColor: colorOnErrorContainer(context),
        ),
        onPressed: () => showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: buildDialog,
        ),
        child: Text(const TranslationString("page.update.newer").tl(context)),
      );
    }
  }

  Widget buildDialog(BuildContext context) {
    return AlertDialog(
      title: Text(TranslationString("page.update.dialog.title", <String>[newVersion!]).tl(context)),
      content: SingleChildScrollView(scrollDirection: Axis.vertical, child: Text(changeLog ?? "")),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            unawaited(launchUrl(Uri.parse(_checker.baseGitProjectPath)));
          },
          child: Text(
            TranslationString("page.update.dialog.open", <String>[_checker.baseGitProjectPath]).tl(context),
          ),
        ),
      ],
    );
  }

  UpdateChecker get _checker => UpdateChecker.updateChecker();
}
