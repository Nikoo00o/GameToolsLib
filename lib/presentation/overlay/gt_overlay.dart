import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/enums/overlay_mode.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/base/ui_helper.dart';
import 'package:game_tools_lib/presentation/overlay/widgets/gt_settings_button.dart';
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
  // todo: MULTI-WINDOW IN THE FUTURE: no longer used, because instead a separate window is used
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
  final GlobalKey<ScaffoldState> _overlayScaffold = GlobalKey<ScaffoldState>();

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
      UIHelper.simpleValueProvider(value: overlayManager().overlayMode),
    ];
  }

  /// Can be overridden in sub classes to display some centered ui element, but per default returns centered nothing
  Widget buildCenterChild(BuildContext context, OverlayMode overlayMode) {
    return const Center(child: SizedBox());
  }

  /// Can be overridden to not display the top right settings icon to switch back to full app mode
  // todo: MULTI-WINDOW IN THE FUTURE: remove this
  Widget buildTopRightSettings(BuildContext context, OverlayMode overlayMode) {
    return const Positioned(top: 1, right: 1, child: GtSettingsButton());
  }

  /// Decides depending on the [overlayMode] what to build and is the main logic part of this widget
  Widget buildWithState(BuildContext context, GameWindow window, OverlayMode overlayMode) {
    // todo: gibt constraints für home page und baut im overlay mode den settings knopf oben rechts (ggf togglebar und
    // auch hotkey einstellbar? aber dann würde erkennung nicht gehen? ggf dazu schreiben! oder vorher noch andere
    // methode testen!)

    if (overlayMode == OverlayMode.APP_OPEN) {
      return widget.navigatorChild;
    }

    return Scaffold(
      key: _overlayScaffold,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: <Widget>[
          // draw middle center child first
          buildCenterChild(context, overlayMode),

          // draw settings as last top most child
          buildTopRightSettings(context, overlayMode),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _buildProvider(),
      child: Consumer<GameWindow>(
        builder: (BuildContext context, GameWindow window, Widget? child) {
          // this also rebuilds when main game window bounds change to rebuilds all ui elements!
          Logger.verbose(
            "Main GameWindow ${window.name} is ${window.isOpen == false ? "not " : ""}open and has "
            "${window.hasFocus == false ? "no " : ""}focus",
          );
          return UIHelper.simpleConsumer(
            builder: (BuildContext context, OverlayMode overlayMode, Widget? child) {
              return buildWithState(context, window, overlayMode);
            },
          );
        },
      ),
    );
  }

  /// Shows a bottom SnackBar with the translated [message] if this is currently displaying in any other than
  /// [OverlayMode.APP_OPEN]! Optionally a custom [duration] may be given.
  ///
  /// Otherwise nothing will be shown/done!
  ///
  /// This may not be called during build (use post frame callback)!
  void showToast(TranslationString message, [Duration duration = const Duration(seconds: 4)]) {
    if (_overlayScaffold.currentContext?.mounted ?? false) {
      final SnackBar snackBar = SnackBar(
        content: Center(
          child: Text(
            GTBaseWidget.translateS(message, null),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85)),
          ),
        ),
        duration: duration,
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
      );
      ScaffoldMessenger.of(_overlayScaffold.currentContext!).showSnackBar(snackBar);
    }
  }

  /// Just references the [OverlayManager.overlayManager] with the correct subclass type [T]
  T overlayManager<T extends OverlayManagerBaseType>() => OverlayManager.overlayManager<T>();
}
