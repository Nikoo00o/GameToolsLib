import 'package:game_tools_lib/data/native/native_image.dart';

/// The base Exception class which holds a message to display
abstract base class BaseException implements Exception {
  /// Error Description
  final String? message;

  /// Optional message parameter for the [message] printed in another line
  final List<Object>? messageParams;

  const BaseException({required this.message, this.messageParams = const <Object>[]});

  @override
  String toString() {
    if (messageParams == null || messageParams!.isEmpty) {
      return "$runtimeType: $message";
    }
    return "$runtimeType: $message\nException Data:$messageParams";
  }
}

/// The target window was not open
final class WindowClosedException extends BaseException {
  const WindowClosedException({required super.message, super.messageParams});
}

/// The target window was not open
final class ConfigException extends BaseException {
  const ConfigException({required super.message, super.messageParams});
}

/// A target file was not found
final class FileNotFoundException extends BaseException {
  const FileNotFoundException({required super.message, super.messageParams});
}

/// Keycode for a key was not found
final class KeyNotFoundException extends BaseException {
  const KeyNotFoundException({required super.message, super.messageParams});
}

/// Different use cases for [NativeImage]
final class ImageException extends BaseException {
  const ImageException({required super.message, super.messageParams});
}

/// An exception only important for testing
final class TestException extends BaseException {
  const TestException({required super.message, super.messageParams});
}
