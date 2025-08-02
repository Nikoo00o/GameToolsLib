part of 'native_image.dart';

/// Helper class which contains private helper methods and less commonly used methods for [NativeImage].
///
/// Also provides static helper functions [iterateMat] and [iterateMatI].
sealed class BaseNativeImage {
  /// Reference to the native opencv mat (the reference will be updated to a copy on most change operations!)
  cv.Mat? _data;

  /// This is only set when this [NativeImage] was created from native code to get an image from a window handle, etc
  /// and it will be cleaned up in [cleanupMemory] after a change to the data (or otherwise from a finalizer when
  /// this object is garbage collected)
  Pointer<UnsignedChar>? _nativeData;

  /// Unique ID automatically assigned and incremented on creation (used to trace images in logs, see [toString])
  final int id;

  /// Cached: returned in [type] and changed in constructors [BaseNativeImage._base] and [changeTypeSync],
  /// [changeTypeAsync]
  NativeImageType? _type;

  /// Almost always false except for special cases on how [clone], or [NativeImage.getSubImage] are called!
  bool _isReference;

  /// Used to track images in logs
  static int _imgCounter = 0;

  /// Tracks only successful calls to [cleanupMemory] when the data was changed
  static int _imgCleanupCounter = 0;

  /// Only used for native data, because for dart data, opencv has its own finalizer
  static final Finalizer<Pointer<UnsignedChar>?> _finalizer = Finalizer<Pointer<UnsignedChar>?>(
    (Pointer<UnsignedChar>? data) => _cleanupNativeData(data, "NativeImage finalizer dispose", ++_imgCleanupCounter),
  );

  static final SpamIdentifier _createLog = SpamIdentifier();
  static final SpamIdentifier _deleteLog = SpamIdentifier();
  static final SpamIdentifier _otherLog = SpamIdentifier();

  /// Tries to adjust the current internal channel configuration to match the [newType] if its not null, otherwise
  /// this will do nothing. If it changes something, this will reassign the internal data and clears old memory.
  /// There is also a sync version [changeTypeSync].
  /// This may throw a [ImageException] if the type conversion to [newType] is not possible.
  Future<void> changeTypeAsync(NativeImageType? newType) async {
    if (newType != null && newType != NativeImageType.NONE) {
      final NativeImageType oldType = type;
      final int? method = _typeChangeMethod(oldType, newType);
      if (newType == oldType) {
        Logger.spamPeriodic(_deleteLog, "Skipping changing to same type ", newType, " for ", this);
      } else if (method == null) {
        throw ImageException(message: "Could not change type of $this to $newType");
      } else {
        cleanupMemory(await cv.cvtColorAsync(_data!, method), "type changes to ", newType);
        _type = newType;
      }
    } else {
      Logger.spamPeriodic(_deleteLog, "New Type invalid ", newType, " for ", this);
    }
  }

  /// Prefer to use [changeTypeAsync] instead.
  void changeTypeSync(NativeImageType? newType) {
    if (newType != null && newType != NativeImageType.NONE) {
      final NativeImageType oldType = type;
      final int? method = _typeChangeMethod(oldType, newType);
      if (newType == oldType) {
        Logger.spamPeriodic(_deleteLog, "Skipping changing to same type ", newType, " for ", this);
      } else if (method == null) {
        throw ImageException(message: "Could not change type of $this to $newType");
      } else {
        cleanupMemory(cv.cvtColor(_data!, method), "type changes to ", newType);
        _type = newType;
      }
    } else {
      Logger.spamPeriodic(_deleteLog, "New Type invalid ", newType, " for ", this);
    }
  }

