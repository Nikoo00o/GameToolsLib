import 'package:flutter/material.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigator.dart';
import 'package:provider/provider.dart';

// todo: doc comments
/// This is shown in a separate second flutter window as a transparent overlay on top of your game (per default
/// [GameToolsLib.mainGameWindow]) and can be used to show or move some ui elements (todo: reference).
///
/// Provides the widgets below with changes if main window focus or open status changed which can be accessed with a
/// [Consumer] of [GameWindow], but per default only uses the main window! At this point if the target main game
/// window was open, then this will never build with false and same goes for the focus!
///
/// Of course also look at the state [GTOverlayState] for this! You need sub classes for both if you want some custom
/// functionality.
base class GTOverlay extends StatefulWidget {
  // todo: this has to be used inside of a different window of the app and the navigatorchild has to be removed!
  /// The [GTNavigator] which contains the different pages of the main ui of the app
  final Widget navigatorChild;

  GTOverlay({
    required this.navigatorChild,
  }) : super(key: OverlayManager.overlayManager().overlayReference);

  @override
  State<GTOverlay> createState() => GTOverlayState();
}

/// State base class for the [GTOverlay] (look at docs of that!) and the current [OverlayManager] in [overlayManager].
base class GTOverlayState extends State<GTOverlay> {
  @override
  void initState() {
    super.initState();
    overlayManager().onCreate(context);
  }

  @override
  void dispose() {
    overlayManager().onDispose(context);
    super.dispose();
  }

  List<ChangeNotifierProvider<dynamic>> _buildProvider() {
    return <ChangeNotifierProvider<dynamic>>[
      ChangeNotifierProvider<GameWindow>.value(value: GameToolsLib.mainGameWindow),
    ];
  }

  Widget buildWithState(BuildContext context, GameWindow window) {
    // todo: gibt constraints für home page und baut im overlay mode den settings knopf oben rechts (ggf togglebar und
    // auch hotkey einstellbar? aber dann würde erkennung nicht gehen? ggf dazu schreiben! oder vorher noch andere
    // methode testen!)

    return widget.navigatorChild;
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

  /// Just references the [OverlayManager.overlayManager] with the correct subclass type [T]
  T overlayManager<T extends OverlayManagerBaseType>() => OverlayManager.overlayManager<T>();
}
