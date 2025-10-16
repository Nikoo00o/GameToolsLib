part of 'gt_asset.dart';

/// Important: for general usage first look at the doc comments of [GTAsset]!
///
/// This is a special case used in [GTApp] to load the translation files for the current locale of the app! Which is
/// almost like a [JsonAsset].
///
/// So [isMultiLanguage] and [fileName] are ignored here and [fileEnding] is always ".json".
///
/// The [subFolderPath] is "locales" per default, but may be overwritten!
///
/// [possibleFileNames], [_alsoLoadSecondPath] and [_checkAllFilesInDirectory] are overridden to first load the generic
/// language files of the current [GameToolsLib.appLanguage] like "en.json", or "de.json", but also afterwards
/// replace the values with more specific ones from any files in the "locales" folder below the "assets" folder ending
/// with "_en.json", or "_de.json", etc.
///
/// [translations] just returns [validContent], but valid content itself also checks if the translations is not empty!
base class LocaleAsset extends GTAsset<Map<String, String>> {
  LocaleAsset({String localesPath = "locales"})
    : super._(fileName: "", subFolderPath: localesPath, isMultiLanguage: false, fileEnding: "json");

  @override
  Map<String, String> get validContent {
    final Map<String, String> content = super.validContent;
    if (content.isEmpty) {
      throw AssetException(
        message: "$runtimeType didn't load a single translation for: $possibleFileNames from folders: $possibleFolders",
      );
    }
    return content;
  }

  /// Just returns [validContent]
  Map<String, String> get translations => validContent;

  /// Overridden to first return the base language file like "en.json" and then variable language files like "_en.json"
  @override
  (String, String) get possibleFileNames {
    _checkAllFilesSwitcher = false;
    final String languageCode = GameToolsLib.appLanguage.languageCode;
    final String ending = ".$fileEnding";
    return ("$languageCode$ending", "_$languageCode$ending");
  }

  /// See [_checkAllFilesInDirectory]
  bool _checkAllFilesSwitcher = false;

  /// Overridden to always return true
  @override
  bool _alsoLoadSecondPath(String secondFileName) {
    _checkAllFilesSwitcher = true;
    return true;
  }

  /// Used as a toggle which is set in [possibleFileNames] to false and in  [_alsoLoadSecondPath] to true to only
  /// affect the loading of the second variable language file ending
  @override
  bool _checkAllFilesInDirectory() => _checkAllFilesSwitcher;

  /// Overridden to just load json file and replace keys with new values if already contained and only set map once
  /// at first!
  @override
  void loadFromFile(String absolutePath) {
    final Map<String, dynamic>? data = HiveDatabase.database.readJson(absoluteFilePath: absolutePath);
    if (data != null) {
      if (_loadedContent == null) {
        _loadedContent = <String, String>{}; // small difference to json asset, always replace keys and init map to
        // string!
      }
      for (final MapEntry<String, dynamic> pair in data.entries) {
        _loadedContent![pair.key] = pair.value.toString(); // only save strings here!
      }
      Logger.spam("Loaded ", data.keys.length, " / ", _loadedContent!.keys.length, " keys for next translation file");
    } else {
      Logger.spam("$runtimeType could not read translation keys from ", absolutePath);
    }
  }
}
