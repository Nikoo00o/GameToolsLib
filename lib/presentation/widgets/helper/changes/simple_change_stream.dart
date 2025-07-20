import 'dart:async';

import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/widgets/helper/changes/simple_change_listener.dart';

// ignore_for_file: use_setters_to_change_properties

/// Helper mixin that can be used in your data layer to provide updates to the UI when the value [changeValue] of
/// type [Type] changes.
///
/// It will provide the current data to the ui every time it is updated by using [addEvent] automatically when you
/// set the [changeValue]. But if its a mutable object and you only change some internal data, then you have to call
/// [addEvent] manually after you are done!
///
/// The [changeValue] should always be initialized in the constructor of your subclass of this with
/// [initSimpleChangeStream] to prevent the UI listening to non initialized data!
///
/// In the UI its best to use [SimpleChangeListener] to listen to the changes from this! Just pass [simpleChangeStream]
/// to its constructor and that's it (or the object itself)!
mixin SimpleChangeStream<Type> {
  Type? _value;

  final StreamController<Type> _controller = StreamController<Type>.broadcast();

  /// Important: this must be called in the constructor of the class that is using this interface to initialize the
  /// value to something (so that it cant happen that the value is used in the ui before it is initialized)
  void initSimpleChangeStream(Type value) {
    _value = value;
  }

  Type get changeValue {
    if (_value is! Type) {
      Logger.error("SimpleChangeStream.initSimpleChangeStream was not called in constructor");
    }
    return _value as Type;
  }

  set changeValue(Type data) {
    changeValue = data;
    addEvent();
  }

  /// Useless helper method for clarity.
  SimpleChangeStream<Type> get simpleChangeStream => this;

  /// Returns a [StreamSubscription] listener for which the [callbackFunction] will be called each time a new event
  /// would be added in [addEvent] (or if the [changeValue] is set again).
  ///
  /// Important: remember to close the listener when its no longer needed!
  StreamSubscription<Type> listenToEvents(void Function(Type message) callbackFunction) {
    return _controller.stream.listen(callbackFunction);
  }

  /// Used from the classes that are using this mixin to add events internally that should update the ui!
  ///
  /// This is also automatically called when setting the [changeValue]
  void addEvent() {
    _controller.add(changeValue);
  }
}
