import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show protected, mustCallSuper;
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/enums/native_image_type.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/file_utils.dart';
import 'package:game_tools_lib/data/native/native_image.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_app.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/compare_image.dart';

part 'json_asset.dart';

part 'locale_asset.dart';

part 'image_asset.dart';

/// Instances of this class can directly be created and used anywhere to load static asset files containing some
/// strings, images, or other data that you collected before starting the program like for example a list of names
/// (which may be replaced in the final app folder, or by user modification, but are stored statically in the source
/// code). Use any of [LocaleAsset], [ImageAsset] and [JsonAsset]'s instead of using this directly.
///
/// The content is late initialized and only loaded from file the first time is it used at which point
/// [GameToolsLib.initGameToolsLib] must have been called!
///
/// IMPORTANT: this uses [GameToolsConfig.staticAssetFolders] to find all asset folders containing a file matching this,
/// so make sure to also look at the doc comments there, ESPECIALLY on how to modify your pubspec.yaml!!!
/// DO NOT use any of the subclasses of this for your custom dynamic data paths of [GameToolsConfig.resourceFolderPath]!
///
/// For configuration this offers [subFolderPath], [fileName], [isMultiLanguage] and [fileEnding] and for access it
/// offers [content]. Also look at the doc comments of those! And you do not have to call [loadContent]. If you want
/// to access the content not nullable but maybe with an exception, use the [validContent] getter instead!
///
/// TLDR: affects paths "data/flutter_assets/assets/...", "data/flutter_assets/packages/game_tools_lib/assets/...", ...
///
/// And will replace assets (either values, or whole file) of packages/plugins with overrides of the final app
/// project. Also may use different files depending on the current language! So a final path to a file might look like:
/// "data/flutter_assets/assets/images/test_en.png" and you would have to put the "test_en.png" into your
/// projects "/assets/images" folder that is included in your pubspec.yaml! and then you would also put a
/// "test_de.png" there for a different language! But if you use a library (for example this game tools lib) that
/// contains the same "test_en.png" image than you in your final app project, then yours will replace the old one!
abstract base class GTAsset<T> {
  /// The path after "data/flutter_assets/assets" or "data/flutter_assets/packages/game_tools_lib/assets" (which
  /// relates to the "assets" folder in your project directory [GameToolsConfig.staticAssetFolders]) to the folder
  /// your [fileName] is in. For example "locales" for [LocaleAsset]. This may be empty.
  final String subFolderPath;

  /// The last path to read the files after your [subFolderPath] and before the [fileEnding]. Important: if this is
  /// empty, then it will read all files within the enclosing folder with the same file ending! For example one image
  /// with "test" for [ImageAsset]. Its important to not include the file ending here!
  final String fileName;

  /// If this is true, then this file will be loaded depending on the [GameToolsLib.gameLanguage] with the two letter
  /// [Locale.languageCode] being put after the [fileName] and an underscore before the [fileEnding]. Important: as a
  /// default case if true, this will always also check the first [FixedConfig.supportedLocales] (mostly "_en") if no
  /// files for the current language were not found. Otherwise if this is false, then no language string will be
  /// inserted!
  /// So for example "_en", or "_de" will be inserted if true depending on the language. If false "" as nothing.
  final bool isMultiLanguage;

  /// The file ending after the [fileName], for example "json" for [JsonAsset]. Important: don't add the dot (".")!
  final String fileEnding;

  /// The loaded content from the files which is directly available after the constructor call (because it is loaded
  /// on demand the first time it is accessed and then cached)!
  ///
  /// If this is null, then the files were invalid, or could not be read! The error check and handling has to be done
  /// elsewhere and this will never throw! But you may call (and override) [validContent] which throws an
  /// [AssetException] if the content is null and otherwise returns it not nullable!
  // todo: comment how files are loaded and modified
  T? get content => _loadedContent;

  /// Will be set to cache results of [loadContent]
  late T? _loadedContent = loadContent();

  GTAsset._({
    required this.subFolderPath,
    required this.fileName,
    required this.isMultiLanguage,
    required this.fileEnding,
  }) {
    if (fileEnding.isEmpty || fileEnding.startsWith(".")) {
      throw AssetException(
        message:
            "File ending for $runtimeType $fileName within $subFolderPath started with \".\" "
            "or was empty",
      );
    }
  }

  /// This can be used to check if the content was loaded correctly and otherwise throw an [AssetException].
  /// You have to call this manually (and you can also use this to ensure that this asset is loaded/initialized at a
  /// specific time, but of course you may also override this for additional checks and use this super method)
  @mustCallSuper
  T get validContent {
    if (content == null) {
      throw AssetException(
        message: "$runtimeType can't load possible files: $possibleFileNames from folders: $possibleFolders",
      );
    }
    return content!;
  }

  /// Returns the [GameToolsConfig.staticAssetFolders] together with the [subFolderPath] as [FileUtils.combinePath]
  /// to return all possible parent paths which may contain the files in the correct order lib -> app.
  List<String> get possibleFolders => subFolderPath.isEmpty
      ? GameToolsConfig.baseConfig.staticAssetFolders
      : GameToolsConfig.baseConfig.staticAssetFolders
            .map((String path) => FileUtils.combinePath(<String>[path, subFolderPath]))
            .toList();

  /// If [isMultiLanguage] is false, then this just returns 1 element as [fileName].[fileEnding] and the second is
  /// empty!
  /// Otherwise if true it returns the path with the [GameToolsLib.gameLanguage]'s [Locale.languageCode] first and
  /// then secondly the fallback with the first entry of [FixedConfig.supportedLocales].
  ///
  /// The first file path then is always loaded and the second only if [_alsoLoadSecondPath] returns true!
  (String, String) get possibleFileNames {
    if (isMultiLanguage == false) {
      return ("$fileName.$fileEnding", "");
    } else {
      return (
        "${fileName}_${GameToolsLib.gameLanguage.languageCode}.$fileEnding",
        "${fileName}_${FixedConfig.fixedConfig.supportedLocales.first!.languageCode}.$fileEnding",
      );
    }
  }

  /// ONLY USED INTERNALLY!!!! Don't use this directly!!!!
  /// This is overridden in sub classes to load the file content of [absolutePath] (its guaranteed that it exists here)
  /// and then either always replace the current [_loadedContent] with the newest file, or only set the content once
  /// if its null and afterwards replace json keys with new loaded values!
  /// Important: this will be called multiple times for each file in the correct order from plugin package -> final
  /// app project, but before the first file the [_loadedContent] is set to null first!
  @protected
  void loadFromFile(String absolutePath);

  @protected
  /// ONLY USED INTERNALLY!!!! Don't use this directly!!!! per default this only logs the load success as spam logs.
  /// This can be overridden to perform additional init stuff for the content and call this super method at the end
  /// for the logs
  void initContentIfNeeded(T? loadedContent) {
    final T content = _loadedContent as T;
    if (content is Map) {
      Logger.spam(runtimeType, " loaded total content with ", content.length, " elements in map");
    } else if (content is String) {
      Logger.spam(runtimeType, " loaded total content with ", content.length, " characters in string");
    } else {
      Logger.spam(runtimeType, " loaded total content: ", content);
    }
  }

  /// Overridden in [LocaleAsset]!
  /// This is used to decide in [loadContent] if the second path of [possibleFileNames] should also be loaded and per
  /// default only returns true if the second fileName is not empty and the content is still null. But of course may
  /// be overridden in sub classes
  bool _alsoLoadSecondPath(String secondFileName) => _loadedContent == null && secondFileName.isNotEmpty;

  /// Overridden in [LocaleAsset]!
  /// Used in [_loadFilesFromFolders] to either try to load a file with the [fileName] or if this method returns true
  /// tries to load all files ending with the [possibleFileNames] (which per default happens if the fileName is empty
  /// so that all files in that folder ending with the language code get loaded)
  bool _checkAllFilesInDirectory() => fileName.isEmpty;

  /// used in [_loadFilesFromFolders] to call [loadFromFile]
  void _loadFile(String fullPath) {
    if (FileUtils.fileExists(fullPath)) {
      loadFromFile(fullPath);
      Logger.spam(runtimeType, " loaded from: ", fullPath);
    } else {
      Logger.spam(runtimeType, " could not find: ", fullPath);
    }
  }

  /// Used by [loadContent] to call [_loadFilesFromFolders]. Loads all files if [_checkAllFilesInDirectory] returns
  /// true and otherwise only the [filePath]
  void _loadFilesFromFolders(List<String> folders, String filePath) {
    for (final String parentPath in folders) {
      if (_checkAllFilesInDirectory()) {
        final List<String> files = FileUtils.getFilesInDirectorySync(parentPath, skipDirectories: true);
        for (final String fullPath in files) {
          if (fullPath.endsWith(filePath)) {
            _loadFile(fullPath); // special case, check all files that end with same ending filePath
          }
        }
      } else {
        _loadFile(FileUtils.combinePath(<String>[parentPath, filePath])); // only load the one target file
      }
    }
  }

  /// This is called the first time the [content] is accessed automatically internally to load the data from the
  /// file's, but of course you can also call it multiple times to reload the data! The subclasses will do the real
  /// file reading in [loadFromFile]!
  ///
  /// Loads [possibleFolders] / [possibleFileNames] (which means [fileName]<_OPTIONAL_LANGUAGE_CODE>.[fileEnding]
  /// while loading app project files later and replacing old values!
  ///
  /// Also calls [initContentIfNeeded] after all file reads for some additional init work before returning it and
  /// logging the creation success!
  T? loadContent() {
    _loadedContent = null;
    final List<String> folders = possibleFolders;
    final (String first, String second) = possibleFileNames;
    _loadFilesFromFolders(folders, first); // first load first file name
    if (_alsoLoadSecondPath(second)) {
      _loadFilesFromFolders(folders, second); // also load second fallback if method returns true
    }
    if (_loadedContent == null) {
      Logger.warn("$runtimeType could not load any content");
    } else {
      initContentIfNeeded(_loadedContent); // also prints success logs
    }
    return _loadedContent;
  }
}
