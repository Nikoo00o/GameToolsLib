import 'dart:async';

import 'package:game_tools_lib/core/utils/file_utils.dart';
import 'package:game_tools_lib/core/utils/list_utils.dart';
import 'package:game_tools_lib/core/utils/num_utils.dart';
import 'package:game_tools_lib/core/utils/string_utils.dart';
export 'bounds.dart';
export 'file_utils.dart';
export 'immutable_equatable.dart';
export 'list_utils.dart';
export 'nullable.dart';
export 'num_utils.dart';
export 'string_utils.dart';

/// Contains general Utils functions like [executePeriodic].
/// For specific Utils look into [NumUtils], [StringUtils], [ListUtils], [FileUtils].
abstract final class Utils {
  /// if the value is not set, then its the timestamp when the callback may be executed again
  static final Map<FutureOr<void> Function(), DateTime?> _executors = <FutureOr<void> Function(), DateTime?>{};

  /// This is a guard used for asserts in debug mode to check if you used [executePeriodicAsync] with unnamed lambda
  /// functions and have more unique [_executors] than this number (for some unknown edge cases, you may change this).
  static int maxExecutorCountGuard = 9999;

  /// Should be called from inside an (async) loop and will not loop, or block itself!
  /// This acts as a guard to only call [callback] after every [delay].
  /// The [callback] function reference/pointer should be unique across all sources that call this.
  ///
  /// IMPORTANT: you have to create the function pointer for [callback] outside of your loop and you MAY NOT use an
  /// unnamed lambda function!!!!!!!! As a guard an assert is thrown in debug mode if there are more unique [_executors]
  /// callbacks added than [maxExecutorCountGuard].
  /// Example:
  /// ```dart
  ///     int counter = 0;
  ///     void callback() { counter -= 1; }
  ///     while(true) { Utils.executePeriodicSync(delay: Duration(milliseconds: 10), callback: callback); }
  /// ```
  static Future<void> executePeriodicAsync({required Duration delay, required Future<void> Function() callback}) async {
    final DateTime now = DateTime.now();
    final DateTime? blockUntil = _executors[callback];
    if (blockUntil != null) {
      if (now.isBefore(blockUntil)) {
        return;
      }
    }
    _executors[callback] = now.add(delay);
    assert(_executors.keys.length < maxExecutorCountGuard);
    await callback.call();
  }

  /// Should be called from inside a (sync) loop and will not loop, or block itself!
  /// This acts as a guard to only call [callback] after every [delay].
  /// The [callback] function reference/pointer should be unique across all sources that call this.
  ///
  /// IMPORTANT: you have to create the function pointer for [callback] outside of your loop and you MAY NOT use an
  /// unnamed lambda function!!!!!!!! As a guard an assert is thrown in debug mode if there are more unique [_executors]
  /// callbacks added than [maxExecutorCountGuard].
  /// Example:
  /// ```dart
  ///     int counter = 0;
  ///     void callback() { counter -= 1; }
  ///     while(true) { Utils.executePeriodicSync(delay: Duration(milliseconds: 10), callback: callback); }
  /// ```
  static void executePeriodicSync({required Duration delay, required void Function() callback}) {
    final DateTime now = DateTime.now();
    final DateTime? blockUntil = _executors[callback];
    if (blockUntil != null) {
      if (now.isBefore(blockUntil)) {
        return;
      }
    }
    _executors[callback] = now.add(delay);
    assert(_executors.keys.length < maxExecutorCountGuard);
    callback.call();
  }

  /// Just shorter syntax than Future<void>.delayed
  static Future<void> delay(Duration delay) async => Future<void>.delayed(delay);
}
