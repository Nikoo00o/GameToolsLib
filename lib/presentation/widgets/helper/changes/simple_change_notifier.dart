import 'package:flutter/material.dart';
import 'package:game_tools_lib/presentation/base/ui_helper.dart';
import 'package:provider/provider.dart';

/// Just wraps the type [T] with a change notifier so that [_value] can be used with [UIHelper.simpleProvider],
/// [UIHelper.simpleConsumer] and [UIHelper.simpleSelector].
/// This should mostly be used with immutable [T]'s that are always replaced with the setter.
/// Otherwise if you store a mutable object in [_value], then you have to call [notifyListeners] manually on this
/// after your changes to update the ui!
///
/// You can directly use this with any type for [T], but of course you can also extend from this if you want to
/// provide the same type multiple times and want a named type that you can use in your providers/consumers (but in
/// this case you can not use those simple helper methods from [UIHelper] and instead need to use [ChangeNotifierProvider])!
///
/// This also overrides the [hashCode] and [operator==] to just compare [value] and [runtimeType]
base class SimpleChangeNotifier<T> with ChangeNotifier {
  T _value;

  SimpleChangeNotifier(T value) : _value = value;

  T get value => _value;

  set value(T value) {
    _value = value;
    notifyListeners();
  }

  /// Same as setting [value]
  void set(T newValue) {
    _value = newValue;
    notifyListeners();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimpleChangeNotifier<T> && runtimeType == other.runtimeType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => "$runtimeType($_value)";
}
