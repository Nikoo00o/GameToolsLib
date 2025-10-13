import 'package:flutter/material.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/overlay_element.dart';
import 'package:provider/provider.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// This simply builds the [Selector]'s to access the [OverlayElement] and either call [OverlayElement.buildOverlay] or
/// [OverlayElement.buildEdit] depending on [editInsteadOfOverlay] and also depending on [OverlayElement.editable]
/// and [OverlayElement.visible]. This is only used as a helper class for the overlay element!
base class OverlayElementWidget extends StatelessWidget {
  /// If this should
  final bool editInsteadOfOverlay;

  const OverlayElementWidget({
    required this.editInsteadOfOverlay,
  });

  /// Returns Selector with either builder, or sizedbox depending on selector
  Widget buildOuterSelector(
    Widget Function(BuildContext) builder,
    bool Function(BuildContext, OverlayElement) selector,
  ) {
    return Selector<OverlayElement, bool>(
      builder: (BuildContext context, bool canBuild, Widget? child) {
        if (canBuild) {
          return builder(context);
        } else {
          return const SizedBox();
        }
      },
      selector: selector,
    );
  }

  /// Calls [OverlayElement.buildEdit] if [OverlayElement.editable]
  Widget buildEdit(BuildContext context) {
    return Consumer<OverlayElement>(
      builder: (BuildContext context, OverlayElement element, Widget? child) {
        return element.buildEdit(context);
      },
    );
  }

  /// Calls [OverlayElement.buildOverlay] if [OverlayElement.visible]
  Widget buildOverlay(BuildContext context) {
    return Consumer<OverlayElement>(
      builder: (BuildContext context, OverlayElement element, Widget? child) {
        return element.buildOverlay(context);
      },
    );
  }

  /// Nested selector and consumer for performance reasons so first outer rebuilds only if editable or visible
  /// changes depending on current overlaymode (rebuild for overlaymode happens on the outside) to either content, or
  /// sizedbox. then inner builder listens and rebuilds for all changes to the ui element
  @override
  Widget build(BuildContext context) {
    if (editInsteadOfOverlay) {
      return buildOuterSelector(buildEdit, (BuildContext context, OverlayElement element) => element.editable);
    } else {
      return buildOuterSelector(buildOverlay, (BuildContext context, OverlayElement element) => element.visible);
    }
  }
}
