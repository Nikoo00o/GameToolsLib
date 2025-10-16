import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/bounds.dart';
import 'package:game_tools_lib/core/utils/scaled_bounds.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/overlay_element.dart';

/// Used to build the edit border and a drag and drop around an [OverlayElement] and is used in
/// [OverlayElement.buildEdit].
///
/// The translated [OverlayElement.identifier] will be shown as text in the center (or optionally a custom [child] and
/// the border with the [borderColor] will be shifted by 1 pixel to the outside so the whole content of the
/// [overlayElement] is visible.
class EditableBuilder extends StatefulWidget {
  /// For the border on the outside (and also the slightly transparent effect in the middle which can be turned off
  /// with [alsoColorizeMiddle])
  final Color borderColor;

  /// Reference to the object this builds the border for
  final OverlayElement overlayElement;

  /// Quick access to the bounds of the overlay element
  late final Bounds<double> scaledBounds = overlayElement.bounds.scaledBoundsD;

  /// If this should also paint the [borderColor] semi transparent within the whole element as well (the center will
  /// always be painted for the dragging around effect)!
  final bool alsoColorizeMiddle;

  /// Displayed in the middle of the element. If null, then just a [Text] will be shown with a translated
  /// [OverlayElement.identifier].
  final Widget? child;

  EditableBuilder({
    super.key,
    required this.borderColor,
    required this.overlayElement,
    required this.alsoColorizeMiddle,
    required this.child,
  });

  @override
  State<EditableBuilder> createState() => _EditableBuilderState();
}

class _EditableBuilderState extends State<EditableBuilder> {
  /// The mutable bounds which change during modifications below
  late double x, y, width, height;

  double _dragX = 0, _dragY = 0;

  static const double borderSize = 2;

  @override
  void initState() {
    super.initState();
    _initBounds();
  }

  @override
  void didUpdateWidget(covariant EditableBuilder oldWidget) {
    _initBounds();
    super.didUpdateWidget(oldWidget);
  }

  void _initBounds() {
    x = widget.scaledBounds.x;
    y = widget.scaledBounds.y;
    width = widget.scaledBounds.width;
    height = widget.scaledBounds.height;
  }

  void _startDrag(DragStartDetails? details) {
    if (details != null) {
      _dragX = details.globalPosition.dx;
      _dragY = details.globalPosition.dy;
    }
  }

  void _finishedDrag(DragEndDetails? details) {
    final ScaledBounds<int> scaledBounds = widget.overlayElement.bounds;
    final Bounds<int> bounds = Bounds<int>(x: x.round(), y: y.round(), width: width.round(), height: height.round());
    if (bounds.x < 0 ||
        bounds.y < 0 ||
        bounds.x + bounds.width > scaledBounds.gameWindow.width ||
        bounds.y + bounds.height > scaledBounds.gameWindow.height) {
      Logger.warn(
        "Resetting drag and drop, because you moved the element out of the window! Bounds $bounds for "
        "window size ${scaledBounds.gameWindow.width}, ${scaledBounds.gameWindow.height}",
      );
      setState(() {
        _initBounds();
      });
    } else {
      widget.overlayElement.bounds = scaledBounds.move(bounds);
    }
  }

  /// Builds gesture detector around something
  Widget buildDraggable(
    MouseCursor cursor,
    void Function(double dx, double dy) onDrag,
    Widget child,
  ) {
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: _startDrag,
        onPanUpdate: (DragUpdateDetails? details) {
          if (details != null) {
            final double dx = details.globalPosition.dx - _dragX;
            final double dy = details.globalPosition.dy - _dragY;
            _dragX = details.globalPosition.dx;
            _dragY = details.globalPosition.dy;
            onDrag.call(dx, dy);
          }
        },
        onPanEnd: _finishedDrag,
        child: child,
      ),
    );
  }

  /// vertical true would be left and right borders
  Widget buildBorderContainer({required bool vertical}) {
    return Container(
      width: vertical ? borderSize : width + borderSize * 2,
      height: vertical ? height : borderSize,
      color: widget.borderColor,
    );
  }

  void _move(double dx, double dy) => setState(() {
    x += dx;
    y += dy;
  });

  void _resize(double? dx, double? dy) => setState(() {
    if (dx != null) {
      width += dx;
    }
    if (dy != null) {
      height += dy;
    }
  });

  /// resizing to top left corner should also move position and invert the value
  void _resizeInverted(double? dx, double? dy) => setState(() {
    if (dx != null) {
      width -= dx;
      x += dx;
    }
    if (dy != null) {
      height -= dy;
      y += dy;
    }
  });

  Widget buildMiddleContainer(BuildContext context) {
    final double innerWidth = width - borderSize * 4;
    final double innerHeight = height - borderSize * 4;
    return Container(
      color: widget.alsoColorizeMiddle ? widget.borderColor.withValues(alpha: 0.15) : null,
      width: innerWidth,
      height: innerHeight,
      child: Stack(
        children: <Widget>[
          Center(child: widget.child ?? Text(widget.overlayElement.identifier.tl(context))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: innerWidth / 3, vertical: innerHeight / 3),
            child: buildDraggable(
              SystemMouseCursors.move,
              _move,
              Container(color: widget.borderColor.withValues(alpha: 0.05)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInnerPaddingAndDoubleDetector(BuildContext context) {
    // return buildMiddleContainer(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildDraggable(
          SystemMouseCursors.resizeUp,
          (double dx, double dy) => _resizeInverted(null, dy),
          Container(height: borderSize * 2, width: width, color: widget.borderColor.withValues(alpha: 0.15)),
        ),
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              buildDraggable(
                SystemMouseCursors.resizeLeft,
                (double dx, double dy) => _resizeInverted(dx, null),
                Container(width: borderSize * 2, height: height, color: widget.borderColor.withValues(alpha: 0.15)),
              ),
              Expanded(child: buildMiddleContainer(context)),
              buildDraggable(
                SystemMouseCursors.resizeRight,
                (double dx, double dy) => _resize(dx, null),
                Container(width: borderSize * 2, height: height, color: widget.borderColor.withValues(alpha: 0.15)),
              ),
            ],
          ),
        ),
        buildDraggable(
          SystemMouseCursors.resizeDown,
          (double dx, double dy) => _resize(null, dy),
          Container(height: borderSize * 2, width: width, color: widget.borderColor.withValues(alpha: 0.15)),
        ),
      ],
    );
  }

  Widget buildStructure(BuildContext context) {
    return SizedBox(
      width: width + borderSize * 2,
      height: height + borderSize * 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          buildDraggable(
            SystemMouseCursors.resizeUp,
            (double dx, double dy) => _resizeInverted(null, dy),
            buildBorderContainer(vertical: false),
          ),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                buildDraggable(
                  SystemMouseCursors.resizeLeft,
                  (double dx, double dy) => _resizeInverted(dx, null),
                  buildBorderContainer(vertical: true),
                ),
                Expanded(child: buildInnerPaddingAndDoubleDetector(context)),
                buildDraggable(
                  SystemMouseCursors.resizeRight,
                  (double dx, double dy) => _resize(dx, null),
                  buildBorderContainer(vertical: true),
                ),
              ],
            ),
          ),
          buildDraggable(
            SystemMouseCursors.resizeDown,
            (double dx, double dy) => _resize(null, dy),
            buildBorderContainer(vertical: false),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x - borderSize,
      top: y - borderSize,
      width: width + borderSize * 2,
      height: height + borderSize * 2,
      child: buildStructure(context),
    );
  }
}
