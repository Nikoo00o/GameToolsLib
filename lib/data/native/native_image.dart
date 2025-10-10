import 'dart:ffi' show Pointer, UnsignedChar, Void;
import 'dart:math' show min, max;
import 'dart:ui' show Color, Image, PixelFormat, decodeImageFromPixels;
import 'package:flutter/material.dart'
    show showDialog, BuildContext, AlertDialog, Text, Widget, RawImage, Navigator, TextButton;
import 'package:game_tools_lib/core/enums/native_image_type.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/bounds.dart';
import 'package:game_tools_lib/core/utils/file_utils.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/data/native/native_window.dart' show NativeWindow;
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';
import 'package:opencv_dart/opencv.dart' as cv;

part 'base_native_image.dart';

/// Helper class to interact with opencv images with the internal [cv.Mat] in [_data]. This contains the most used
/// methods and some helper methods are stored in the base class [BaseNativeImage].
///
/// Use either [NativeImage.readSync], or [readAsync] to create an instance of this. And you can also use
/// [saveSync], or [saveAsync] to save this to the disk.
///
/// For comparison there are multiple options like [equals], [pixelSimilarity], etc
///
/// Important: always try to use async methods instead of sync methods! You can also modify the internal data with
/// for example [resize] or [changeTypeAsync].
///
/// [NativeImage.nativeSync] and [NativeImage.nativeAsync] are used internally in [GameWindow] to create images.
///
/// For debugging you can also show this image in the ui with [showImageDialog]
final class NativeImage extends BaseNativeImage {
  /// Used for pixel comparison how high the total R, G, B value difference may be until a pixel is counted as invalid
  static int defaultPixelValueThreshold = 75;

  /// Used for pixel comparison how many invalid pixel would still return true
  static int defaultMaxAmountOfPixelsNotEqual = 40;

  /// Used for pixel comparison as the shift between images in each direction (top, left, right, bot)
  static int defaultShiftedEqualsPixels = 1;

  /// Only takes [mat] reference and optionally [nativeData]. Used in other constructors
  /// If [typeOverride] is not null, then the type will be derived from the [mat.channels] (but this is not possible
  /// for [clone])
  NativeImage._mat(super.mat, {super.nativeData, super.typeOverride}) : super._base();

  /// Creates an image from [data] as a buffer allocated in native c/c++ code with [width] and [height].
  /// For [targetType], look at [NativeImageType] docs!
  /// [logXPos] and [logYPos] are used for logging and are the pos inside of the window (0, 0) for full win, and null
  /// for full display.
  factory NativeImage.nativeSync({
    required int width,
    required int height,
    required Pointer<UnsignedChar> data,
    required NativeImageType targetType,
    int? logXPos,
    int? logYPos,
  }) {
    final NativeImage img = BaseNativeImage._loadNative(width, height, data, logXPos, logYPos);
    img.changeTypeSync(targetType);
    BaseNativeImage._attachToFinalizer(img);
    return img;
  }

  /// Creates an image from [data] as a buffer allocated in native c/c++ code with [width] and [height].
  /// For [targetType], look at [NativeImageType] docs!
  /// [logXPos] and [logYPos] are used for logging and are the pos inside of the window (0, 0) for full win, and null
  /// for full display.
  static Future<NativeImage> nativeAsync({
    required int width,
    required int height,
    required Pointer<UnsignedChar> data,
    required NativeImageType targetType,
    int? logXPos,
    int? logYPos,
  }) async {
    final NativeImage img = BaseNativeImage._loadNative(width, height, data, logXPos, logYPos);
    await img.changeTypeAsync(targetType);
    BaseNativeImage._attachToFinalizer(img);
    return img;
  }

  /// Creates an image by reading it from a [path] and otherwise throws a [ImageException] exception.
  /// For [type], look at [NativeImageType] docs! Default is [NativeImageType.RGB] here.
  /// A copy is only made here with [changeTypeSync] if the [type] should be [NativeImageType.RGBA], but the file has
  /// no alpha channel!
  factory NativeImage.readSync({required String path, NativeImageType type = NativeImageType.RGB}) {
    final int flags = BaseNativeImage._loadFileType(path, type);
    final NativeImage img = NativeImage._mat(cv.imread(path, flags: flags));
    Logger.verbose("Loaded $img ${img.type != type ? "with different type ${img.type}" : ""} from path $path");
    img.changeTypeSync(type);
    return img;
  }

  /// Creates an image by reading it from a [path] and otherwise throws a [ImageException] exception.
  /// For [type], look at [NativeImageType] docs! Default is [NativeImageType.RGB] here.
  /// A copy is only made here with [changeTypeAsync] if the [type] should be [NativeImageType.RGBA], but the file has
  /// no alpha channel!
  static Future<NativeImage> readAsync({required String path, NativeImageType type = NativeImageType.RGB}) async {
    final int flags = BaseNativeImage._loadFileType(path, type);
    final NativeImage img = NativeImage._mat(await cv.imreadAsync(path, flags: flags));
    Logger.verbose("Loaded $img ${img.type != type ? "with different type ${img.type}" : ""} from path $path");
    await img.changeTypeAsync(type);
    return img;
  }

