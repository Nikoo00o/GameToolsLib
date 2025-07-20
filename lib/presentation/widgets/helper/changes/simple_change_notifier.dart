import 'package:flutter/material.dart';
import 'package:game_tools_lib/presentation/base/ui_helper.dart';

/// Just wraps the [Type] with a change notifier so that [_value] can be used with [UIHelper.simpleProvider],
/// [UIHelper.simpleConsumer] and [UIHelper.simpleSelector].
/// This should mostly be used with immutable [Type]'s that are always replaced with the setter.
/// Otherwise if you store a mutable object in [_value], then you have to call [notifyListeners] manually on this
/// after your changes to update the ui!
final class SimpleChangeNotifier<Type> with ChangeNotifier {
  Type _value;

  SimpleChangeNotifier(Type value) : _value = value;

  Type get value => _value;

  set value(Type value) {
    _value = value;
    notifyListeners();
  }

  /// Same as setting [value]
  void set(Type newValue) {
    _value = newValue;
    notifyListeners();
  }
}
