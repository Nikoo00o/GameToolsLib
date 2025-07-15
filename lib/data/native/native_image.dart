import 'dart:ffi' show Pointer, UnsignedChar, Void;
import 'dart:math' show min;
import 'dart:ui' show Color;
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/file_utils.dart';
import 'package:game_tools_lib/data/game/game_window.dart';
import 'package:game_tools_lib/data/native/native_window.dart' show NativeWindow;
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:opencv_dart/opencv.dart' as cv;

/// Helper class to interact with opencv images with the internal [cv.Mat] in [_data] like for example [resize].
///
/// Use either [NativeImage.nativeSync], [NativeImage.nativeAsync] (used in [GameWindow]), [NativeImage.readSync], or
/// [readAsync] to create an instance of this. And you can also use [saveSync], or [saveAsync] to save this to the disk.
///
/// Important: always try to use async methods instead of sync methods! And mostly images used here have no alpha
/// channel (and [removeAlphaAsync] is used for most constructors).
final class NativeImage {
  /// Reference to the native opencv mat (the reference will be updated to a copy on most change operations!)
  cv.Mat? _data;

  /// This is only set when this [NativeImage] was created from native code to get an image from a window handle, etc
  /// and it will be cleaned up in [cleanupMemory] after a change to the data (or otherwise from a finalizer when
  /// this object is garbage collected)
  Pointer<UnsignedChar>? _nativeData;

  /// Unique ID automatically assigned and incremented on creation (used to trace images in logs, see [toString])
  final int id;

  /// Used for pixel comparison how high the total R, G, B value difference may be until a pixel is counted as invalid
  static int defaultPixelRGBThreshold = 75;

  /// Used for pixel comparison how many invalid pixel would still return true
  static int defaultMaxAmountOfPixelsNotEqual = 40;

  /// Used to track images in logs
  static int _imgCounter = 0;

  /// Only used for native data, because for dart data, opencv has its own finalizer
  static final Finalizer<Pointer<UnsignedChar>?> _finalizer = Finalizer<Pointer<UnsignedChar>?>(
    (Pointer<UnsignedChar>? data) => NativeImage._cleanupNativeData(data, "NativeImage data cleanup by finalizer"),
  );

  static final SpamIdentifier _createLog = SpamIdentifier();
  static final SpamIdentifier _deleteLog = SpamIdentifier();
  static final SpamIdentifier _otherLog = SpamIdentifier();

  /// Creates an image from [data] as a buffer allocated in native c/c++ code with [width] and [height].
  /// Per default [removeAlpha] is true to remove the alpha channel, because its not used for comparison.
  factory NativeImage.nativeSync({
    required int width,
    required int height,
    required Pointer<UnsignedChar> data,
    bool removeAlpha = true,
    int? logXPos,
    int? logYPos,
  }) {
    final NativeImage img = NativeImage._mat(
      cv.Mat.fromBuffer(height, width, cv.MatType.CV_8UC4, data as Pointer<Void>),
      nativeData: data,
      removeAlpha: removeAlpha,
    );
    Logger.spamPeriodic(_createLog, "Loaded ", img, " from native data at winPos (", logXPos, ", ", logYPos, ")");
    if (img._nativeData != null) {
      _finalizer.attach(img, img._nativeData, detach: img);
    }
    return img;
  }

  /// Creates an image from [data] as a buffer allocated in native c/c++ code with [width] and [height].
  /// Per default [removeAlpha] is true to remove the alpha channel, because its not used for comparison.
  static Future<NativeImage> nativeAsync({
    required int width,
    required int height,
    required Pointer<UnsignedChar> data,
    bool removeAlpha = true,
    int? logXPos,
    int? logYPos,
  }) async {
    final NativeImage img = NativeImage._mat(
      cv.Mat.fromBuffer(height, width, cv.MatType.CV_8UC4, data as Pointer<Void>),
      nativeData: data,
      removeAlpha: false,
    );
    Logger.spamPeriodic(_createLog, "Loaded ", img, " from native data at winPos (", logXPos, ", ", logYPos, ")");
    if (removeAlpha) {
      await img.removeAlphaAsync();
    }
    if (img._nativeData != null) {
      _finalizer.attach(img, img._nativeData, detach: img);
    }
    return img;
  }

