import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/bounds.dart';
import 'package:game_tools_lib/core/utils/scaled_bounds.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/overlay_element.dart';

/// This is a special dynamic version of the static [OverlayElement] which can be used to quickly show/hide a menu
/// overlay at a dynamic position instead of some statically configured overlays! Also look at the general doc
/// comments of [OverlayElement] for general info!
///
/// The [buildEdit] method does nothing here and this also does not care about [toJson] and [fromJson], because it is
/// not saved to storage! [editable] is always false here!
///
/// In most cases you just create a subclass of this and override [buildContent] to builds your content!
///
/// Also for this special case there are always unique objects created and no cached references reused! Therefor the
/// [identifier] is created uniquely internally starting with "overlay.dynamic.unique.0"!
/// So here its important to call [dispose] before your local object variable of this type goes out of scope, because
/// otherwise you create memory leaks!
base class DynamicOverlayElement extends OverlayElement {
  static int _identifierCounter = 0;

  static String get _generateIdentifier => "overlay.dynamic.unique.${_identifierCounter++}";

  /// Factory constructor should always be used from the outside to add the unique objects automatically!
  /// Checks [cachedInstance] first and then [storeToCache] with [OverlayElement.newInstance] otherwise.
  factory DynamicOverlayElement({
    bool visible = true,
    required ScaledBounds<int> bounds,
  }) {
    final TranslationString identifier = TranslationString(_generateIdentifier);
    final OverlayElement overlayElement =
        OverlayElement.cachedInstance(identifier) ??
        OverlayElement.storeToCache(
          DynamicOverlayElement.newInstance(
            identifier: identifier,
            visible: visible,
            bounds: bounds,
          ),
        );
    return overlayElement as DynamicOverlayElement;
  }

  /// New instance constructor should only be called internally from sub classes to create a new object instance!
  /// From the outside, use the default factory constructor instead!
  @protected
  DynamicOverlayElement.newInstance({
    required super.identifier,
    required super.visible,
    required super.bounds,
  }) : super.newInstance(editable: false);

  /// Just a simple constructor for the current [GameToolsLib.mainGameWindow]!
  factory DynamicOverlayElement.forPos({
    required int x,
    required int y,
    required int width,
    required int height,
  }) => DynamicOverlayElement(
    bounds: ScaledBounds<int>(
      Bounds<int>(x: x, y: y, width: width, height: height),
      creationWidth: null,
      creationHeight: null,
    ),
  );

  @override
  Widget buildEdit(BuildContext context) {
    Logger.warn("buildEdit was called on $this");
    return const SizedBox();
  }
}
