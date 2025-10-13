import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/bounds.dart';
import 'package:game_tools_lib/core/utils/scaled_bounds.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/dynamic_overlay_element.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/helper/canvas_painter.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/helper/editable_builder.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/overlay_element.dart';

/// This is a special dynamic version of [OverlayElement] which can be used to draw lines, or text directly on the
/// background without widgets! Also look at the general doc comments of [OverlayElement] for general info!
///
/// The [buildOverlay] method does nothing here and instead [paintOnCanvas] is used and can be overridden to draw on
/// the [CanvasPainter]! You can also use the [CanvasOverlayElement.dynamic] constructor instead of the default
/// unnamed one if you carefully read the comments!
///
/// Important: sub classes with additional members that are used in [paintOnCanvas] must override the [operator==] to
/// also compare those and also override the [createDeepCopy] method and create a new instance of the sub type with
/// the additional member values set (like for example [color])!
base class CanvasOverlayElement extends OverlayElement {
  /// Additional mutable member which can be used to influence the paint brush in [paintOnCanvas]
  Color color;

  /// Factory constructor that will cache and reuse instances for [identifier] and should always be used from the
  /// outside! Checks [cachedInstance] first and then [storeToCache] with [OverlayElement.newInstance] otherwise.
  ///
  /// Here per default [editable] is false instead of true!
  factory CanvasOverlayElement({
    required TranslationString identifier,
    bool visible = true,
    bool editable = false,
    required ScaledBounds<int> bounds,
    required Color color,
  }) {
    final OverlayElement overlayElement =
        OverlayElement.cachedInstance(identifier) ??
        OverlayElement.storeToCache(
          CanvasOverlayElement.newInstance(
            identifier: identifier,
            editable: editable,
            visible: visible,
            bounds: bounds,
            color: color,
          ),
        );
    return overlayElement as CanvasOverlayElement;
  }

  static int _identifierCounter = 0;

  static String get _generateIdentifier => "overlay.dynamic.canvas.unique.${_identifierCounter++}";

  /// Special constructor that combines this with the functionality of the [DynamicOverlayElement] to always create a
  /// new instance and not reuse the cache!
  ///
  /// Important: here its even more important to explicitly [dispose] objects created with this constructor before
  /// they go out of scope! Otherwise you will have bad performance very quickly!
  factory CanvasOverlayElement.dynamic({
    bool visible = true,
    required ScaledBounds<int> bounds,
    required Color color,
  }) {
    final TranslationString identifier = TranslationString(_generateIdentifier);
    final OverlayElement overlayElement =
        OverlayElement.cachedInstance(identifier) ??
        OverlayElement.storeToCache(
          CanvasOverlayElement.newInstance(
            identifier: identifier,
            editable: false,
            visible: visible,
            bounds: bounds,
            color: color,
          ),
        );
    return overlayElement as CanvasOverlayElement;
  }

  /// New instance constructor should only be called internally from sub classes to create a new object instance!
  /// From the outside, use the default factory constructor instead!
  @protected
  CanvasOverlayElement.newInstance({
    required super.identifier,
    required super.editable,
    required super.visible,
    required super.bounds,
    required this.color,
  }) : super.newInstance();

  /// Just a simple constructor for the current [GameToolsLib.mainGameWindow]!
  factory CanvasOverlayElement.forPos({
    required TranslationString identifier,
    required int x,
    required int y,
    required int width,
    required int height,
    required Color color,
  }) => CanvasOverlayElement(
    identifier: identifier,
    bounds: ScaledBounds<int>(
      Bounds<int>(x: x, y: y, width: width, height: height),
      creationWidth: null,
      creationHeight: null,
    ),
    color: color,
  );

  /// Used for the [CanvasPainter] for performance during comparison. This needs to be overridden in sub classes to
  /// call the newInstance constructor with new values and create a real new instance and not return a cached reference!
  CanvasOverlayElement createDeepCopy() {
    return CanvasOverlayElement.newInstance(
      identifier: identifier,
      editable: editable,
      visible: visible,
      bounds: bounds,
      color: color,
    );
  }

  @override
  @mustCallSuper
  bool operator ==(Object other) =>
      other is CanvasOverlayElement &&
      super == other &&
      visible == other.visible &&
      bounds == other.bounds &&
      color == other.color;

  @override
  int get hashCode => Object.hash(super.hashCode, visible.hashCode, bounds.hashCode, color.hashCode);

  /// Called from [CanvasPainter] to draw the overlay ui for this if [visible] is true!
  /// Per default this just draws an outlined square at the [bounds], but of course sub classes can override this!
  void paintOnCanvas(Canvas canvas) {
    final Paint paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.stroke;
    canvas.drawRect(bounds.toRect(), paint);
  }

  @override
  Widget buildOverlay(BuildContext context) {
    Logger.warn("buildOverlay was called on $this");
    return const SizedBox();
  }

  @override
  Widget buildEdit(BuildContext context) {
    return EditableBuilder(borderColor: Colors.deepPurpleAccent, overlayElement: this);
  }
}
