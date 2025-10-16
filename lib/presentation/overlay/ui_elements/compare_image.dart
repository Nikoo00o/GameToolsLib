import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/bounds.dart';
import 'package:game_tools_lib/core/utils/scaled_bounds.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/helper/editable_builder.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/overlay_element.dart';

/// The [buildOverlay] method does nothing here!
///
/// Important: [clickable] will always be false for this!
base class CompareImage extends OverlayElement {
  /// Factory constructor that will cache and reuse instances for [identifier] and should always be used from the
  /// outside! Checks [cachedInstance] first and then [storeToCache] with [OverlayElement.newInstance] otherwise.
  factory CompareImage({
    required TranslationString identifier,
    bool editable = true,
    OverlayContentBuilder contentBuilder,
    bool visible = true,
    required ScaledBounds<int> bounds,
  }) {
    final OverlayElement overlayElement =
        OverlayElement.cachedInstance(identifier) ??
        OverlayElement.storeToCache(
          CompareImage.newInstance(
            identifier: identifier,
            editable: editable,
            contentBuilder: contentBuilder,
            visible: visible,
            bounds: bounds,
          ),
        );
    return overlayElement as CompareImage;
  }

  /// Just a simple constructor for the current [GameToolsLib.mainGameWindow]!
  factory CompareImage.forPos({
    required TranslationString identifier,
    required int x,
    required int y,
    required int width,
    required int height,
    bool editable = true,
    OverlayContentBuilder contentBuilder,
    bool visible = true,
  }) => CompareImage(
    identifier: identifier,
    editable: editable,
    contentBuilder: contentBuilder,
    visible: visible,
    bounds: ScaledBounds<int>(
      Bounds<int>(x: x, y: y, width: width, height: height),
      creationWidth: null,
      creationHeight: null,
    ),
  );

  /// New instance constructor should only be called internally from sub classes to create a new object instance!
  /// From the outside, use the default factory constructor instead!
  @protected
  CompareImage.newInstance({
    required super.identifier,
    required super.editable,
    required super.contentBuilder,
    required super.visible,
    required super.bounds,
  }) : super.newInstance(clickable: false);

  @override
  Widget buildOverlay(BuildContext context) {
    Logger.warn("buildOverlay was called on $this");
    return const SizedBox();
  }

  @override
  Widget buildEdit(BuildContext context) {
    return EditableBuilder(
      borderColor: Colors.pinkAccent,
      overlayElement: this,
      alsoColorizeMiddle: true,
      child: null,
    );
  }
}
