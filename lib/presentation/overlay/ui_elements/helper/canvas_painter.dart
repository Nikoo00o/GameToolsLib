import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/list_utils.dart';
import 'package:game_tools_lib/presentation/overlay/gt_overlay.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/canvas_overlay_element.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/helper/overlay_elements_list.dart';

/// Used automatically in [GTOverlay] to paint the CanvasOverlayElement[] from [OverlayElementsList.canvasElements]
/// if they are visible!
final class CanvasPainter extends CustomPainter {
  /// Deep copy of the [OverlayElementsList.canvasElements] that is used for performance comparison in [shouldRepaint]!
  final List<CanvasOverlayElement> copiedElements;

  CanvasPainter(UnmodifiableListView<CanvasOverlayElement> canvasElements)
    : copiedElements = canvasElements.map((CanvasOverlayElement element) => element.createDeepCopy()).toList();

  @override
  void paint(Canvas canvas, Size size) {
    for (final CanvasOverlayElement element in copiedElements) {
      if (element.visible) {
        element.paintOnCanvas(canvas);
      }
    }
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) =>
      ListUtils.equals(copiedElements, oldDelegate.copiedElements) == false;

  @override
  bool shouldRebuildSemantics(CanvasPainter oldDelegate) => false;
}
