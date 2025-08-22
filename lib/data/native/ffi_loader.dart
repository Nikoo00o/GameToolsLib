import 'dart:ffi';
import 'dart:io';

import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/file_utils.dart';
import 'package:game_tools_lib/game_tools_lib.dart' show Logger;

/// Used in other FFI classes to load their functions.
/// The native code is next to the lib folder in the ffi folder.
abstract final class FFILoader {
  /// important: this is the name of the library that is produced by this whole package! (set in the platform
  /// specific cmake files)
  static const String apiName = "game_tools_lib_plugin";
  static DynamicLibrary? _api;

  /// Reference to the native c / c++ code
  /// Throws an exception if the library was not found
  static DynamicLibrary get api {
    _api ??= Platform.isMacOS || Platform.isIOS
        ? DynamicLibrary.process() // macos and ios
        : (DynamicLibrary.open(apiPath));
    return _api!;
  }

  /// Path to load the library (name is different depending on the platform.
  /// Important: for testing this points to "build/test" and may throw a [TestException] if the library was
  /// not found!
  static String get apiPath {
    if (Platform.isMacOS || Platform.isIOS) {
      return "";
    }
    // windows vs linux and android
    final String name = Platform.isWindows ? "$apiName.dll" : "lib$apiName.so";
    if (Platform.environment.containsKey("FLUTTER_TEST")) {
      final String path = FileUtils.combinePath(<String>["build", "test", name]);
      if (File(path).existsSync()) {
        return path;
      } else {
        final TestException exception = TestException(
          message:
              "You have to Build the Native library manually at put it at $path (or just move "
              "the dll from starting an application like the example project there)",
        );
        Logger.error("FFILoader apiPath Error", exception, StackTrace.current);
        throw exception;
      }
    }
    return name;
  }
}