  /// Frees either [_nativeData] allocated by native c/c++ code if it is not null.
  /// Or explicitly disposes [_data].
  /// Should be called internally in every method that reassigns the internal data to clear old memory. or at the end
  /// of the lifetime of the object! If this was created from a native buffer, then there will also be a finalizer
  /// that will call this automatically!
  /// Optionally pass [newData] if you want to change the internal data after (otherwise [_data] will be set to null).
  /// This will spam the log and [logInfo], [l2], [l3] can contain additional info from where it was called.
  ///
  /// This may throw an [ImageException] if [newData] is the same reference as [_data] (and not null).
  void cleanupMemory([cv.Mat? newData, String? logInfo, Object? l2]) {
    if (newData != null && identical(newData, _data)) {
      throw ImageException(message: "Cleanup called with the same data in $this");
    }
    if (_nativeData != null) {
      _cleanupNativeData(_nativeData, "Cleanup native ", ++_imgCleanupCounter, this, " for ", logInfo, l2);
      _nativeData = null;
      _finalizer.detach(this);
    } else if (_data != null) {
      if (_isReference) {
        Logger.spamPeriodic(_deleteLog, "Cleanup reference ", this, " for ", logInfo, l2);
        _isReference = false;
      } else {
        Logger.spamPeriodic(_deleteLog, "Cleanup ", ++_imgCleanupCounter, this, " for ", logInfo, l2);
        try {
          _data!.dispose();
        } catch (e, s) {
          Logger.warn("Failed Cleanup $_imgCleanupCounter $this for $logInfo $l2", e, s); // never throw here
        }
      }
    } else {
      Logger.spamPeriodic(_deleteLog, "Cleanup no data from ", this, " for ", logInfo, l2);
    }
    _data = newData;
  }

  /// Returns true if the [_data] was successfully stored in [path]
  bool saveSync(String path) {
    if (_data != null) {
      Logger.verbose("Saving $this to path $path");
      return cv.imwrite(path, _data!);
    }
    return false;
  }

  /// Creates a deep copy of the data of this.
  /// Throws an [ImageException] if [_data] is null.
  /// If [onlyAsReference] is true, this will only copy the pointer reference and not copy the data itself!
  /// This is used internally when a copy has to be made which is modified afterwards (then the internal reference
  /// flag is unset)
  Future<NativeImage> clone({bool onlyAsReference = false}) async {
    if (_data == null || type == NativeImageType.NONE) {
      throw ImageException(message: "Cannot clone null from $this");
    }
    if (onlyAsReference) {
      final NativeImage img = NativeImage._mat(_data!, typeOverride: type);
      img._isReference = true;
      return img;
    }
    return NativeImage._mat(await _data!.cloneAsync(), typeOverride: type);
  }

  /// If you want to modify, or access the internal opencv mat directly (should rarely be needed)
  cv.Mat? getRawData() => _data;

  /// Converts the data of this into a dart [Image] which can be displayed in the ui! Throws [ImageException] if
  /// null! That image can now be displayed in a [RawImage] flutter widget, but after it is no longer needed, you
  /// should call [Image.dispose] on it.
  Future<Image> getDartImage() async {
    if (_data == null || type == NativeImageType.NONE) {
      throw ImageException(message: "Cannot show empty flutter image $this");
    }
    final NativeImage rgba = await clone(onlyAsReference: true);
    await rgba.changeTypeAsync(NativeImageType.RGBA);
    Image? image;
    decodeImageFromPixels(rgba._data!.data, width, height, PixelFormat.bgra8888, (Image result) {
      image = result;
    });
    for (int i = 0; i < 200; ++i) {
      await Future<void>.delayed(const Duration(milliseconds: 4));
      if (image != null) {
        break;
      }
    }
    if (image == null) {
      throw ImageException(message: "Could not convert image $this to flutter image");
    }
    return image!;
  }

  /// If [_data] is null, this returns 0. this would be the columns of the mat
  int get width => _data?.width ?? 0;

  /// If [_data] is null, this returns 0. this would be the rows of the mat
  int get height => _data?.height ?? 0;

  /// If this contains no data (width or height are 0), or if [type] is [NativeImageType.NONE]
  bool get isEmpty => type == NativeImageType.NONE || width == 0 || height == 0;

  /// The matching [NativeImageType] for the channels of this (or [NativeImageType.NONE] if null/invalid.
  /// This could not detect special color spaces with the same amount of channels as the default ones and therefor it
  /// is cached in the constructor call and only changed in [changeTypeSync] and [changeTypeAsync]!
  NativeImageType get type => _type ?? NativeImageType.NONE;

