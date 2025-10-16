import 'package:game_tools_lib/core/utils/file_utils.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

/// Instances of this class can directly be created and used anywhere to load static json asset files containing some
/// strings, or other data that you collected before starting the program like for example a list of names (which may
/// be replaced in the final app, or by user modification, but are stored statically in the source code).
///
/// These are similar to [GameToolsConfig.localeFolders] and also use [FileUtils.getAssetFoldersFor] to merge the files
/// of the asset paths of all packages and your final app (so  "data/flutter_assets/packages/game_tools_lib/assets",
/// ..., "data/flutter_assets/assets") together by replacing the keys in the outer json map with the values
/// (latest will be your apps file).
///
/// You just have to give the [subFolderPath] and the [fileName] and then you get to access the [content] afterwards!
/// (the content is late initialized and loaded from file the first time it is used at which point the
/// [HiveDatabase.database] must be initialized!)
final class JsonAsset {
  /// The path after "data/flutter_assets/assets" or "data/flutter_assets/packages/game_tools_lib/assets" which
  /// relates to the "assets" folder in your project directory that should be created with [FileUtils.combinePath]!
  final String subFolderPath;

  /// The last path to read the file after your [subFolderPath] and before the ".json" ending which is added
  /// automatically!
  final String fileName;

  /// The loaded content from the file which is directly available after the constructor call!
  /// If this is null, then the files were invalid, or could not be read!
  late final Map<String, dynamic>? content = _loadContent();

  JsonAsset({
    required this.subFolderPath,
    required this.fileName,
  });

  // database needs to be initialized here
  Map<String, dynamic>? _loadContent() {
    final List<String> filePaths = FileUtils.getAssetFoldersFor(
      subFolderPath,
    ).map((String parentPath) => FileUtils.combinePath(<String>[parentPath, fileName, ".json"])).toList();

    Map<String, dynamic>? content;
    for (final String path in filePaths) {
      final Map<String, dynamic>? data = HiveDatabase.database.readJson(absoluteFilePath: path);
      if (data != null) {
        if (content == null) {
          content = data;
        } else {
          for (final MapEntry<String, dynamic> pair in data.entries) {
            content[pair.key] = pair.value.toString();
          }
        }
      }
    }

    if (content == null) {
      Logger.warn("Could not load JsonAsset $fileName from asset path $subFolderPath");
    }
    Logger.spam("Loaded JsonAsset $fileName content from asset path $subFolderPath: $content");
    return content;
  }
}
