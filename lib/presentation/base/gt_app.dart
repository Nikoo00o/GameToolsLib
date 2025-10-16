import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:game_tools_lib/core/config/locale_config_option.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/utils/file_utils.dart';
import 'package:game_tools_lib/core/utils/locale_extension.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/data/assets/gt_asset.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_app_theme.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/base/ui_helper.dart';
import 'package:game_tools_lib/presentation/overlay/gt_overlay.dart';
import 'package:game_tools_lib/presentation/pages/home/gt_home_page.dart';
import 'package:game_tools_lib/presentation/pages/hotkeys/gt_hotkeys_page.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigation_page.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigator.dart';
import 'package:game_tools_lib/presentation/pages/settings/gt_settings_page.dart';
import 'package:provider/provider.dart';

/// The top level widget that builds the app itself with the widget subtree and provide some top level important
/// classes like the following:
///
/// This provides [UIHelper.configProvider] for [MutableConfig.currentLocale], [MutableConfig.appColors] and
/// [MutableConfig.useDarkTheme] which can be accessed in [UIHelper.configConsumer] further down the widget tree!
///
/// And this also provides the widgets below with changes if main window focus or open status changed which can be
/// accessed with a [Consumer] of [GameWindow], but per default only uses the main window! At this point if the
/// target main game window was open, then this will never build with false and same goes for the focus!
///
/// Subclasses of this should mostly be used to return something different in [buildNavigator].
///
/// This may also be used to statically access [translate] and for the current locale use [GameToolsLib.appLanguage].
base class GTApp extends StatelessWidget {
  /// This may be used to provide additional pages to display as options in the navigation rail of [GTNavigator].
  /// But you can also override [buildNavigator] instead for more options.
  final List<GTNavigationPage> additionalNavigatorPages;

  const GTApp({required this.additionalNavigatorPages});

  /// Builds the top level [Provider] to be used in the app
  List<ChangeNotifierProvider<dynamic>> buildProvider() {
    return <ChangeNotifierProvider<dynamic>>[
      UIHelper.configProvider(option: _mutableConfig.currentLocale),
      UIHelper.configProvider(option: _mutableConfig.appColors),
      UIHelper.configProvider(option: _mutableConfig.useDarkTheme),
      ChangeNotifierProvider<GameWindow>.value(value: GameToolsLib.mainGameWindow),
    ];
  }

  /// Builds the [GTNavigator] with the [GTNavigationPage]s: [GTHomePage], [GTSettingsPage], [GTHotkeysPage],
  /// [additionalNavigatorPages] and can be overridden in sub classes to return more, or fewer!
  Widget buildNavigator(BuildContext context) {
    return GTNavigator(
      pages: <GTNavigationPage>[
        const GTHomePage(),
        GTSettingsPage(),
        GTHotkeysPage(),
        ...additionalNavigatorPages,
      ],
    );
  }

  // todo: MULTI-WINDOW IN THE FUTURE: might be removed
  Widget buildOverlaySwitcher(BuildContext context, Widget navigatorChild) {
    return GTOverlay(navigatorChild: navigatorChild);
  }

  /// Used in [buildApp] to build the main app part which per default just returns [buildNavigator]
  Widget buildHome(BuildContext context) {
    return buildOverlaySwitcher(context, buildNavigator(context));
  }

  /// Is called from [build] to build the app with the theme config options (and locale handled above) and then call
  /// [buildApp]
  Widget buildThemeWithLocale(Locale locale, Widget home) {
    return UIHelper.configConsumer(
      option: _mutableConfig.appColors,
      builder: (BuildContext context, GTAppTheme gtAppTheme, Widget? child) {
        return UIHelper.configConsumer(
          option: _mutableConfig.useDarkTheme,
          builder: (BuildContext context, bool darkTheme, Widget? child) {
            final ThemeData theme = gtAppTheme.getTheme(darkTheme: darkTheme);
            _setSystemStatusBar(isDarkTheme: theme.brightness == Brightness.dark);
            Logger.debug(
              "Displaying $runtimeType with ${darkTheme ? "dark" : "light"} theme and locale $locale",
            );
            return buildApp(context, theme, locale, home);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildProvider(),
      child: Builder(
        builder: (BuildContext context) {
          final Widget home = buildHome(context);
          return Selector<LocaleConfigOption, Locale>(
            selector: (_, LocaleConfigOption option) => option.activeLocale,
            builder: (BuildContext context, Locale locale, Widget? child) {
              localeAsset.loadContent(); // load translation strings for current locale
              return buildThemeWithLocale(locale, home);
            },
          );
        },
      ),
    );
  }

  /// Builds the [MaterialApp] with the home being [buildHome] and called from [buildThemeWithLocale]
  Widget buildApp(BuildContext context, ThemeData theme, Locale locale, Widget home) {
    return MaterialApp(
      title: _baseConfig.appTitle,
      theme: theme,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        CustomAppLocalizationsDelegate(),
      ],
      home: home,
      localeResolutionCallback: (Locale? locale, Iterable<Locale> supportedLocales) =>
          _localeResolutionCallback(locale, supportedLocales, context),
    );
  }

  Locale _localeResolutionCallback(Locale? locale, Iterable<Locale> supportedLocales, BuildContext context) {
    late Locale result;
    if (supportedLocales.where((Locale other) => other.languageCode == locale?.languageCode).isNotEmpty) {
      result = locale!;
    } else {
      Logger.warn("System Locale ${locale?.languageCode} was changed, but not supported");
      result = _baseConfig.fixed.supportedLocales.first!;
    }
    if (_mutableConfig.currentLocale.activeLocale != locale) {
      _mutableConfig.currentLocale.onlyUpdateCachedValue(_mutableConfig.currentLocale.cachedValue()); // update event
    }
    return result;
  }

  void _setSystemStatusBar({required bool isDarkTheme}) =>
      SystemChrome.setSystemUIOverlayStyle(isDarkTheme ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);

  /// Does not contain any null elements
  static final List<Locale> supportedLocales = List<Locale>.from(
    List<Locale?>.of(_baseConfig.fixed.supportedLocales)..removeWhere((Locale? locale) => locale == null),
  );

  static MutableConfig get _mutableConfig => MutableConfig.mutableConfig;

  static GameToolsConfigBaseType get _baseConfig => GameToolsConfig.baseConfig;

  /// Used to load the translation keys for the current locale (may be rarely overwritten) which is always loaded
  /// again when the [LocaleConfigOption.activeLocale] in [MutableConfig.currentLocale] changes to provide the
  /// [LocaleAsset.translations] for [translate]!
  static LocaleAsset localeAsset = LocaleAsset(localesPath: "locales");

  /// Translates a translation [TranslationString.key] for the current locale and placeholders are replaced with
  /// [TranslationString.params].
  ///
  /// If no value was found for the [TranslationString.key], it will return the key itself, but spam log a warning.
  /// If a translated string contains not enough placeholders but more [TranslationString.params] were given, then it
  /// logs a warning. For raw not translated values, use [TranslationString.raw].
  ///
  /// Important: if you need translation values for building widgets, use [GTBaseWidget.translate] with the current
  /// build context instead to react to locale changes!!!
  ///
  /// Placeholders in the translation string of language.json have to start with "{0}" and then "{1}", "{2}", etc.
  /// But you always have to use [TranslationString.params] for translated strings that have those placeholders! (If
  /// you don't want to use them, use a list of empty strings with the same length!)
  static String translate(TranslationString translationString) {
    final String? key = translationString.key;
    if (key == null) {
      return translationString.params!.first; // special case, raw translation string
    }
    if (localeAsset.translations.containsKey(key)) {
      String translatedKey = localeAsset.translations[key]!;
      final List<String>? params = translationString.params;
      if (params != null && params.isNotEmpty) {
        for (int i = 0; i < params.length; i++) {
          final String param = params[i];
          final String placeholder = "{$i}";
          if (translatedKey.contains(placeholder)) {
            translatedKey = translatedKey.replaceAll(placeholder, param);
          } else {
            Logger.warn("Could not replace '$placeholder' with '$param' for '$translationString'");
          }
        }
      }
      return translatedKey;
    }
    Logger.spam("Translation key not found for locale ", GameToolsLib.appLanguage, " : ", translationString);
    return key;
  }
}

/// Used for translation
final class CustomAppLocalizations {
  /// Used for translation
  static CustomAppLocalizations? of(BuildContext context) =>
      Localizations.of<CustomAppLocalizations>(context, CustomAppLocalizations);

  /// delegate translate to translation service
  String translate(TranslationString key) => GTApp.translate(key);
}

/// Used for translation
final class CustomAppLocalizationsDelegate extends LocalizationsDelegate<CustomAppLocalizations> {
  @override
  bool isSupported(Locale locale) =>
      GTApp.supportedLocales.where((Locale other) => other.languageCode == locale.languageCode).isNotEmpty;

  @override
  Future<CustomAppLocalizations> load(Locale locale) async => CustomAppLocalizations();

  @override
  bool shouldReload(CustomAppLocalizationsDelegate old) => false;
}
