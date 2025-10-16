import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/bounds.dart';
import 'package:game_tools_lib/core/utils/scaled_bounds.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/data/assets/gt_asset.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/helper/editable_builder.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/overlay_element.dart';

///
/// The [unscaledImage] is used to store the image file and the [ImageAsset.fileName] will be used as the [identifier]!
///
/// The [buildOverlay] method does nothing here and [clickable] will always be false for this!
///
/// Important:
base class CompareImage extends OverlayElement {
  /// Reference to the locally stored image file from which the (not dynamically changing) [ImageAsset.fileName] will
  /// be used as the [identifier] which is also used as a file name to save this compare image to storage!
  final ImageAsset unscaledImage;

  /// Factory constructor that will cache and reuse instances for [identifier] and should always be used from the
  /// outside! Checks [cachedInstance] first and then [storeToCache] with [OverlayElement.newInstance] otherwise.
  factory CompareImage({
    bool editable = true,
    OverlayContentBuilder contentBuilder,
    bool visible = true,
    required ScaledBounds<int> bounds,
    required ImageAsset unscaledImage,
  }) {
    final TranslationString identifier = TranslationString.raw(unscaledImage.fileName);
    final OverlayElement overlayElement =
        OverlayElement.cachedInstance(identifier) ??
        OverlayElement.storeToCache(
          CompareImage.newInstance(
            identifier: identifier,
            editable: editable,
            contentBuilder: contentBuilder,
            visible: visible,
            bounds: bounds,
            unscaledImage: unscaledImage,
          ),
        );
    return overlayElement as CompareImage;
  }

  /// Just a simple constructor for the current [GameToolsLib.mainGameWindow]!
  factory CompareImage.forPos({
    required int x,
    required int y,
    required int width,
    required int height,
    bool editable = true,
    OverlayContentBuilder contentBuilder,
    bool visible = true,
    required ImageAsset unscaledImage,
  }) => CompareImage(
    editable: editable,
    contentBuilder: contentBuilder,
    visible: visible,
    bounds: ScaledBounds<int>(
      Bounds<int>(x: x, y: y, width: width, height: height),
      creationWidth: null,
      creationHeight: null,
    ),
    unscaledImage: unscaledImage,
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
    required this.unscaledImage,
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
