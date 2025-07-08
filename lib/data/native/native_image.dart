import 'dart:ffi' show Pointer, UnsignedChar;
import 'package:game_tools_lib/data/native/native_window.dart' show NativeWindow;
import 'package:opencv_dart/opencv.dart' as cv;

final class NativeImage {
  /// Frees [data] allocated by native c/c++ code
  void _cleanupMemory(Pointer<UnsignedChar> data) {
    _cleanupMemory.call(data);
  }

  /// Returns [NativeWindow.instance]
  static NativeWindow get _nativeWindow => NativeWindow.instance;
}
