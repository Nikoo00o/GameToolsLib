import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/utils/bounds.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/overlay/gt_overlay.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/canvas_overlay_element.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/compare_image.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/dynamic_overlay_element.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/overlay_element.dart';

/// Used in [OverlayManager.overlayElements] to [add], [remove], or [get] the [OverlayElement]'s which are build in
/// [GTOverlay] by providing this in a provider and listening to changes! Also a helper method [isObscured]
final class OverlayElementsList with ChangeNotifier {
  final Map<String, OverlayElement> _staticElements;

  /// The remaining overlay ui elements that are not of any of the other special categories.
  UnmodifiableListView<OverlayElement> get staticElements =>
      UnmodifiableListView<OverlayElement>(_staticElements.values);

  final Map<String, DynamicOverlayElement> _dynamicElements;

  /// The [DynamicOverlayElement]'s which are not editable and always have a unique identifier.
  UnmodifiableListView<DynamicOverlayElement> get dynamicElements =>
      UnmodifiableListView<DynamicOverlayElement>(_dynamicElements.values);

  final Map<String, CanvasOverlayElement> _canvasElements;

  /// The [CanvasOverlayElement]'s which have a different rendering mode for their overlay.
  UnmodifiableListView<CanvasOverlayElement> get canvasElements =>
      UnmodifiableListView<CanvasOverlayElement>(_canvasElements.values);

  final Map<String, CompareImage> _compareImages;

  /// The [CompareImage]'s which have their own edit mode and don't draw no overlay
  UnmodifiableListView<CompareImage> get compareImages => UnmodifiableListView<CompareImage>(_compareImages.values);

  /// Only contains reference to the overlay ui elements with [OverlayElement.clickable] being true and is managed
  /// automatically!
  final List<OverlayElement> clickableElements;

  OverlayElementsList()
    : _staticElements = <String, OverlayElement>{},
      _dynamicElements = <String, DynamicOverlayElement>{},
      _canvasElements = <String, CanvasOverlayElement>{},
      _compareImages = <String, CompareImage>{},
      clickableElements = <OverlayElement>[];

  Map<String, OverlayElement>? _containingKey(String key) {
    if (_staticElements.containsKey(key)) {
      return _staticElements;
    }
    if (_dynamicElements.containsKey(key)) {
      return _dynamicElements;
    }
    if (_compareImages.containsKey(key)) {
      return _compareImages;
    }
    if (_canvasElements.containsKey(key)) {
      return _canvasElements;
    }
    return null;
  }

  Map<String, OverlayElement> _containingType(OverlayElement element) {
    if (element is DynamicOverlayElement) {
      return _dynamicElements;
    }
    if (element is CompareImage) {
      return _compareImages;
    }
    if (element is CanvasOverlayElement) {
      return _canvasElements;
    }
    return _staticElements;
  }

  /// Used to return a reference to an instance related to the [identifier] which may return null if it does not exist.
  ///
  /// Of course you can modify members of the reference without needing to update this list!
  OverlayElement? get(TranslationString identifier) {
    final String key = identifier.identifier;
    final Map<String, OverlayElement>? map = _containingKey(key);
    if (map != null) {
      return map[key];
    }
    return null;
  }

  /// Returns if the [element] with its [OverlayElement.identifier] was added and notifies listeners/rebuilds!
  bool add(OverlayElement element) {
    final String key = element.identifier.identifier;
    final Map<String, OverlayElement> map = _containingType(element);
    if (map.containsKey(key) == false) {
      map[key] = element;
      if (element.clickable) {
        clickableElements.add(element);
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Returns if the [element] with its [OverlayElement.identifier] was deleted and notifies listeners/rebuilds!
  bool remove(OverlayElement element) {
    final String key = element.identifier.identifier;
    final Map<String, OverlayElement> map = _containingType(element);
    if (map.containsKey(key) == true) {
      map.remove(key);
      if (element.clickable) {
        clickableElements.remove(element);
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Runs the [callback] for every element!
  void doForAll(void Function(OverlayElement element) callback) {
    _staticElements.values.forEach(callback);
    _dynamicElements.values.forEach(callback);
    _compareImages.values.forEach(callback);
    _canvasElements.values.forEach(callback);
  }

  /// Returns if there is a visible ui overlay element inside of the [bounds] (without checking the overlay mode)!
  ///
  /// Bounds are relational to inner top left window border without top bar!
  bool isObscured(Bounds<int> bounds) =>
      _containsBounds(_staticElements, bounds) ||
      _containsBounds(_dynamicElements, bounds) ||
      _containsBounds(_canvasElements, bounds);

  bool _containsBounds(Map<String, OverlayElement> elements, Bounds<int> bounds2) {
    for (final OverlayElement element in elements.values) {
      final Bounds<int> bounds1 = element.bounds.scaledBounds;
      return bounds1.collides(bounds2);
    }
    return false;
  }

  /// Combined elements count
  int get countOfElements =>
      _dynamicElements.length + _compareImages.length + _canvasElements.length + _staticElements.length;
}
