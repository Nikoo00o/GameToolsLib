import 'package:flutter/material.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:provider/provider.dart';

// todo: doc comment
/// Provides the widgets below with changes if main window focus or open status changed
/// Per default only uses the main window
///
/// at this point if the target main game window was open (this will never build with false and same goes for the
/// focus!)
base class GTOverlaySwitcher extends StatelessWidget {
  final Widget navigatorChild;

  const GTOverlaySwitcher({
    required this.navigatorChild,
  });

  List<ChangeNotifierProvider<dynamic>> _buildProvider() {
    return <ChangeNotifierProvider<dynamic>>[
      ChangeNotifierProvider<GameWindow>.value(value: GameToolsLib.mainGameWindow),
    ];
  }

  Widget buildWithState(BuildContext context, GameWindow window) {
    // todo: gibt constraints für home page und baut im overlay mode den settings knopf oben rechts (ggf togglebar und
    // auch hotkey einstellbar? aber dann würde erkennung nicht gehen? ggf dazu schreiben! oder vorher noch andere
    // methode testen!)

    return navigatorChild;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _buildProvider(),
      child: Consumer<GameWindow>(
        builder: (BuildContext context, GameWindow window, Widget? child) {
          Logger.verbose(
            "Main GameWindow ${window.name} is ${window.isOpen == false ? "not " : ""}open and has "
            "${window.hasFocus == false ? "no " : ""}focus",
          );
          return buildWithState(context, window);
        },
      ),
    );
  }
}
