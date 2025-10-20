part of 'gt_asset.dart';

/// Important: for general usage first look at the doc comments of [GTAsset]! Instances of this class can directly be
/// created and used anywhere to get a list of files inside of all asset folders merged together and files with the
/// same name will be replaced! It will only load direct files and no folders!
///
/// [fileName], [fileEnding] and [isMultiLanguage] will be ignored and do nothing here! And [possibleFileNames] just
/// returns empty names!
///
/// Remember the [subFolderPath] has to point to the sub folder that is the same across the packages inside first
/// "data/flutter_assets/packages/game_tools_lib/assets/", ..., and then lastly "data/flutter_assets/assets/".
///
/// The [content] will then provide access to all of the absolute file paths to the files with [FileInfoAsset]! But
/// it may be empty!
base class FolderAsset extends GTAsset<List<FileInfoAsset>> {
  FolderAsset({required super.subFolderPath}) : super._(fileName: "", fileEnding: "_", isMultiLanguage: false);

  /// maps file name (without extension) as key to absolute path as value
  final Map<String, String> _pathToName = <String, String>{};

  /// Overridden to replace paths at first and only load the image at the end in [initContentIfNeeded] with the most
  /// recent path!
  @override
  void loadFromFile(String absolutePath) {
    if (FileUtils.dirExists(absolutePath)) {
      final List<String> files = FileUtils.getFilesInDirectorySync(absolutePath, skipDirectories: true);
      for (final String path in files) {
        final String name = FileUtils.getFileName(path, withoutExtension: true);
        _pathToName[name] = path;
      }
    } else {
      Logger.warn("$runtimeType had to skip $absolutePath because it was no directory");
    }
  }

  @override
  void initContentIfNeeded(List<FileInfoAsset>? _) {
    _loadedContent = <FileInfoAsset>[];
    for (final MapEntry<String, String> entry in _pathToName.entries) {
      _loadedContent!.add(FileInfoAsset(fileName: entry.key, absolutePath: entry.value));
    }
    if (_loadedContent!.isEmpty) {
      Logger.warn("$runtimeType could not find any files in $subFolderPath");
    }
    super.initContentIfNeeded(_loadedContent);
  }

  @override
  (String, String) get possibleFileNames => ("", "");
}

/// Used for [FolderAsset] to group the files together nicely
final class FileInfoAsset {
  /// The file name (without file extension!!!)
  final String fileName;

  /// The full absolute path to the file
  final String absolutePath;

  const FileInfoAsset({required this.fileName, required this.absolutePath});
}
