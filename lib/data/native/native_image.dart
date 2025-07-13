import 'dart:ffi' show Pointer, UnsignedChar, Void;
import 'package:game_tools_lib/data/native/native_window.dart' show NativeWindow;
import 'package:opencv_dart/opencv.dart' as cv;

/// Helper class to interact with opencv images with the internal [cv.Mat] in [_data] like for example [resize].
///
final class NativeImage {
  /// Reference to the native opencv mat (the reference will be updated to a copy on most change operations!)
  cv.Mat _data;

  /// This is only set when this [NativeImage] was created from native code to get an image from a window handle, etc
  /// and it will be cleaned up in [_cleanupMemory] after every action
  Pointer<UnsignedChar>? _nativeData;

  NativeImage.native({required int width, required int height, required Pointer<UnsignedChar> data})
    : this._mat(cv.Mat.fromBuffer(height, width, cv.MatType.CV_8UC4, data as Pointer<Void>), data);

  NativeImage.path({required String path}) : this._mat(cv.imread(path));

  /// Copies [mat] reference and used in other constructors
  NativeImage._mat(cv.Mat mat, [Pointer<UnsignedChar>? nativeData]) : _data = mat, _nativeData = nativeData {
    removeAlpha(); // todo: really always remove alpha?
  }

  /// Sets the image bounds to [newWidth], [newHeight] (reassigns internal data and clears old memory)
  void resize(int newWidth, int newHeight) {
    _cleanupMemory();
    _data = cv.resize(_data, (newWidth, newHeight));
  }

  /// Multiplies the image bounds by [widthFactor], [heightFactor] (reassigns internal data and clears old memory)
  void scale(double widthFactor, double heightFactor) {
    _cleanupMemory();
    _data = cv.resize(_data, (0, 0), fx: widthFactor, fy: heightFactor);
  }

  /// Removes the alpha channel (reassigns internal data and clears old memory)
  void removeAlpha() {
    if (_data.channels == 4) {
      _cleanupMemory();
      _data = cv.cvtColor(_data, cv.COLOR_BGRA2BGR);
    }
  }

  /// Frees either [_nativeData] allocated by native c/c++ code if it is not null.
  /// Or explicitly disposes [_data].
  /// Should be called internally in every method that reassigns the internal data to clear old memory!
  void _cleanupMemory() {
    if (_nativeData != null) {
      _nativeWindow.cleanupMemory(_nativeData!);
      _nativeData = null;
    } else {
      _data.dispose();
    }
  }

  /// Returns [NativeWindow.instance]
  static NativeWindow get _nativeWindow => NativeWindow.instance;
}
