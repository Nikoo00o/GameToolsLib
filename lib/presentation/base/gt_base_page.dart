import 'package:flutter/material.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/base/ui_helper.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Base class for all pages with some helper functions like [popPage] and [pushPage].AboutDialog
///
/// This already has a [build] method that returns a [Scaffold] with your widgets from [buildBody] that you need to
/// override.
///
/// If you need to build providers for both your [buildAppBar], and your [buildBody], then build them in
/// [buildProviders]!
///
/// The methods [buildAppBar] and [buildMenuDrawer], or [buildBottomBar] can also be overridden.
/// Also remember to override [pageName] with a name for debugging!
///
/// To build selectors, etc look for example at [UIHelper.configConsumer] or just use the default [Consumer], or
/// [Selector] widgets. But if you need to listen to a stream that provides updates to the ui via events, then use
///
abstract base class GTBasePage extends GTBaseWidget {
  /// The default page padding
  static const EdgeInsets defaultPagePadding = EdgeInsets.fromLTRB(8, 8, 8, 8);

  /// if background image should be shown for body
  final AssetImage? backgroundImage;

  /// only shown if background image is not shown
  final Color? backgroundColor;

  /// default padding is (20, 5, 20, 20)
  final EdgeInsetsGeometry pagePadding;

  const GTBasePage({
    super.key,
    this.backgroundImage,
    this.backgroundColor,
    EdgeInsetsGeometry? pagePadding,
  }) : pagePadding = pagePadding ?? defaultPagePadding;

  /// Returns [backgroundImage] if not its not null
  DecorationImage? getBackgroundImage() {
    if (backgroundImage != null) {
      return DecorationImage(image: backgroundImage!, fit: BoxFit.cover);
    }
    return null;
  }

  /// Returns the [backgroundColor] if the [backgroundImage] is null, otherwise this returns null.
  ///
  /// If the [backgroundColor] is null as well, then the themes [colorScaffoldBackground] color will be used, which is the
  /// same as the [colorBackground] and this method here returns null as well.
  Color? getBackgroundColor(BuildContext context) {
    if (backgroundImage != null) {
      return null;
    }
    if (backgroundColor != null) {
      return backgroundColor!;
    }
    return null; // default from theme
  }

  /// The page name for logging.
  ///
  /// This needs to be overridden in the subclass
  String get pageName;

  @override
  Widget build(BuildContext context) {
    final List<SingleChildWidget> providers = buildProviders(context);
    final Color? backgroundColor = getBackgroundColor(context);
    final DecorationImage? backgroundImage = getBackgroundImage();
    final Widget scaffold = Scaffold(
      body: Container(
        padding: pagePadding,
        decoration: backgroundColor != null || backgroundImage != null
            ? BoxDecoration(image: backgroundImage, color: backgroundColor)
            : null,
        child: buildBody(context),
      ),
      appBar: buildAppBar(context),
      drawer: buildMenuDrawer(context),
      bottomNavigationBar: buildBottomBar(context),
    );
    if (providers.isNotEmpty) {
      return MultiProvider(providers: providers, child: scaffold);
    } else {
      return scaffold;
    }
  }

  /// Can be used in the [buildAppBar] to build a default app bar translating and showing the [titleKey] together
  /// with the [GameToolsConfig.appTitle]. And [buildBackButton] is false per default, but can be used to build a
  /// back button! Optionally [actions] can also display some elements on the right of the app bar!
  PreferredSizeWidget? buildAppBarDefaultTitle(
    BuildContext context,
    String titleKey, {
    bool buildBackButton = false,
    List<Widget>? actions,
  }) {
    return AppBar(
      leading: buildBackButton ? BackButton() : null,
      title: Text(
        "${GameToolsConfig.baseConfig.appTitle} - ${translate(context, titleKey)}",
        style: textTitleLarge(context).copyWith(fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
      actions: actions,
    );
  }

  /// This can be overridden inside of a subclass to build the [AppBar] for this page.
  PreferredSizeWidget? buildAppBar(BuildContext context) => null;

  /// This can be overridden inside of a subclass to build a menu drawer for this page.
  Widget? buildMenuDrawer(BuildContext context) => null;

  /// You can override this to build a custom [BottomNavigationBar], or [BottomAppBar] for this page.
  Widget? buildBottomBar(BuildContext context) => null;

  /// Should be overridden in your subclass if you need to build some providers.
  /// The returned providers will be put into a [MultiProvider]!
  List<SingleChildWidget> buildProviders(BuildContext context) => <SingleChildWidget>[];

  /// builds the body of the page.
  ///
  /// Needs to be overridden in sub classes
  Widget buildBody(BuildContext context);

  /// pops the current page if one was added on top of the routes with [pushPage].
  ///
  /// Optionally this can also pass data back to the last page!
  void popPage(BuildContext context, dynamic data) {
    Logger.debug("Pop called on page $pageName with data $data");
    Navigator.of(context).pop(data);
  }

  /// pushes a new page (that has no route) on top of the navigator without removing other stored pages.
  /// This can also be awaited to wait for data returned by a [popPage] call when navigating back to this!
  Future<dynamic> pushPage(BuildContext context, GTBasePage page) async {
    Logger.debug("Navigating to page ${page.pageName}");
    return Navigator.push<dynamic>(context, MaterialPageRoute<dynamic>(builder: (BuildContext context) => page));
  }

  /// Shows the left menu only if the [context] is below a [Scaffold]!
  void openMenuDrawer(BuildContext context) {
    if (isMenuDrawerOpen(context) == false) {
      Logger.debug("Opening menu");
      Scaffold.of(context).openDrawer();
    }
  }

  /// Hides the left menu only if the [context] is below a [Scaffold]!
  void closeMenuDrawer(BuildContext context) {
    if (isMenuDrawerOpen(context) == true) {
      Logger.debug("Closing menu");
      Scaffold.of(context).closeDrawer();
    }
  }

  /// Returns if the left menu is open only if the [context] is below a [Scaffold]!
  bool isMenuDrawerOpen(BuildContext context) => Scaffold.of(context).isDrawerOpen;
}