  @override
  String toString() => "NativeImage($id, $type)";

  /// Only takes [mat] reference and optionally [nativeData]. Used in other constructors.
  /// If [typeOverride] is not null, then the type will be derived from the [mat.channels] (but this is not possible
  /// for [clone])
  BaseNativeImage._base(cv.Mat mat, {required Pointer<UnsignedChar>? nativeData, NativeImageType? typeOverride})
    : _data = mat,
      _nativeData = nativeData,
      id = _imgCounter++,
      _type = typeOverride ?? NativeImageType.fromChannels(mat.channels),
      _isReference = false;

  /// Will be [NativeImageType.RGBA] per default with internal native data
  static NativeImage _loadNative(int width, int height, Pointer<UnsignedChar> data, int? logXPos, int? logYPos) {
    final NativeImage img = NativeImage._mat(
      cv.Mat.fromBuffer(height, width, cv.MatType.CV_8UC4, data as Pointer<Void>),
      nativeData: data,
    );
    Logger.spamPeriodic(_createLog, "Loaded ", img, " from native data at winPos (", logXPos, ", ", logYPos, ")");
    return img;
  }

  /// Throws exception if path does not exist
  static int _loadFileType(String path, NativeImageType type) {
    if (FileUtils.fileExists(path) == false || type == NativeImageType.NONE) {
      throw ImageException(message: "Could not load NativeImage from $path with type $type");
    }
    return switch (type) {
      NativeImageType.GRAY => cv.IMREAD_GRAYSCALE,
      NativeImageType.RGB => cv.IMREAD_COLOR,

      /// don't load alpha when trying to read something as hsv (because it can only be converted from rgb)
      NativeImageType.HSV => cv.IMREAD_COLOR,
      _ => cv.IMREAD_UNCHANGED,
    };
  }

  /// Returns null if any of the types is null, or NONE, but also if the types are the same.
  /// Otherwise returns the opencv color conversion code
  static int? _typeChangeMethod(NativeImageType? oldType, NativeImageType newType) => switch (oldType) {
    NativeImageType.GRAY => switch (newType) {
      NativeImageType.RGB => cv.COLOR_GRAY2BGR,
      NativeImageType.RGBA => cv.COLOR_GRAY2BGRA,
      _ => null,
    },
    NativeImageType.RGB => switch (newType) {
      NativeImageType.GRAY => cv.COLOR_BGR2GRAY,
      NativeImageType.RGBA => cv.COLOR_BGR2BGRA,
      NativeImageType.HSV => cv.COLOR_BGR2HSV,
      _ => null,
    },
    NativeImageType.RGBA => switch (newType) {
      NativeImageType.GRAY => cv.COLOR_BGRA2GRAY,
      NativeImageType.RGB => cv.COLOR_BGRA2BGR,
      NativeImageType.HSV => cv.COLOR_BGR2HSV,
      _ => null,
    },
    NativeImageType.HSV => switch (newType) {
      NativeImageType.RGB => cv.COLOR_HSV2BGR,
      _ => null,
    },
    _ => null,
  };

  /// Manually disposes the [nativeData]. [l2] and onwards may contain additional log parts
  static void _cleanupNativeData(
    Pointer<UnsignedChar>? nativeData,
    String logMessage, [
    Object? l2,
    Object? l3,
    Object? l4,
    Object? l5,
    Object? l6,
  ]) {
    if (nativeData != null) {
      Logger.spamPeriodic(_deleteLog, logMessage, l2, l3, l4, l5, l6);
      try {
        _nativeWindow.cleanupMemory(nativeData);
      } catch (e, s) {
        Logger.warn("Failed $logMessage $l2 $l3 $l4 $l5 $l6: ", e, s); // never throw here
      }
    }
  }

  static void _attachToFinalizer(NativeImage img) {
    if (img._nativeData != null) {
      _finalizer.attach(img, img._nativeData, detach: img);
    }
  }