  /// Copies [mat] reference and used in other constructors and removes alpha channel depending on [removeAlpha]
  NativeImage._mat(cv.Mat mat, {required bool removeAlpha, Pointer<UnsignedChar>? nativeData})
    : _data = mat,
      _nativeData = nativeData,
      id = _imgCounter++ {
    if (removeAlpha) {
      removeAlphaSync();
    }
  }

  /// Creates an image by reading it from a [path] and otherwise throws a [FileNotFoundException] exception.
  /// Per default [removeAlpha] is true to remove the alpha channel, because its not used for comparison.
  factory NativeImage.readSync({required String path, bool removeAlpha = true}) {
    if (path.isNotEmpty && FileUtils.fileExists(path)) {
      final NativeImage img = NativeImage._mat(cv.imread(path), removeAlpha: removeAlpha);
      Logger.verbose("Loaded $img from path $path");
      return img;
    } else {
      throw FileNotFoundException(message: "Could not load NativeImage from $path");
    }
  }

  /// Creates an image by reading it from a [path] and otherwise throws a [FileNotFoundException] exception.
  /// Per default [removeAlpha] is true to remove the alpha channel, because its not used for comparison.
  static Future<NativeImage> readAsync({required String path, bool removeAlpha = true}) async {
    if (path.isNotEmpty && FileUtils.fileExists(path)) {
      final NativeImage img = NativeImage._mat(await cv.imreadAsync(path), removeAlpha: false);
      if (removeAlpha) {
        await img.removeAlphaAsync();
      }
      Logger.verbose("Loaded $img from path $path");
      return img;
    } else {
      throw FileNotFoundException(message: "Could not load NativeImage from $path");
    }
  }

