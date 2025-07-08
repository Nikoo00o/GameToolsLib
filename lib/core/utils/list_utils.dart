import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

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
}

const DeepCollectionEquality _equality = DeepCollectionEquality();

bool _isEquatable(dynamic object) {
  return object is Equatable || object is EquatableMixin;
}
