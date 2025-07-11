import 'dart:typed_data' show Uint8List;

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:game_tools_lib/core/utils/num_utils.dart';

/// Provides [equals] for [List]
extension ListExtension<T> on List<T> {
  /// Always use this method if you want to compare list equality by comparing the individual elements of the list instead
  /// of the default comparison of the list references themselves! (does not compare by runtime typ and instead uses the
  /// comparison operator==)
  bool equals(List<T> other) => ListUtils.equals(this, other);
}

/// Provides list element equality comparison
abstract final class ListUtils {
  /// Always use this method if you want to compare list equality by comparing the individual elements of the list instead
  /// of the default comparison of the list references themselves! (does not compare by runtime typ and instead uses the
  /// comparison operator==)
  static bool equals(List<dynamic>? l1, List<dynamic>? l2) {
    if (identical(l1, l2)) return true;
    if (l1 == null || l2 == null || l1.length != l2.length) return false;

    for (int i = 0; i < l1.length; ++i) {
      final dynamic e1 = l1[i];
      final dynamic e2 = l2[i];

      if (l1.elementAt(i) != l2.elementAt(i)) {
        return false;
      }
      if (_isEquatable(e1) && _isEquatable(e2)) {
        if (e1 != e2) return false;
      } else if (e1 is Iterable || e1 is Map) {
        if (!_equality.equals(e1, e2)) return false;
      } else if (e1 != e2) {
        return false;
      }
    }

    return true;
  }

  /// Returns a List of [length] bytes with integer values from 0 to 255 which are cryptographically secure random numbers!
  static Uint8List getRandomBytes(int length) {
    return Uint8List.fromList(List<int>.generate(length, (int index) => NumUtils.getCryptoRandomNumber(0, 255)));
  }

  /// returns [first] + [second]
  static Uint8List combineLists(Uint8List first, Uint8List second) {
    final Uint8List result = Uint8List(first.length + second.length);
    for (int i = 0; i < first.length; i++) {
      result[i] = first[i];
    }
    for (int i = 0; i < second.length; i++) {
      result[i + first.length] = second[i];
    }
    return result;
  }

  static const DeepCollectionEquality _equality = DeepCollectionEquality();

  static bool _isEquatable(dynamic object) {
    return object is Equatable || object is EquatableMixin;
  }
}
