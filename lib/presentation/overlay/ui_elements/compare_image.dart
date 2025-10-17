import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/enums/native_image_type.dart';
import 'package:game_tools_lib/core/enums/overlay_mode.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/bounds.dart';
import 'package:game_tools_lib/core/utils/file_utils.dart';
import 'package:game_tools_lib/core/utils/scaled_bounds.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/data/assets/gt_asset.dart';
import 'package:game_tools_lib/data/native/native_image.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/canvas_overlay_element.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/dynamic_overlay_element.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/helper/editable_builder.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/overlay_element.dart';

/// Instances / objects of this are mostly used to check if the [unscaledImage] is currently shown at the specific
/// [displayDimension] of this overlay element by using [isShown], or you can also try to find the position of the
/// image inside of the window by using [findPos]. Also look at [overlayAwareComparison] which can affect them!
///
/// The [unscaledImage] is used to store the image file and the [ImageAsset.fileName] will be used as the [identifier]!
/// It will be created in the constructor automatically with some additional parameter. Per default all files will be
/// stored inside of "assets/images/compare/", but read comments of constructors for more info.
/// You can also update the image and store new data with [storeNewImage] (instead of [saveToStorage]. The
/// [scaledImage] is cached automatically from the unscaled image!
///
/// For comparison in [isShown] the [compareImages] is used which of course can be overridden in sub classes for
/// different comparison instead of the shifted pixel equal.
///
/// [storedPath] can also be used instead of [unscaledImage.path].
/// The [buildOverlay] method does nothing here and [clickable] will always be false for this!
base class CompareImage extends OverlayElement {
  /// Reference to the locally stored image file from which the (not dynamically changing) [ImageAsset.fileName] will
  /// be used as the [identifier] which is also used as a file name to save this compare image to storage!
  ///
  /// Important: you should always take and save images in the highest resolution possible (for example 2560x1440)
  /// and then scale them down rather than the other way around!
  ///
  /// This is dynamically loaded from storage the first time it is used in either [isShown], [compareImages], or
  /// [storeNewImage]! The scaled to window bounds version of this is cached in [scaledImage]!
  final ImageAsset unscaledImage;

  /// Used for [scaledImage]
  NativeImage? _scaledImageCache;

  /// If this is true (which it is per default, but may be toggled off for performance), then if any visible
  /// [OverlayElement], [DynamicOverlayElement], or [CanvasOverlayElement] are colliding with this (or overlaying),
  /// then the image comparison will be delayed and flickering, because the overlay has to be turned off and on again
  /// (see [windowImageToCompareAgainst])
  final bool overlayAwareComparison;

  /// Factory constructor that will cache and reuse instances for [identifier] and should always be used from the
  /// outside! Checks [cachedInstance] first and then [storeToCache] with [OverlayElement.newInstance] otherwise.
  /// Remember that you have to use [bounds] to override the [attachedWindow]!
  ///
  /// New Params: [fileName] as the pure name of the image asset file which is also used as the [identifier]!
  /// [subFolder] is per default "compare", but can also be extended with [FileUtils.combinePath] to subfolders.
  /// [fileEnding] is "png" per default and the default [imageType] is [NativeImageType.RGB]
  /// for [isMultiLanguage] look at [ImageAsset.isMultiLanguage].
  factory CompareImage({
    bool editable = true,
    OverlayContentBuilder contentBuilder,
    bool visible = true,
    required ScaledBounds<int> bounds,
    required String fileName,
    String subFolder = "compare",
    String fileEnding = "png",
    bool isMultiLanguage = false,
    NativeImageType imageType = NativeImageType.RGB,
    bool overlayAwareComparison = true,
  }) {
    final ImageAsset unscaledImage = ImageAsset(
      fileName: fileName,
      subFolder: subFolder,
      fileEnding: fileEnding,
      isMultiLanguage: isMultiLanguage,
      type: imageType,
    );
    final TranslationString identifier = TranslationString.raw(fileName);
    final OverlayElement overlayElement =
        OverlayElement.cachedInstance(identifier) ??
        OverlayElement.storeToCache(
          CompareImage.newInstance(
            identifier: identifier,
            editable: editable,
            contentBuilder: contentBuilder,
            visible: visible,
            bounds: bounds,
            unscaledImage: unscaledImage,
            overlayAwareComparison: overlayAwareComparison,
          ),
        );
    return overlayElement as CompareImage;
  }

  /// Just a simple constructor for the current [GameToolsLib.mainGameWindow]!
  /// New Params: [fileName] as the pure name of the image asset file which is also used as the [identifier]!
  /// [subFolder] is per default "compare", but can also be extended with [FileUtils.combinePath] to subfolders.
  /// [fileEnding] is "png" per default and the default [imageType] is [NativeImageType.RGB]
  /// for [isMultiLanguage] look at [ImageAsset.isMultiLanguage].
  factory CompareImage.forPos({
    required int x,
    required int y,
    required int width,
    required int height,
    bool editable = true,
    OverlayContentBuilder contentBuilder,
    bool visible = true,
    required String fileName,
    String subFolder = "compare",
    String fileEnding = "png",
    bool isMultiLanguage = false,
    NativeImageType imageType = NativeImageType.RGB,
    bool overlayAwareComparison = true,
  }) => CompareImage(
    editable: editable,
    contentBuilder: contentBuilder,
    visible: visible,
    bounds: ScaledBounds<int>(
      Bounds<int>(x: x, y: y, width: width, height: height),
      creationWidth: null,
      creationHeight: null,
    ),
    fileName: fileName,
    subFolder: subFolder,
    fileEnding: fileEnding,
    isMultiLanguage: isMultiLanguage,
    imageType: imageType,
    overlayAwareComparison: overlayAwareComparison,
  );

  /// New instance constructor should only be called internally from sub classes to create a new object instance!
  /// From the outside, use the default factory constructor instead!
  @protected
  CompareImage.newInstance({
    required super.identifier,
    required super.editable,
    required super.contentBuilder,
    required super.visible,
    required super.bounds,
    required this.unscaledImage,
    required this.overlayAwareComparison,
  }) : super.newInstance(clickable: false);

  @override
  Widget buildOverlay(BuildContext context) {
    Logger.warn("buildOverlay was called on $this");
    return const SizedBox();
  }

  @override
  Widget buildEdit(BuildContext context) {
    return EditableBuilder(
      borderColor: Colors.pinkAccent,
      overlayElement: this,
      alsoColorizeMiddle: true,
      child: null,
    );
  }

  /// Returns and caches the [unscaledImage] scaled to the size of the current [attachedWindow] from the [bounds] which
  /// is used in the methods like [isShown] or [findPos] below!
  ///
  /// This may also throw a [AssetException] if the initial load of the image contained a different width/height
  /// than the default values for the [bounds] (or the values loaded from json file!). Of course the underlying
  /// [AssetException] if the file was not found at all may also be thrown!
  Future<NativeImage> get scaledImage async {
    final Bounds<int> bounds = this.bounds.scaledBounds;
    NativeImage? img = _scaledImageCache;
    if (img == null) {
      img = _scaledImageCache = await unscaledImage.validContent.clone(); // first load clone
      if (bounds.width != img.width || bounds.height != img.height) {
        Logger.warn(
          "$runtimeType first load: size of image $img ${img.width}, ${img.height} does not match size of bounds $bounds",
        );
      }
    }
    if (img.width != bounds.width || img.height != bounds.height) {
      await img.resize(bounds.width, bounds.height);
      Logger.spam(this, " resized image to ", bounds.width, ", ", bounds.height);
    }
    return img;
  }

  /// If [overlayAwareComparison] is true, this might return the [OverlayManager.getWindowImageWithoutOverlay] when
  /// obscured by any ui element and otherwise the [GameWindow.getImage] from the [attachedWindow].
  ///
  /// Used in [isShown] with current bounds and in [findPos] optionally with either target bounds, or null!
  @protected
  Future<NativeImage> windowImageToCompareAgainst(Bounds<int>? bounds) async {
    if (overlayAwareComparison) {
      final OverlayManagerBaseType overlayManager = OverlayManager.overlayManager();
      if (overlayManager.overlayMode != OverlayMode.HIDDEN && overlayManager.overlayMode != OverlayMode.APP_OPEN) {
        if (bounds == null || overlayManager.overlayElements.isObscured(bounds)) {
          final NativeImage img = await overlayManager.getWindowImageWithoutOverlay();
          if (bounds != null) {
            return img.getSubImage(bounds.x, bounds.y, bounds.width, bounds.height, onlyReference: true);
          } else {
            return img;
          }
        }
      }
    }

    if (bounds == null) {
      return attachedWindow.getFullImage(includeBorders: false);
    } else {
      return attachedWindow.getImageB(bounds);
    }
  }

  /// Returns if [myImage] is equal to [gameWindowImage] by using [NativeImage.shiftedEquals] per default.
  /// May be overridden in sub classes for different comparison methods! Used in [isShown]
  @protected
  Future<bool> compareImages(NativeImage myImage, NativeImage gameWindowImage) async {
    return gameWindowImage.shiftedEquals(myImage);
  }

  /// Checks if currently the [unscaledImage] is shown at [displayDimension] by comparing
  /// [windowImageToCompareAgainst] at [bounds.scaledBounds] against.
  ///
  /// by using [compareImages]!
  ///
  /// Just returns false if the window was closed!
  Future<bool> isShown() async {
    if (!attachedWindow.isOpen) {
      return false;
    }
    final Bounds<int> myBounds = bounds.scaledBounds;
    final NativeImage windowImage = await windowImageToCompareAgainst(myBounds);
    final NativeImage myImage = await scaledImage;
    return compareImages(myImage, windowImage);
  }

  /// This is used to search the [unscaledImage] in the [targetBounds] area and return the dimensions if it was found
  /// and otherwise null! If [targetBounds] are null, then this will search the whole window image from top left to
  /// bot right corner (worse performance). Its best to always choose a target area even if its big
  ///
  /// Just returns null if the window was closed
  Future<Bounds<int>?> findPos(Bounds<int>? targetBounds) async {
    if (!attachedWindow.isOpen) {
      return null;
    }
    final NativeImage windowImage = await windowImageToCompareAgainst(targetBounds);
    final NativeImage myImage = await scaledImage;
    throw UnimplementedError("todo: implement"); // todo: implement with template matching from native image
  }

  /// This will take a new screenshot of the current [displayDimension] and then save the [unscaledImage] with the
  /// matching bounds!
  /// Important: you should always take and save images in the highest resolution possible (for example 2560x1440)
  /// and then scale them down rather than the other way around!
  ///
  /// This will only work if [editable] is true and also call [saveToStorage]!
  Future<void> storeNewImage() async {
    if (editable == false) {
      Logger.warn("$this tried to call storeNewImage while editable was false");
    } else {
      final Bounds<int> scaledBounds = bounds.scaledBounds;
      final NativeImage newImage = await windowImageToCompareAgainst(scaledBounds);
      if (_scaledImageCache != null) {
        _scaledImageCache!.cleanupMemory();
      }
      _scaledImageCache = await newImage.clone();
      bounds.move(scaledBounds);
      unscaledImage.saveToFile(replaceWith: newImage);
      saveToStorage();
    }
  }

  /// Shortcut for [unscaledImage.path] to return latest storage path (or a default)
  String get storedPath => unscaledImage.path;
}