  static Color? _pixelToColor(List<num> pixel) {
    if (pixel.length == 3) {
      return Color.fromARGB(255, pixel[2].round(), pixel[1].round(), pixel[0].round()); // BGR
    } else if (pixel.length == 4) {
      return Color.fromARGB(pixel[3].round(), pixel[2].round(), pixel[1].round(), pixel[0].round()); // BGRA
    } else if (pixel.length == 1) {
      return Color(pixel[0].round()); //GRAY
    }
    return null;
  }

  /// The [callback] will be called for every value stored in the [mat] and if the callback does not return null, then
  /// that returned value will instantly be returned cancelling any further calls to the callback.
  /// Otherwise as long as [callback] returns only null, at the end of this function null will be returned after
  /// callback was called with every value.
  /// [T] is the returned type that you want to work with and [MatDataType] is the type stored in the [mat] (depends
  /// on the channel (for example [cv.Vec4b])
  static T? iterateMat<T, MatDataType>(cv.Mat mat, T? Function(MatDataType val) callback) {
    for (int r = 0; r < mat.height; ++r) {
      for (int c = 0; c < mat.width; ++c) {
        final MatDataType val = mat.at<MatDataType>(r, c);
        final T? ret = callback.call(val);
        if (ret != null) {
          return ret;
        }
      }
    }
    return null;
  }

  /// Same as [iterateMat], but with indices. [r] for the row (height, accessed first!) and [c] for the column(width).
  static T? iterateMatI<T>(cv.Mat mat, T? Function(int r, int c) callback) {
    for (int r = 0; r < mat.height; ++r) {
      for (int c = 0; c < mat.width; ++c) {
        final T? ret = callback.call(r, c);
        if (ret != null) {
          return ret;
        }
      }
    }
    return null;
  }

  /// Returns true if both mats (see dimensions) are empty, but false if only one is empty!
  ///
  /// The [compareCallback] will be called to access every value of the overlap of both mats (min size) to get the
  /// pixel difference. If the value change is higher than [pixelValueThreshold], then an internal counter is increased.
  /// If that counter reaches higher than [maxAmountOfPixelsNotEqual], then this returns false.
  ///
  /// Otherwise this returns true after calling the callback for each value.
  static bool _compareValsOfMats({
    required int width1,
    required int height1,
    required int width2,
    required int height2,
    required int pixelValueThreshold,
    required int maxAmountOfPixelsNotEqual,
    required int Function(int r, int c) compareCallback,
  }) {
    if (width1 < 0 || width2 <= 0 || height1 <= 0 || height2 <= 0) {
      // one side is empty and the other is not
      return (width1 >= 0 || width2 >= 0 || height1 >= 0 || height2 >= 0) == false;
    }
    final int rMin = min(height1, height2); // height = row = access first
    final int cMin = min(width1, width2); // width = col = last
    int pixelsChanged = 0;
    for (int r = 0; r < rMin; ++r) {
      for (int c = 0; c < cMin; ++c) {
        final int change = compareCallback.call(r, c);
        if (change > pixelValueThreshold) {
          if (++pixelsChanged > maxAmountOfPixelsNotEqual) {
            return false;
          }
        }
      }
    }
    return true;
  }

