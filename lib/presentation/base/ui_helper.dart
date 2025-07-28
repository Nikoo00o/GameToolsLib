import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/presentation/widgets/helper/changes/simple_change_listener.dart';
import 'package:game_tools_lib/presentation/widgets/helper/changes/simple_change_notifier.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Useful helper methods for building the ui of the app.
/// For example to listen for config option changes, use [configProvider] with [configConsumer].
///
/// for other items just use [ChangeNotifierProvider] and [Selector], or [Consumer] directly). Or you can use the
/// simple wrappers [simpleProvider], [simpleConsumer] and [simpleSelector] around a value!
///
/// Or you can also listen to a stream of events with [streamListener] for the individual events, or
/// [SimpleChangeListener] with [SimpleChangeStream] if you want to update related to the whole data and get notified
/// when it changes (so lists of data are stored when navigating back and forward).
abstract final class UIHelper {
  /// Build a provider for [option]. Important: you always have to use the same [ConfigOption] subclass type
  /// that you also use in your selector here! The value is then provided to [child] further down the widget tree!
  /// Of course this can also be used inside of a [MultiProvider].
  static ChangeNotifierProvider<ConfigOption>
  configProvider<ConfigOption extends MutableConfigOption<ConfigOptionType>, ConfigOptionType>({
    required ConfigOption option,
    Key? key,
    Widget? child,
  }) => ChangeNotifierProvider<ConfigOption>.value(value: option, key: key, child: child);

  /// Build a consumer for [option] that always rebuilds when the config option notifies its listeners (the option
  /// itself is only used to determine the [ConfigOption] and [ConfigOptionType] and also the selector. also the
  /// shouldRebuild of this selector here always returns true when [onlyRebuildOnValueChange] is false, because the
  /// internal value of the config option could be set to the same reference and otherwise not trigger updates),
  /// otherwise . Important: you always have to use the same [ConfigOption] subclass type that you also use in your
  /// selector here! [child] will be build outside of [builder] for better performance if it does not need the state!
  static Selector<ConfigOption, ConfigOptionType>
  configConsumer<ConfigOption extends MutableConfigOption<ConfigOptionType>, ConfigOptionType>({
    Key? key,
    required ConfigOption option,
    required Widget Function(BuildContext context, ConfigOptionType value, Widget? child) builder,
    bool onlyRebuildOnValueChange = false,
    Widget? child,
  }) => Selector<ConfigOption, ConfigOptionType>(
    selector: (_, ConfigOption option) => option.cachedValueNotNull(),
    shouldRebuild: (ConfigOptionType newValue, ConfigOptionType? oldValue) =>
        onlyRebuildOnValueChange == false || newValue != oldValue,
    key: key,
    builder: builder,
    child: child,
  );

  /// Provides a [SimpleChangeNotifier] of [Type] like the default [ChangeNotifierProvider] to provide the value
  /// to [child] further down the widget tree! Of course this can also be used inside of a [MultiProvider].
  /// You have to create a new object of your [Type] in [createValue] which you can then modify below in the widget
  /// tree with [modifySimpleValue] (without rebuilding) and also listen to changes of it and rebuild with
  /// [simpleConsumer], or [simpleSelector].
  static SingleChildWidget simpleProvider<Type>({
    required Type Function(BuildContext context) createValue,
    Key? key,
    Widget? child,
  }) => ChangeNotifierProvider<SimpleChangeNotifier<Type>>(
    create: (BuildContext context) => SimpleChangeNotifier<Type>(createValue.call(context)),
    key: key,
    child: child,
  );

  /// This is used to modify a value of [Type] provided with [simpleProvider] higher up in the widget tree.
  /// Remember that if you stored a mutable object in [SimpleChangeNotifier.value] that you are changing without
  /// overriding the instance, you have to call [SimpleChangeNotifier.notifyListeners] after all of your changes!
  ///
  /// (you could also listen for changes if you set [listen] to true and you are not inside of a button callback,
  /// etc, but instead in a build method)
  static SimpleChangeNotifier<Type> modifySimpleValue<Type>(BuildContext context, {bool listen = false}) =>
      Provider.of(context, listen: listen);

