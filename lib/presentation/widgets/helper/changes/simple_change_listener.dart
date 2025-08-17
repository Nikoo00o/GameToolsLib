import 'dart:async';
import 'package:flutter/material.dart';
import 'package:game_tools_lib/presentation/base/ui_helper.dart';
import 'package:game_tools_lib/presentation/widgets/helper/changes/simple_change_stream.dart';

/// Builds a listener for the ui layer that listens to changes from a [SimpleChangeStream] of the data layer.
///
/// When the [SimpleChangeStream.changeValue] of [streamToListenTo] changes, then the [builder] of this will be
/// called with the current data as a new event!
///
/// The type [T] can be any type(so lists of data are stored when navigating back and forward).
///
/// [child] will be build outside of the builders for better performance if it does not need the state!
///
/// Important: if you want to listen to individual events of a stream instead and rebuild depending on each
/// event, use [UIHelper.streamListener] instead! But also use that one instead if you want to access the same list
/// while navigating back and forward.
final class SimpleChangeListener<T> extends StatefulWidget {
  /// Rebuilds with the current [data] of the [SimpleChangeStream]
  final Widget Function(BuildContext context, T data, Widget? child) builder;

  /// The target stream for which this widget will listen to changes of its [SimpleChangeStream.changeValue]
  final SimpleChangeStream<T> streamToListenTo;

  /// Not rebuild when the data of the [SimpleChangeStream] changes!
  final Widget? child;

  const SimpleChangeListener({super.key, required this.builder, required this.streamToListenTo, this.child});

  @override
  State<SimpleChangeListener<T>> createState() => _SimpleChangeListenerState<T>();
}

final class _SimpleChangeListenerState<T> extends State<SimpleChangeListener<T>> {
  StreamSubscription<T>? subscription;
  T? currentData;

  @override
  Widget build(BuildContext context) {
    return widget.builder.call(context, currentData as T, widget.child);
  }

  @override
  void initState() {
    super.initState();
    subscription = widget.streamToListenTo.listenToEvents((T data) {
      setState(() {
        currentData = data;
      });
    });
    currentData = widget.streamToListenTo.changeValue;
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }
}
