import 'dart:ui' show Locale;
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/utils/locale_extension.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';

/// Special case: [Locale] as a config option which provides another getter [activeLocale].
///
/// This is a nullable [EnumConfigOption] and has [stringToData] and [dataToString] overridden!
/// Because null should be stored to represent the system locale!
final class LocaleConfigOption extends EnumConfigOption<Locale?> {
  LocaleConfigOption({
    required super.title,
    super.description,
    super.defaultValue,
  }) : super(
         availableOptions: <Locale?>[],
         updateCallback: null,
         convertToTranslationKeys: _localeToKey,
         onInit: _addSupportedLocales,
       );

  /// callback used in added to add support locales during init, because a constructor could not directly access
  /// the fixed config when its not already initialized. and can also not access instance members during constructor.
  static Future<void> _addSupportedLocales(MutableConfigOption<dynamic> configOption) async {
    final LocaleConfigOption localeConfigOption = configOption as LocaleConfigOption;
    localeConfigOption.availableOptions.addAll(FixedConfig.fixedConfig.supportedLocales);
  }

  /// callback used for translation keys in ui builder
  static TranslationString _localeToKey(Locale? locale) => TS(locale?.translationKey ?? "locale.system");

  /// Returns the currently active locale which can be the current [_value], but also the default system locale, but
  /// also the first locale of the locale list!
  Locale get activeLocale {
    final Locale? locale = cachedValue() ?? LocaleExtension.getSupportedSystemLocale();
    return locale ?? availableOptions.first!;
  }

  @override
  Locale? stringToData(String? str) => LocaleExtension.getLocaleByName(str);

  @override
  String? dataToString(Locale? data) => data?.toLanguageTag();
}
