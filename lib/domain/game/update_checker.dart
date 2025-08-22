import 'package:game_tools_lib/core/exceptions/exceptions.dart';

// todo: implement and comment

/// If you want to use a sub class of this, then set the [instance] to an object instance of your sub class!
base class UpdateChecker {
  /// Returns the the [UpdateChecker.instance] with type [T], otherwise throws a [ConfigException]
  static T updateChecker<T extends UpdateChecker>() {
    if (instance is T) {
      return instance as T;
    } else {
      throw ConfigException(message: "Wrong type $T for $instance");
    }
  }

  /// Concrete instance of this which can be replaced with sub classes
  static UpdateChecker instance = UpdateChecker();
}
