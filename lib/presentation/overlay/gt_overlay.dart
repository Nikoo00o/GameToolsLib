import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/enums/overlay_mode.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/base/ui_helper.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/canvas_overlay_element.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/helper/canvas_painter.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/helper/overlay_elements_list.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/overlay_element.dart';
import 'package:game_tools_lib/presentation/overlay/widgets/gt_edit_done_button.dart';
import 'package:game_tools_lib/presentation/overlay/widgets/gt_settings_button.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigator.dart';
import 'package:provider/provider.dart';

// todo: doc comments
/// This is shown in a separate second flutter window as a transparent overlay on top of your game (per default
/// [GameToolsLib.mainGameWindow]) and can be used to show or move some overlay ui elements (todo: reference).
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
base class GTOverlayState extends State<GTOverlay> with GTBaseWidget {
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
      ChangeNotifierProvider<OverlayElementsList>.value(value: overlayManager().overlayElements),
      UIHelper.simpleValueProvider(value: overlayManager().overlayMode),
    ];
  }

  /// Can be overridden in sub classes which per default displays full screen transparent canvas that can be drawn on!
  Widget buildCanvas(BuildContext context, OverlayElementsList elements, OverlayMode overlayMode) {
    if (overlayMode == OverlayMode.HIDDEN ||
        overlayMode == OverlayMode.EDIT_UI ||
        overlayMode == OverlayMode.EDIT_COMP_IMAGES) {
      return const Center(child: SizedBox());
    }
    final UnmodifiableListView<CanvasOverlayElement> canvasElements = elements.canvasElements;
    if (canvasElements.isEmpty) {
      return const Center(child: SizedBox());
    }
    return CustomPaint(
      painter: CanvasPainter(canvasElements),
      child: const Center(child: SizedBox()),
    );
  }

  /// Can be overridden in sub classes which per default displays full screen transparent canvas that can be drawn on!
  /// builds the elements of [OverlayElementsList] nested for performance reasons!
  List<Widget> buildOverlayElements(BuildContext context, OverlayElementsList elements, OverlayMode overlayMode) {
    if (overlayMode == OverlayMode.HIDDEN) {
      return const <Widget>[SizedBox()];
    }
    final List<Widget> children = <Widget>[];
    if (overlayMode == OverlayMode.VISIBLE) {
      children.addAll(
        elements.staticElements.map((OverlayElement element) => element.build(context, editInsteadOfOverlay: false)),
      );
      children.addAll(
        elements.dynamicElements.map((OverlayElement element) => element.build(context, editInsteadOfOverlay: false)),
      );
    } else if (overlayMode == OverlayMode.EDIT_UI) {
      children.addAll(
        elements.canvasElements.map((OverlayElement element) => element.build(context, editInsteadOfOverlay: true)),
      );
      children.addAll(
        elements.staticElements.map((OverlayElement element) => element.build(context, editInsteadOfOverlay: true)),
      );
    } else if (overlayMode == OverlayMode.EDIT_COMP_IMAGES) {
      children.addAll(
        elements.compareImages.map((OverlayElement element) => element.build(context, editInsteadOfOverlay: true)),
      );
    }
    return children;
  }

  /// Can be overridden to not display the top right checkbox in [OverlayMode.EDIT_UI] or [OverlayMode.EDIT_COMP_IMAGES]
  Widget buildEditCheckmark(BuildContext context) {
    return const Positioned(top: 1, right: 26, child: GTEditDoneButton());
  }

  /// Can be overridden to not display the top right settings icon to switch back to full app mode!
  // todo: MULTI-WINDOW IN THE FUTURE: remove this
  Widget buildTopRightSettings(BuildContext context, OverlayMode overlayMode) {
    return const Positioned(top: 1, right: 1, child: GtSettingsButton());
  }

  /// Decides depending on the [overlayMode] what to build and is the main logic part of this widget. Also builds a a
  /// [Consumer] to listen to changes of [OverlayElementsList] list sizes!
  Widget buildWithState(BuildContext context, GameWindow window, OverlayMode overlayMode) {
    if (overlayMode == OverlayMode.APP_OPEN) {
      return widget.navigatorChild;
    }
    return Scaffold(
      key: _overlayScaffold,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Consumer<OverlayElementsList>(
        builder: (BuildContext context, OverlayElementsList elements, Widget? child) {
          return Stack(
            children: <Widget>[
              // draw canvas first
              buildCanvas(context, elements, overlayMode),
              // then ui overlay elements
              ...buildOverlayElements(context, elements, overlayMode),
              // only draw edit checkbox during edit states
              if (overlayMode == OverlayMode.EDIT_UI || overlayMode == OverlayMode.EDIT_COMP_IMAGES)
                buildEditCheckmark(context),
              // and draw settings as last top most child
              buildTopRightSettings(context, overlayMode),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _buildProvider(),
      child: Consumer<GameWindow>(
        builder: (BuildContext context, GameWindow window, Widget? child) {
          // this also rebuilds when main game window bounds change to rebuilds all overlay ui elements!
          Logger.verbose(
            "Main GameWindow ${window.name} is ${window.isOpen == false ? "not " : ""}open and has "
            "${window.hasFocus == false ? "no " : ""}focus with size ${window.size}",
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
  /// Otherwise nothing will be shown/done! This will not listen to locale changes for translation!
  ///
  /// This may not be called during build (use post frame callback)!
  void showToastOverlay(TranslationString message, [Duration duration = const Duration(seconds: 4)]) {
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
