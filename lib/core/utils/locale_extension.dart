import 'dart:io';
import 'dart:ui';

import 'package:game_tools_lib/core/config/fixed_config.dart';

/// Provides [getLocaleByName], [getSupportedSystemLocale], [translationKey] and [fileName] for [Locale]
extension LocaleExtension on Locale {
  /// Used to translate the language name itself
  String get translationKey => "locale.$languageCode";

  /// Used to find the translation file for this language
  String get fileName => "$languageCode.json";

  /// Converts for example "en_US" to Locale("en", "US")
  static Locale? getLocaleByName(String? localeName) {
    if (localeName != null && localeName.isNotEmpty) {
      late final List<String> split;
      if (localeName.contains("_")) {
        split = localeName.split("_");
      } else if (localeName.contains("-")) {
        split = localeName.split("-");
      } else {
        return Locale(localeName);
      }
      if (split.length == 2) {
        return Locale(split[0], split[1]);
      }
      return Locale(localeName);
    }
    return null;
  }

  /// Only returns the locale if its in the supported locales! May return null
  static Locale? getSupportedSystemLocale() {
    final Locale? systemLocale = LocaleExtension.getLocaleByName(Platform.localeName);
    if (systemLocale != null &&
        FixedConfig.fixedConfig.supportedLocales
            .where((Locale? locale) => locale?.languageCode == systemLocale.languageCode)
            .isNotEmpty) {
      return systemLocale;
    } else {
      return null;
    }
  }
}