  /// returns a function to return the pixel change between [i1] and [i2] with the minimum amount of channel (gray
  /// only against itself, but rgb and rgba will only compare 3 values. and rgba can also only compare 3 values if
  /// [ignoreAlpha] is true).
  /// Returns null if a change would not be able to calculate, for example gray against any other type.
  static int Function(int r, int c)? _minPixChange({
    required NativeImage i1,
    required NativeImage i2,
    required bool ignoreAlpha,
  }) {
    return switch (i1.type.channels) {
      1 => switch (i2.type.channels) {
        1 => (int r, int c) {
          final int pix1 = i1._data!.at<int>(r, c);
          final int pix2 = i2._data!.at<int>(r, c);
          return pix2.diff(pix1);
        },
        _ => null,
      },
      3 => switch (i2.type.channels) {
        3 => (int r, int c) {
          final cv.Vec3b pix1 = i1._data!.at<cv.Vec3b>(r, c);
          final cv.Vec3b pix2 = i2._data!.at<cv.Vec3b>(r, c);
          return pix2.val1.diff(pix1.val1) + pix2.val2.diff(pix1.val2) + pix2.val3.diff(pix1.val3);
        },
        4 => (int r, int c) {
          final cv.Vec3b pix1 = i1._data!.at<cv.Vec3b>(r, c);
          final cv.Vec4b pix2 = i2._data!.at<cv.Vec4b>(r, c);
          return pix2.val1.diff(pix1.val1) + pix2.val2.diff(pix1.val2) + pix2.val3.diff(pix1.val3);
        },
        _ => null,
      },
      4 => switch (i2.type.channels) {
        3 => (int r, int c) {
          final cv.Vec4b pix1 = i1._data!.at<cv.Vec4b>(r, c);
          final cv.Vec3b pix2 = i2._data!.at<cv.Vec3b>(r, c);
          return pix2.val1.diff(pix1.val1) + pix2.val2.diff(pix1.val2) + pix2.val3.diff(pix1.val3);
        },
        4 =>
          ignoreAlpha
              ? (int r, int c) {
                  final cv.Vec4b pix1 = i1._data!.at<cv.Vec4b>(r, c);
                  final cv.Vec4b pix2 = i2._data!.at<cv.Vec4b>(r, c);
                  return pix2.val1.diff(pix1.val1) + pix2.val2.diff(pix1.val2) + pix2.val3.diff(pix1.val3);
                }
              : (int r, int c) {
                  final cv.Vec4b pix1 = i1._data!.at<cv.Vec4b>(r, c);
                  final cv.Vec4b pix2 = i2._data!.at<cv.Vec4b>(r, c);
                  return pix2.val1.diff(pix1.val1) +
                      pix2.val2.diff(pix1.val2) +
                      pix2.val3.diff(pix1.val3) +
                      pix2.val4.diff(pix1.val4);
                },
        _ => null,
      },
      _ => null,
    };
  }

  /// This will return a pair of matrices of the same size.
  /// This may return references to [a] and [b], or clone and resize them!
  static Future<(NativeImage, NativeImage)> makeSameSize(NativeImage a, NativeImage b) async {
    final int aw = a.width;
    final int ah = a.height;
    final int bw = b.width;
    final int bh = b.height;
    final int targetWidth = max(aw, bw);
    final int targetHeight = max(ah, bh);
    NativeImage i1 = a;
    NativeImage i2 = b;
    if (aw < targetWidth || ah < targetHeight) {
      i1 = await a.clone(onlyAsReference: true);
      await i1.resize(targetWidth, targetHeight);
    }
    if (bw < targetWidth || bh < targetHeight) {
      i2 = await b.clone(onlyAsReference: true);
      await i2.resize(targetWidth, targetHeight);
    }
    return (i1, i2);
  }

  /// h_bins and s_bins histogram arguments (all below here are late lazy initialized when accessed!)
  static final cv.VecI32 _histSize = cv.VecI32.fromList(const <int>[50, 60]);

  /// use hue and satu for histogram
  static final cv.VecI32 _channels = cv.VecI32.fromList(const <int>[0, 1]);

  /// hue varies from 0 to 179 and satu 0 to 255 for histogram
  static final cv.VecF32 _ranges = cv.VecF32.fromList(const <double>[0, 180, 0, 256]);

  /// Returns histogram for this. Can throw if [NativeImageType.GRAY]
  Future<cv.Mat> _getHistogram() async {
    final NativeImage hsv = await clone(onlyAsReference: true);
    await hsv.changeTypeAsync(NativeImageType.HSV);
    final cv.Mat hist = await cv.calcHistAsync(
      cv.VecMat.fromList(<cv.Mat>[hsv._data!]),
      _channels,
      cv.Mat.empty(),
      _histSize,
      _ranges,
    );
    return cv.normalizeAsync(hist, hist, alpha: 0, beta: 1, normType: cv.NORM_MINMAX, dtype: -1, mask: cv.Mat.empty());
  }

  /// Returns [NativeWindow.instance]
  static NativeWindow get _nativeWindow => NativeWindow.instance;
}

class TestMockNativeImageWrapper {
  final NativeImage img;

  const TestMockNativeImageWrapper(this.img);

  Pointer<UnsignedChar>? get native => img._nativeData;
}