  /// Returns true if the [_data] was successfully stored in [path]
  bool saveSync(String path) {
    if (_data != null) {
      Logger.verbose("Saving $this to path $path");
      return cv.imwrite(path, _data!);
    }
    return false;
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
      if (pixelValues.length == 3) {
        color = Color.fromARGB(255, pixelValues[2].toInt(), pixelValues[1].toInt(), pixelValues[0].toInt());
      } else if (pixelValues.length == 4) {
        color = Color.fromARGB(
          pixelValues[4].toInt(),
          pixelValues[2].toInt(),
          pixelValues[1].toInt(),
          pixelValues[0].toInt(),
        );
      }
    }
    Logger.spamPeriodic(_otherLog, "color at pixel(", x, ", ", y, ") is: ", color);
    return color;
  }

  /// Pixel per pixel comparison for equality of two images.
  /// [pixelRGBThreshold] represents how high the total R, G, B value difference for each pixel may be until a pixel
  /// is counted as invalid. If its null, then it will use [defaultPixelRGBThreshold]
  /// [maxAmountOfPixelsNotEqual] represents how many pixel may be counted as invalid for this to still return true.
  /// If its null, then it will use [defaultMaxAmountOfPixelsNotEqual].
  /// Alpha is only compared if both images have an alpha channel.
  bool equals(NativeImage other, {int? pixelRGBThreshold, int? maxAmountOfPixelsNotEqual}) {
    pixelRGBThreshold ??= defaultPixelRGBThreshold;
    maxAmountOfPixelsNotEqual ??= defaultMaxAmountOfPixelsNotEqual;
    final int myWidth = width; // width is cols
    final int otherWidth = other.width;
    final int myHeight = height; // height is rows
    final int otherHeight = other.height;
    if (myWidth == 0 || otherWidth == 0 || myHeight == 0 || otherHeight == 0) {
      // one image could also be empty and the other not
      return (myWidth != 0 || otherWidth != 0 || myHeight != 0 || otherHeight != 0) == false;
    }
    int pixelsChanged = 0;
    final int rMin = min(myHeight, otherHeight);
    final int cMin = min(myWidth, otherWidth);
    for (int r = 0; r < rMin; ++r) {
      for (int c = 0; c < cMin; ++c) {
        late int change;
        if (_data?.channels == 4 && other._data?.channels == 4) {
          final cv.Vec4b pix1 = other._data!.at<cv.Vec4b>(r, c);
          final cv.Vec4b pix2 = _data!.at<cv.Vec4b>(r, c);
          change = (pix1.val1 - pix2.val1).abs() + (pix1.val2 - pix2.val2).abs() + (pix1.val3 - pix2.val3).abs();
          change += (pix1.val4 - pix2.val4).abs();
        } else {
          final cv.Vec3b pix1 = other._data!.at<cv.Vec3b>(r, c);
          final cv.Vec3b pix2 = _data!.at<cv.Vec3b>(r, c);
          change = (pix1.val1 - pix2.val1).abs() + (pix1.val2 - pix2.val2).abs() + (pix1.val3 - pix2.val3).abs();
        }
        if (change > pixelRGBThreshold) {
          Logger.info("CHANGED $change more than $pixelRGBThreshold");
          ++pixelsChanged;
        }
        if (pixelsChanged > maxAmountOfPixelsNotEqual) {
          return false;
        }
      }
    }
    return true;
  }

  /// 100% equality, calls [equals] with pixelRGBThreshold=0 and maxAmountOfPixelsNotEqual=0.
  /// Alpha is only compared if both images have an alpha channel
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NativeImage && equals(other, pixelRGBThreshold: 0, maxAmountOfPixelsNotEqual: 0);

  @override
  int get hashCode => _data.hashCode;

  /// Sets the image bounds to [newWidth], [newHeight] (reassigns internal data and clears old memory)
  Future<void> resize(int newWidth, int newHeight) async {
    if (_data != null && !isEmpty) {
      cleanupMemory(await cv.resizeAsync(_data!, (newWidth, newHeight)), "resize to $newWidth, $newHeight");
    } else {
      Logger.warn("resize called with $newWidth, $newHeight for an empty image $this");
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
  Future<NativeImage> getSubImage(int x, int y, int width, int height, {bool onlyReference = false}) async {
    if (_data != null &&
        width > 0 &&
        height > 0 &&
        x >= 0 &&
        y >= 0 &&
        x + width <= this.width &&
        y + height <= this.height) {
      final cv.Mat mat = cv.Mat.fromMat(_data!, copy: onlyReference == false, roi: cv.Rect(x, y, width, height));
      return NativeImage._mat(mat, removeAlpha: false);
    } else {
      throw ImageException(message: "cant get SubImage from $this at $x, $y, $width, $height");
    }
  }

  /// Removes the alpha channel (reassigns internal data and clears old memory).
  /// There is also an async version [removeAlphaAsync]
  void removeAlphaSync() {
    if (_data?.channels == 4 && isEmpty == false) {
      cleanupMemory(cv.cvtColor(_data!, cv.COLOR_BGRA2BGR), "remove alpha");
    }
  }

  /// Same as [removeAlphaSync]
  Future<void> removeAlphaAsync() async {
    if (_data?.channels == 4 && isEmpty == false) {
      cleanupMemory(await cv.cvtColorAsync(_data!, cv.COLOR_BGRA2BGR), "remove alpha");
    }
  }

  /// Frees either [_nativeData] allocated by native c/c++ code if it is not null.
  /// Or explicitly disposes [_data].
  /// Should be called internally in every method that reassigns the internal data to clear old memory. or at the end
  /// of the lifetime of the object! If this was created from a native buffer, then there will also be a finalizer
  /// that will call this automatically!
  /// Optionally pass [newData] if you want to change the internal data
  /// This will spam the log and [logInfo] can contain additional info from where it was called
  void cleanupMemory([cv.Mat? newData, String? logInfo]) {
    if (_nativeData != null) {
      _cleanupNativeData(_nativeData, "Cleaning up native allocated ", this, " for ", logInfo);
      _nativeData = null;
      _finalizer.detach(this);
    } else if (_data != null) {
      Logger.spamPeriodic(_deleteLog, "Cleaning up ", this, " for ", logInfo);
      _data!.dispose();
    } else {
      Logger.spamPeriodic(_deleteLog, "Cleanup no data from ", this, " for ", logInfo);
    }
    _data = newData;
  }

  /// [l2] and onwards may contain additional log parts
  static void _cleanupNativeData(
    Pointer<UnsignedChar>? nativeData,
    String logMessage, [
    Object? l2,
    Object? l3,
    Object? l4,
  ]) {
    if (nativeData != null) {
      Logger.spamPeriodic(_deleteLog, logMessage, l2, l3, l4);
      _nativeWindow.cleanupMemory(nativeData);
    }
  }

  /// If [_data] is null, this returns 0. this would be the columns of the mat
  int get width => _data?.width ?? 0;

  /// If [_data] is null, this returns 0. this would be the rows of the mat
  int get height => _data?.height ?? 0;

  /// If this contains no data (width or height are 0)
  bool get isEmpty => width == 0 || height == 0;

  @override
  String toString() => "NativeImage($id)";

  /// Returns [NativeWindow.instance]
  static NativeWindow get _nativeWindow => NativeWindow.instance;
}