  /// Returns true if the [_data] was successfully stored in [path]
  Future<bool> saveAsync(String path) async {
    if (_data != null) {
      Logger.verbose("Saving $this to path $path");
      return cv.imwriteAsync(path, _data!);
    }
    return false;
  }

  /// May return null if [x], [y] are out of range, or if [_data] is null
  Color? colorAtPixel(int x, int y) {
    Color? color;
    if (_data != null && x >= 0 && x < width && y >= 0 && y < height) {
      final List<num> pixelValues = _data!.atPixel(y, x); // inverted access
      color = BaseNativeImage._pixelToColor(pixelValues);
    }
    Logger.spamPeriodic(BaseNativeImage._otherLog, "color at pixel(", x, ", ", y, ") is: ", color);
    return color;
  }

  /// Pixel per pixel comparison for equality of two images (just iterates through).
  /// This is the most restricted, but also the fastest of all comparison methods!
  ///
  /// [pixelValueThreshold] represents how high the total value difference for each pixel may be until a pixel is
  /// counted as invalid (for example R G B). If its null, then it will use [defaultPixelValueThreshold]
  /// [maxAmountOfPixelsNotEqual] represents how many pixel may be counted as invalid for this to still return true.
  /// If its null, then it will use [defaultMaxAmountOfPixelsNotEqual].
  ///
  /// [NativeImageType.GRAY] can only be compared against itself, but for [NativeImageType.RGB] with
  /// [NativeImageType.RGBA] the alpha channel will just be ignored. You can also set [ignoreAlpha] to true to also
  /// always skip the alpha channel when comparing [NativeImageType.RGBA] to [NativeImageType.RGBA].
  bool equals(NativeImage other, {int? pixelValueThreshold, int? maxAmountOfPixelsNotEqual, bool ignoreAlpha = false}) {
    pixelValueThreshold ??= defaultPixelValueThreshold;
    maxAmountOfPixelsNotEqual ??= defaultMaxAmountOfPixelsNotEqual;
    final int myWidth = width; // width is cols
    final int otherWidth = other.width;
    final int myHeight = height; // height is rows
    final int otherHeight = other.height;
    final int Function(int r, int c)? compareFunc = BaseNativeImage._minPixChange(
      i1: this,
      i2: other,
      ignoreAlpha: ignoreAlpha,
    );
    if (compareFunc == null) {
      return false;
    }
    return BaseNativeImage._compareValsOfMats(
      width1: myWidth,
      height1: myHeight,
      width2: otherWidth,
      height2: otherHeight,
      pixelValueThreshold: pixelValueThreshold,
      maxAmountOfPixelsNotEqual: maxAmountOfPixelsNotEqual,
      compareCallback: compareFunc,
    );
  }

