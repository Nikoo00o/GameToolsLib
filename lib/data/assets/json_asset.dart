part of 'gt_asset.dart';

/// Important: for general usage first look at the doc comments of [GTAsset]!
///
/// This is used to load static json config files with for example crawled data like some area names, etc directly
/// anywhere.
///
/// If you need different translations of those for different locales of [GameToolsLib.gameLanguage], then set
/// [isMultiLanguage] to true (and remember to contain the 2 letter language code like "_en" in the file name).
/// Otherwise per default it is false and you just have to supply the [subFolderPath] below your assets directory
/// and then the [fileName] of your json file without file ending (because that's always ".json").
///
/// And you can simply access the [content] or [validContent] instantly after creating an object of this!
///
/// You can also create subclasses of this with getters to return different keys of [validContent] if you override
/// the valid content getter to also check if the key exists by using for example the [mustContain] helper method!
base class JsonAsset extends GTAsset<Map<String, dynamic>> {
  JsonAsset({
    required super.subFolderPath,
    required super.fileName,
    super.isMultiLanguage = false,
  }) : super._(fileEnding: "json");

  /// This can be used to additionally check the [validContent] if it contains the [key] and the value is of type [T].
  ///
  /// Remember that you should only check against primitive types that can be stored inside of the json map like
  /// [List<dynamic], [Map<String, dynamic] and [String], etc and not class types!
  void mustContain<T extends Object>(String key) {
    if (!validContent.containsKey(key)) {
      throw AssetException(message: "$runtimeType did not contain key $key");
    }
    if (validContent[key] is! T) {
      throw AssetException(message: "$runtimeType value for key $key was not of type $T");
    }
  }

  /// Overridden to just load json file and replace keys with new values if already contained and only set map once
  /// at first!
  @override
  void loadFromFile(String absolutePath) {
    final Map<String, dynamic>? data = HiveDatabase.database.readJson(absoluteFilePath: absolutePath);
    if (data != null) {
      if (_loadedContent == null) {
        _loadedContent = data;
      } else {
        for (final MapEntry<String, dynamic> pair in data.entries) {
          _loadedContent![pair.key] = pair.value;
        }
      }
    } else {
      Logger.warn("$runtimeType could not parse json from: ", absolutePath);
    }
  }
}