  /// This is used to listen to changes from a value of [Type] provided higher up the widget tree with
  /// [simpleProvider], but the [child] is build outside for performance reason! Uses a [Consumer] widget.
  static Widget simpleConsumer<Type>({
    Key? key,
    required Widget Function(BuildContext context, Type value, Widget? child) builder,
    Widget? child,
  }) => Consumer<SimpleChangeNotifier<Type>>(
    key: key,
    builder: (BuildContext context, SimpleChangeNotifier<Type> value, Widget? child) =>
        builder.call(context, value.value, child),
    child: child,
  );

  /// This is similar to [simpleConsumer], but for performance reasons it can select a member of [MemberType] from
  /// the value [Type] and only rebuild when that exact member changes and that member has to be filtered with
  /// [getMemberFromValue]. Uses a [Selector] widget.
  static Widget simpleSelector<Type, MemberType>({
    Key? key,
    required MemberType Function(BuildContext context, Type value) getMemberFromValue,
    required Widget Function(BuildContext context, MemberType value, Widget? child) builder,
    Widget? child,
  }) => Selector<SimpleChangeNotifier<Type>, MemberType>(
    selector: (BuildContext context, SimpleChangeNotifier<Type> value) => getMemberFromValue.call(context, value.value),
    key: key,
    builder: builder,
    child: child,
  );

  /// Builds a listener that listens to individual event from [stream] (can by broadcast, or not) and calls
  /// [eventBuilder] that always contains the newest event to rebuild depending on it. If the stream produces an error,
  /// [errorBuilder] will be used.
  ///
  /// At first when starting to listen to a stream, the [transitionBuilder] will be called first with
  /// [ConnectionState.waiting] and also at the end when the stream has no more data with [ConnectionState.done] (and
  /// with the same last event that arrived in the [eventBuilder]). Also when switching the [stream] to another, it
  /// will be called with [ConnectionState.none] and [ConnectionState.waiting].
  ///
  /// If the other builders are [null], then in those cases only the [child] or an empty container will be returned!
  /// Except for [ConnectionState.done], here the normal [eventBuilder] would be called!
  /// [child] will be build outside of the builders for better performance if it does not need the state!
  ///
  /// If [initialEvent] is not null, then the [eventBuilder] is called instead of the [transitionBuilder] in the states
  /// [ConnectionState.waiting] and [ConnectionState.none].
  ///
  /// Important: if you want to keep a list of the events instead and rebuild depending on changes of the list, use
  /// [SimpleListListener] instead!
  ///
  /// Also important: if you want to access the same list while navigating back and forward, better use this
  /// [streamListener] here and choose the [List] as the [EventData] type and in your data layer add new events to a
  /// [StreamController] with the list reference when the list changes!
  static StreamBuilder<EventData> streamListener<EventData>({
    required Stream<EventData> stream,
    required Widget Function(BuildContext context, EventData data, Widget? child) eventBuilder,
    Widget Function(BuildContext context, Object? error, Widget? child)? errorBuilder,
    Widget Function(BuildContext context, AsyncSnapshot<EventData> state, Widget? child)? transitionBuilder,
    EventData? initialEvent,
    Widget? child,
    Key? key,
  }) => StreamBuilder<EventData>(
    key: key,
    stream: stream,
    builder: (BuildContext context, AsyncSnapshot<EventData> state) {
      if (state.hasError) {
        return errorBuilder?.call(context, state.error, child) ?? (child ?? const SizedBox());
      }
      switch (state.connectionState) {
        case ConnectionState.none:
          if (initialEvent != null) {
            return eventBuilder.call(context, initialEvent, child);
          }
          return transitionBuilder?.call(context, state, child) ?? (child ?? const SizedBox());
        case ConnectionState.waiting:
          if (initialEvent != null) {
            return eventBuilder.call(context, initialEvent, child);
          }
          return transitionBuilder?.call(context, state, child) ?? (child ?? const SizedBox());
        case ConnectionState.active:
          return eventBuilder.call(context, state.data as EventData, child);
        case ConnectionState.done:
          if (initialEvent != null) {
            return eventBuilder.call(context, initialEvent, child);
          }
          return transitionBuilder?.call(context, state, child) ??
              eventBuilder.call(context, state.data as EventData, child);
      }
    },
  );
}