  /// Uses [equals] a number of ([imagePixelShift]*2 + 1) ^ 2 times in total to compare the images with
  /// different offsets to each other for "1" it would be called 9 times (-1 0 +1 pixel shifts in x/y direction)!
  ///
  /// Per default if [imagePixelShift] is null, it will use [defaultShiftedEqualsPixels] instead for 1 pixel in each
  /// 4 directions!
  ///
  /// While comparing, the minimum width and the minimum height of both images will be used for comparison and each
  /// image starts at x/y 0/0 for comparing and then each image will be shifted up to [imagePixelShift] times in each
  /// dimension!
  /// This also means that at least [imagePixelShift] pixels are cut off when comparing pixels, so you might need
  /// stricter pixel threshold values!
  ///
  /// Look at doc comments of [equals] for the meaning of the base parameter!
  bool shiftedEquals(
    NativeImage other, {
    int? pixelValueThreshold,
    int? maxAmountOfPixelsNotEqual,
    bool ignoreAlpha = false,
    int? imagePixelShift,
  }) {
    imagePixelShift ??= defaultShiftedEqualsPixels;
    final int minWidth = width < other.width ? width : other.width;
    final int minHeight = height < other.height ? height : other.height;
    // now compare row by row with both images being shifted once!
    for (int y1 = 0; y1 <= imagePixelShift; ++y1) {
      for (int x1 = 0; x1 <= imagePixelShift; ++x1) {
        final NativeImage firstMine = getSubImage(x1, y1, minWidth, minHeight, onlyReference: true);
        final NativeImage firstOther = getSubImage(0, 0, minWidth - x1, minHeight - y1, onlyReference: true);
        if (firstMine.equals(
          firstOther,
          pixelValueThreshold: pixelValueThreshold,
          maxAmountOfPixelsNotEqual: maxAmountOfPixelsNotEqual,
          ignoreAlpha: ignoreAlpha,
        )) {
          return true;
        }
        if (x1 != 0) {
          final NativeImage secondMine = getSubImage(0, 0, minWidth - x1, minHeight - y1, onlyReference: true);
          final NativeImage secondOther = getSubImage(x1, y1, minWidth, minHeight, onlyReference: true);
          if (secondMine.equals(
            secondOther,
            pixelValueThreshold: pixelValueThreshold,
            maxAmountOfPixelsNotEqual: maxAmountOfPixelsNotEqual,
            ignoreAlpha: ignoreAlpha,
          )) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Similar to [equals] this also compares the difference between the pixels of both matrices, but here instead it
  /// returns a value up to "1.0" (for 100%) on how similar the matrices are.
  ///
  /// It uses either l2 relative error, or comparing histograms and is still a bit restricted, but also not that slow.
  ///
  /// If [comparePixelOverall] is true, then this will not do pixel-per-pixel comparison, but instead looks at the
  /// overall pixels and calculates the difference of those, so its even more similarity than equality!
  /// For example images of different forests should often return a high value, because they have the same colors.
  ///
  /// This has to make some internal copies if the mats are not of the same size (but if [comparePixelOverall] is
  /// true, then this always has to do a lot more copies, but same size does not matter here).
  ///
  /// If the [type] is [NativeImageType.GRAY] then this will throw an [ImageException]!
  Future<double> pixelSimilarity(NativeImage other, {required bool comparePixelOverall}) async {
    if (comparePixelOverall) {
      final cv.Mat hist1 = await _getHistogram();
      final cv.Mat hist2 = await other._getHistogram();
      return cv.compareHistAsync(hist1, hist2, method: cv.HISTCMP_CORREL);
    } else {
      final (NativeImage i1, NativeImage i2) = await BaseNativeImage.makeSameSize(this, other);
      final double errorL2 = await cv.norm1Async(i1._data!, i2._data!); // calculates l2 relative error (sum of all pix)
      return errorL2 / (i1.width * i1.height).toDouble(); // scale down to pix per pix similarity
    }
  }

  /// Sets the image bounds to [newWidth], [newHeight] (reassigns internal data and clears old memory)
  Future<void> resize(int newWidth, int newHeight) async {
    if (_data != null) {
      cleanupMemory(await cv.resizeAsync(_data!, (newWidth, newHeight)), "resize to $newWidth, $newHeight");
    } else {
      Logger.warn("resize called with $newWidth, $newHeight for an null image $this");
    }
  }

  /// Multiplies the image bounds by [widthFactor], [heightFactor] (reassigns internal data and clears old memory).
  /// May throw an [ImageException] if used on an empty image!
  Future<void> scale(double widthFactor, double heightFactor) async {
    if (_data != null && !isEmpty) {
      cleanupMemory(
        await cv.resizeAsync(_data!, (0, 0), fx: widthFactor, fy: heightFactor),
        "scale  to $widthFactor, $heightFactor",
      );
    } else {
      throw ImageException(message: "cant scale image $this to $widthFactor, $heightFactor");
    }
  }

  /// Returns a cropped image out of this image at [x], [y] with size [width], [height].
  /// If you only use this for one comparison, set [onlyReference] so that no unnecessary copy is made, BUT remember
  /// that you should not call [cleanupMemory] on the reference! And also only use it as long as this current image
  /// is not disposed! May throw an [ImageException] if used on an empty image!
  NativeImage getSubImage(int x, int y, int width, int height, {bool onlyReference = false}) {
    if (_data != null &&
        width > 0 &&
        height > 0 &&
        x >= 0 &&
        y >= 0 &&
        x + width <= this.width &&
        y + height <= this.height) {
      final cv.Mat mat = cv.Mat.fromMat(_data!, copy: onlyReference == false, roi: cv.Rect(x, y, width, height));
      return NativeImage._mat(mat);
    } else {
      throw ImageException(message: "cant get SubImage from $this at $x, $y, $width, $height");
    }
  }

  /// Displays this in the ui by using [getDartImage]!
  Future<void> showImageDialog(BuildContext outerContext) async {
    final Image dartImage = await getDartImage();
    if (outerContext.mounted) {
      await showDialog<void>(
        context: outerContext,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(GTBaseWidget.translateS(const TranslationString("input.image"), dialogContext)),
            content: RawImage(image: dartImage),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(GTBaseWidget.translateS(const TranslationString("input.ok"), dialogContext)),
              ),
            ],
          );
        },
      );
    }
    dartImage.dispose();
  }

  /// 100% equality, calls [equals] with pixelRGBThreshold=1 and maxAmountOfPixelsNotEqual=0.
  /// Alpha is only compared if both images have an alpha channel.
  /// The 1 pixel difference is not counted because of rounding errors, so it sets pixelValueThreshold=1
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NativeImage && equals(other, pixelValueThreshold: 1, maxAmountOfPixelsNotEqual: 0);

  @override
  int get hashCode => _data?.hashCode ?? 0;

  /// Statistics on how many times the internal data was changed with new data and cleaned up [cleanupMemory].
  /// This will not be as high as the [BaseNativeImage._imgCounter], because it does not track garbage collection of
  /// native images allocated in dart code.
  static int get cleanupCounter => BaseNativeImage._imgCleanupCounter;
}
