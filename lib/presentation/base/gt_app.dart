import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/enums/gt_contrast.dart';
import 'package:game_tools_lib/core/utils/file_utils.dart';
import 'package:game_tools_lib/core/utils/locale_extension.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:game_tools_lib/presentation/base/gt_overlay_switcher.dart';
import 'package:game_tools_lib/presentation/base/ui_helper.dart';
import 'package:game_tools_lib/presentation/pages/home/gt_home_page.dart';
import 'package:game_tools_lib/presentation/pages/hotkeys/gt_hotkeys_page.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigation_page.dart';
import 'package:game_tools_lib/presentation/pages/navigation/gt_navigator.dart';
import 'package:game_tools_lib/presentation/pages/settings/gt_settings_page.dart';
import 'package:provider/provider.dart';

// todo: doc comment
/// The top level widget that builds the app itself with the widget subtree
base class GTApp extends StatelessWidget {
  /// This may be used to provide additional pages to display as options in the navigation rail of [GTNavigator].
  /// But you can also override [buildNavigator] instead for more options.
  final List<GTNavigationPage> additionalNavigatorPages;

  const GTApp({required this.additionalNavigatorPages});

  List<ChangeNotifierProvider<dynamic>> buildProvider() {
    return <ChangeNotifierProvider<dynamic>>[
      UIHelper.configProvider(option: _mutableConfig.currentLocale),
      UIHelper.configProvider(option: _mutableConfig.useDarkTheme),
    ];
  }

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

  Widget buildOverlaySwitcher(BuildContext context, Widget navigatorChild) {
    return GTOverlaySwitcher(navigatorChild: navigatorChild);
  }

  Widget buildHome(BuildContext context) {
    return buildOverlaySwitcher(context, buildNavigator(context));
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildProvider(),
      child: Builder(
        builder: (BuildContext context) {
          return Selector<LocaleConfigOption, Locale>(
            selector: (_, LocaleConfigOption option) => option.activeLocale,
            builder: (BuildContext context, Locale locale, Widget? child) {
              _loadLocale(locale);
              return UIHelper.configConsumer(
                option: _mutableConfig.useDarkTheme,
                builder: (BuildContext context, bool darkTheme, Widget? child) {
                  final ThemeData theme = _baseConfig.appColors.getTheme(
                    darkTheme: darkTheme,
                    contrast: GTContrast.DEFAULT,
                  );
                  _setSystemStatusBar(isDarkTheme: theme.brightness == Brightness.dark);
                  Logger.verbose(
                    "Displaying $runtimeType with ${darkTheme ? "dark" : "light"} theme and locale $locale",
                  );
                  return buildApp(context, theme, locale);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget buildApp(BuildContext context, ThemeData theme, Locale locale) {
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
      home: buildHome(context),
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

  /// translation values
  static final Map<String, String> _keys = <String, String>{};

  static Locale? _cachedLocale;

  /// This is set during build, so it might be null!
  static Locale? get currentLocale => _cachedLocale;

  /// Is called with the new [locale] when it changes (and of course once at init) to load all translation values
  static void _loadLocale(Locale locale) {
    _cachedLocale = locale;
    final List<String> folders = _baseConfig.localeFolders; // sorted correctly: lib first, game last
    _keys.clear();
    for (final String folder in folders) {
      final File file = File(FileUtils.combinePath(<String>[folder, locale.fileName]));
      if (file.existsSync()) {
        final String jsonString = file.readAsStringSync();
        final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        for (final MapEntry<String, dynamic> pair in jsonMap.entries) {
          _keys[pair.key] = pair.value.toString();
        }
        Logger.spam("Loaded translation file: ", file.path);
      } else {
        Logger.debug("Translation file does not exist: ${file.path}");
      }
    }
    Logger.spam("Loaded ", _keys.length, " translation key-value-pairs for the locale ", locale);
  }

  /// Translates a [key] to a value of the map and replaces the placeholders with the optional [keyParams]..
  ///
  /// If no value was found for the [key], it will return the key itself.
  ///
  /// Important: if you need translation values for building widgets, use [GTBaseWidget.translate] with the current
  /// build context instead to react to locale changes!!!
  static String translate(String key, {List<String>? keyParams}) {
    if (_keys.containsKey(key)) {
      String translatedKey = _keys[key]!;
      if (keyParams != null && keyParams.isNotEmpty) {
        for (int i = 0; i < keyParams.length; i++) {
          final String param = keyParams[i];
          final String placeholder = "{$i}";
          if (translatedKey.contains(placeholder)) {
            translatedKey = translatedKey.replaceAll(placeholder, param);
          } else {
            Logger.warn("Could not replace '$placeholder' with '$param' in '$key'");
          }
        }
      }
      return translatedKey;
    }
    Logger.spam("Translation key not found for locale $_cachedLocale: $key");
    return key;
  }
}

/// Used for translation
class CustomAppLocalizations {
  /// Used for translation
  static CustomAppLocalizations? of(BuildContext context) =>
      Localizations.of<CustomAppLocalizations>(context, CustomAppLocalizations);

  /// delegate translate to translation service
  String translate(String key, {List<String>? keyParams}) => GTApp.translate(key, keyParams: keyParams);
}

/// Used for translation
class CustomAppLocalizationsDelegate extends LocalizationsDelegate<CustomAppLocalizations> {
  @override
  bool isSupported(Locale locale) =>
      GTApp.supportedLocales.where((Locale other) => other.languageCode == locale.languageCode).isNotEmpty;

  @override
  Future<CustomAppLocalizations> load(Locale locale) async => CustomAppLocalizations();

  @override
  bool shouldReload(CustomAppLocalizationsDelegate old) => false;
}
