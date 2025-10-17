part of 'gt_asset.dart';

/// Important: for general usage first look at the doc comments of [GTAsset]!
///
/// Instances of this class can directly be created and used anywhere to load image files, but remember to not create
/// multiple objects for the same image, so its best to only use objects of this internally in [CompareImage] and not
/// manually!
///
/// One key difference for the [subFolderPath]: check the doc comments of [ImageAsset._combineSubFolderPath] with the
/// new constructor parameter! And the constructor has an additional param [type].
///
/// An example image path would be "assets/images/example/test.png", but of course also "assets/image/test_en.png"
/// would be a valid image path! Important: to get the final path used for loading the image, use [path]!
///
/// And the resulting asset folders for the compiled app would of course be first
/// "data/flutter_assets/packages/game_tools_lib/assets" and then lastly "data/flutter_assets/assets" and if the
/// image is contained in the last app project dir, then it replaces the previous ones and will get loaded instead!
///
/// The [NativeImage] can directly be accessed in [content] or [validContent]. But if the image is corrupted this
/// might throw an exception on access! And remember that [validContent] also throws if the image was null (file not
/// found)!
///
/// In addition to reloading an image with [loadFromFile], you can also save the image to the file here with
/// [saveToFile] (and replace data)!
base class ImageAsset extends GTAsset<NativeImage> {
  /// Additional param to specify the color of the image for [NativeImage.readSync] which is RGB per default!
  final NativeImageType type;

  /// Important: for [baseImageFolder] and [subFolder] params look at the doc comments of [_combineSubFolderPath]!
  /// TLDR: [subFolder] is below [baseImageFolder] and that results in the [subFolderPath].
  ImageAsset({
    required super.fileName,
    String baseImageFolder = "images",
    String subFolder = "",
    super.fileEnding = "png",
    super.isMultiLanguage = false,
    this.type = NativeImageType.RGB,
  }) : super._(subFolderPath: _combineSubFolderPath(baseImageFolder, subFolder));

  /// Important this is used in the constructor to combine the [baseImageFolder] (which is "images" per default)
  /// together with the [subFolder] (which is empty per default) below the "assets" folder so that images are nicely
  /// packed together!
  static String _combineSubFolderPath(String baseImageFolder, String subFolder) =>
      subFolder.isEmpty ? baseImageFolder : FileUtils.combinePath(<String>[baseImageFolder, subFolder]);

  /// Returns the path to the latest loaded image (so the final override), or a fallback path if no image was found
  /// as the last possible store location in your final app project!
  /// Cached in [loadFromFile] and then used in [initContentIfNeeded] and reset in next [loadContent]!
  ///
  /// Used for [saveToFile]! Returns a fallback path (as the last possible location) of [possibleFolders.last] and
  /// first of [possibleFileNames].
  String get path {
    if (_path != null) {
      return _path!;
    }
    final (String first, String second) = possibleFileNames;
    return FileUtils.combinePath(<String>[possibleFolders.last, first]);
  }

  /// See [path]
  String? _path;

  /// Overridden to replace paths at first and only load the image at the end in [initContentIfNeeded] with the most
  /// recent path!
  @override
  void loadFromFile(String absolutePath) {
    _path = absolutePath;
  }

  /// Saves the [content] to the [path], or if [replaceWith] is not null, then it will first replace the [content]
  /// and afterwards saves it to the path! If both [content] and [replaceWith] are null, then an [AssetException]
  /// will be thrown!
  void saveToFile({NativeImage? replaceWith}) {
    if (replaceWith != null) {
      _loadedContent = replaceWith;
    }
    if (content != null) {
      content!.saveSync(path);
      Logger.spam(runtimeType, replaceWith != null ? " replaced and" : "", " saved new image data to ", path);
    } else {
      throw AssetException(message: "$runtimeType.saveToFile both content and replaceWith are null for $_path");
    }
  }

  /// Overridden to perform loading of the image only at the end with the most recent path and using that as loaded
  /// content. This might throw an exception for corrupted images!
  @override
  void initContentIfNeeded(NativeImage? _) {
    if (_path != null) {
      _loadedContent = NativeImage.readSync(path: _path!);
      Logger.spam(runtimeType, " loaded image data from path ", _path);
    }
    super.initContentIfNeeded(_loadedContent);
  }

  /// Overridden to first always reset the internal path to null
  @override
  NativeImage? loadContent() {
    _path = null;
    return super.loadContent();
  }
}
