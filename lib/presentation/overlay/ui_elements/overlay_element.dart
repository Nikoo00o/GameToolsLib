import 'package:flutter/material.dart';
import 'package:game_tools_lib/core/enums/overlay_mode.dart';
import 'package:game_tools_lib/core/utils/bounds.dart';
import 'package:game_tools_lib/core/utils/scaled_bounds.dart';
import 'package:game_tools_lib/core/utils/translation_string.dart';
import 'package:game_tools_lib/domain/entities/base/model.dart';
import 'package:game_tools_lib/domain/game/game_window.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/canvas_overlay_element.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/compare_image.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/dynamic_overlay_element.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/helper/editable_builder.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/helper/overlay_element_widget.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/helper/overlay_elements_list.dart';
import 'package:provider/provider.dart';

/// Base class for all ui overlay elements. Render Order: [CanvasOverlayElement] ([Colors.deepPurpleAccent] edit
/// border)-> [CompareImage] ([Colors.pinkAccent] edit border) -> [OverlayElement] ([Colors.pink] edit border)
/// -> [DynamicOverlayElement].
///
/// Instances from this must be created with the default constructor which caches and reuses pointers in a
/// [OverlayElementsList] with [identifier]'s in [OverlayManager.overlayElements]. So objects created with the same
/// identifier point to the same instance! So the objects will never get garbage collected except if you call
/// [dispose] and all references go out of scope. But you can also use the [OverlayElement.forPos] constructor for
/// simplicity!
///
/// Important: only create instances of this after the [OverlayManager] is initialized from [GameToolsLib.initGameToolsLib]
/// but also remember that static variables are only late initialized when you access them first and so those might
/// not get created and the elements won't show up in the edit ui screen! Best create objects in some onCreate/onStart
/// callback method of a module, or manager! To init late final static variables, you can use [ensureInitialized].
///
/// Also during construction [loadOrSaveToStorage] is called automatically to synchronize the data with the storage
/// (loads, or saves)! Afterwards [saveToStorage] is used! And the user may edit the json data while the program is
/// closed (errors will lead to overriding user file with defaults again!)! For this sub classes must also override
/// [toJson] and [fromJson] and extend them by the additional member.
///
/// If you set [editable] to true, then [buildEdit] will be called and this object will be saved to storage. And you
/// can also toggle visibility with [visible] for [buildOverlay] to hide/show this.
/// For those elements saved to storage, the values from the constructor are only default values that will be
/// replaced by those from storage! This includes for example the position with [bounds], etc so that users can
/// adjust the ui!
///
/// You can set [clickable] to true to receive mouse events (clicks/focus) instead of the underlying window.
///
/// Subclasses should override [buildOverlay] and [buildEdit] to build the layout depending on the [OverlayMode] in
/// [OverlayManager.overlayMode]. And subclasses must create a separate [OverlayElement.newInstance] constructor that
/// calls the same constructor of the super class to create new instances. And then the default unnamed constructor
/// must be a factory constructor that returns [OverlayElement.cachedInstance] if not null and only otherwise calls the
/// newly created newInstance constructor as param to [OverlayElement.storeToCache]. For example look at [CompareImage]
///
/// Important: for any additional member in your subclasses that affect displaying, you must add a call to
/// [notifyListeners] in the setter for the property, because otherwise the overlay ui element will not automatically
/// be rebuild on changes!
///
///
/// Per default here the [operator==] and [hashCode] only compare the [identifier].
///
/// For example you could just create an use an object anywhere like the following:
/// `final OverlayElement element1 = OverlayElement.forPos(x: 10, y: 10, width: 100, height: 200, identifier: const TS("overlay.example.1"));`
base class OverlayElement with ChangeNotifier implements Model {
  /// This is used to identify cached instances, so each logically unique object should have a different unique
  /// identifier! But you can create new objects with the constructor that reference the same instance if they use
  /// the same identifier.
  ///
  /// It will also be translated and displayed when editing the UI to show some info!
  ///
  /// It will also be used (untranslated) as the name for the json file that is stored for this, so don't use any
  /// special characters like "/", "\", "?", """, ":", "*", "|", "<", ">" !
  final TranslationString identifier;

  /// Controls if this [buildEdit] is called or an empty sized box is displayed instead.
  ///
  /// But unrelated to this, this overlay element will only be shown if [OverlayManager.overlayMode] is
  /// [OverlayMode.EDIT_UI] or [OverlayMode.EDIT_COMP_IMAGES] depending on runtime.
  ///
  /// Important: this also controls if the members of this object are saved to storage, or not!
  final bool editable;

  /// Optionally this can be set to true to allow mouse events like clicks, etc to affect the overlay instead of the
  /// underlying window. be careful when using this!
  final bool clickable;

  bool _visible;

  /// Controls if this [buildOverlay] is called or an empty sized box is displayed instead as an extra toggle.
  ///
  /// But unrelated to this, this overlay element will only be shown if [OverlayManager.overlayMode] is
  /// [OverlayMode.VISIBLE]
  ///
  /// This is mutable and may be changed during runtime to toggle the visibility of this element (and rebuild after)!
  bool get visible => _visible;

  /// Controls if this [buildOverlay] is called or an empty sized box is displayed instead.
  ///
  /// But unrelated to this, this overlay element will only be shown if [OverlayManager.overlayMode] is
  /// [OverlayMode.VISIBLE]
  ///
  /// This is mutable and may be changed during runtime to toggle the visibility of this element (and rebuild after)!
  set visible(bool value) {
    _visible = value;
    notifyListeners();
  }

  // see below
  ScaledBounds<int> _bounds;

  /// The position and size of this ui element in relation to the size of the window it was created with.
  ///
  /// Best change this by setting it to [ScaledBounds.move] which automatically references the current window size!
  ///
  /// You don't have to worry about the window resizing here!
  ScaledBounds<int> get bounds => _bounds;

  // see below
  Bounds<double>? _displayDimension;

  /// Set periodically during the build in [buildOverlay] to contain the final already scaled position of the widget!
  ///
  /// Used in [OverlayManager._checkMouseForClickableOverlayElements].
  Bounds<double>? get displayDimension => _displayDimension;

  /// The position and size of this ui element in relation to the size of the window it was created with.
  ///
  /// Best change this by setting it to [ScaledBounds.move] which automatically references the current window size!
  ///
  /// You don't have to worry about the window resizing here!
  set bounds(ScaledBounds<int> value) {
    _bounds = value;
    notifyListeners();
  }

  /// Factory constructor that will cache and reuse instances for [identifier] and should always be used from the
  /// outside! Checks [cachedInstance] first and then [storeToCache] with [OverlayElement.newInstance] otherwise.
  factory OverlayElement({
    required TranslationString identifier,
    bool editable = true,
    bool clickable = false,
    bool visible = true,
    required ScaledBounds<int> bounds,
  }) =>
      cachedInstance(identifier) ??
      storeToCache(
        OverlayElement.newInstance(
          identifier: identifier,
          editable: editable,
          clickable: clickable,
          visible: visible,
          bounds: bounds,
        ),
      );

  /// Just a simple constructor for the current [GameToolsLib.mainGameWindow]!
  factory OverlayElement.forPos({
    required TranslationString identifier,
    required int x,
    required int y,
    required int width,
    required int height,
    bool editable = true,
    bool clickable = false,
    bool visible = true,
  }) => OverlayElement(
    identifier: identifier,
    editable: editable,
    clickable: clickable,
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
  OverlayElement.newInstance({
    required this.identifier,
    required this.editable,
    required this.clickable,
    required bool visible,
    required ScaledBounds<int> bounds,
  }) : _visible = visible,
       _bounds = bounds;

  static final SpamIdentifier _storeLog = SpamIdentifier();

  /// Does nothing, but can be used in a constructor of any class if you have static variables in the file that you want
  /// to make sure are initialized right after the game tools lib and not only when they are used.
  void ensureInitialized() {}

  /// Used to either load, or store the current member data for this identifier from/to storage in the
  /// unnamed default factory constructor inside of [storeToCache]!
  ///
  /// This checks first if [editable] is true and otherwise does nothing!
  ///
  /// If the user modified the data to be invalid, then it will be overridden by default data at some point when the
  /// [OverlayManager.overlayMode] changes the next time!
  void loadOrSaveToStorage() {
    if (editable) {
      final Map<String, dynamic>? json = GameToolsLib.database.loadSimpleJson(
        subPath: <String>[OverlayManager.overlayManager().overlayElementSubFolder, identifier.identifier],
      );
      if (json != null) {
        try {
          fromJson(json);
          Logger.spam("Loaded $this from storage");
        } catch (e, s) {
          Logger.error("Could not load Overlay Element $identifier from its json file, OVERRIDING IT", e, s);
        }
      } else {
        saveToStorage();
        Logger.spamPeriodic(_storeLog, "Saved ", this, " to storage");
      }
    }
  }

  /// Used to store the current member data for this identifier to storage (modifiable json) which is only always
  /// called automatically in [OverlayManager.onOverlayModeChanged] if this is editable and in [dispose].
  ///
  /// This checks first if [editable] is true and otherwise does nothing!
  ///
  /// This will not listen to changes exactly between [OverlayMode.HIDDEN] and [OverlayMode.VISIBLE] which happen
  /// quite often!
  void saveToStorage() {
    if (editable == true) {
      GameToolsLib.database.storeSimpleJson(
        subPath: <String>[OverlayManager.overlayManager().overlayElementSubFolder, identifier.identifier],
        convertToJson: this,
      );
      Logger.spamPeriodic(_storeLog, "Saved ", this, " to storage");
    }
  }

  static final SpamIdentifier _cacheLog = SpamIdentifier();

  /// This is used to first return the matching cached instance to the [identifier] or null if not found in all factory
  /// constructors of this and sub classes!
  static OverlayElement? cachedInstance(TranslationString identifier) {
    final OverlayElement? element = OverlayManager.overlayManager().overlayElements.get(identifier);
    if (element != null) {
      Logger.spamPeriodic(_cacheLog, "Loaded from cache: ", element);
    }
    return element;
  }

  /// This is used to then store a new instance to the cache in all factory constructors of this and sub classes!
  ///
  /// Just returns the [newInstance] after caching it after calling [loadOrSaveToStorage] on it!
  static OverlayElement storeToCache(OverlayElement newInstance) {
    final OverlayManagerBaseType overlayManager = OverlayManager.overlayManager();
    final GameWindow otherWindow = newInstance.bounds.gameWindow;
    overlayManager.overlayElements.add(newInstance);
    if (overlayManager.windowToTrack != otherWindow) {
      Logger.warn("OverlayElement ${newInstance.identifier} window ${otherWindow.name} did not match OverlayManager");
    }
    newInstance.loadOrSaveToStorage();
    Logger.spamPeriodic(_cacheLog, "Created new: ", newInstance);
    return newInstance;
  }

  /// This is used to remove the instance this element is pointing to from the cache so they will no longer be
  /// updated. Important: this will also invalidate all references to the same object and they will not be refreshed!
  /// So after this the garbage collector may destroy the instance if all references go out of scope.
  @override
  void dispose() {
    super.dispose();
    overlayElementsList.remove(this);
    saveToStorage();
  }

  /// Called from [buildOverlay] to build the inner content within the [scaledBounds].
  ///
  /// Per default this just builds a yellow border around and puts a to do message inside!
  Widget buildContent(BuildContext context, Bounds<double> scaledBounds) {
    return Container(
      width: scaledBounds.width,
      height: scaledBounds.height,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.yellow,
          width: 5.0,
        ),
        borderRadius: BorderRadius.circular(1),
      ),
      child: Center(child: Text(TS.combineS(<TS>[TS.raw("todo: buildContent for "), identifier], context))),
    );
  }

  /// This will be called automatically to build the overlay content of this overlay ui element if [visible] is true
  /// (otherwise nothing is displayed). Per default this just calls the helper method [buildContent] inside of a
  /// [Positioned] widget! Also sets the [displayDimension] for the final already scaled size!
  Widget buildOverlay(BuildContext context) {
    _displayDimension = bounds.scaledBoundsD;
    return Positioned(
      left: _displayDimension!.x,
      top: _displayDimension!.y,
      width: _displayDimension!.width,
      height: _displayDimension!.height,
      child: buildContent(context, _displayDimension!),
    );
  }

  /// This will be called automatically to build the edit border of this overlay ui element if [editable] is true
  /// (otherwise nothing is displayed). Per default this just returns an [EditableBuilder] with [Colors.pink] and of
  /// course sub classes may override this to choose a different border color!
  Widget buildEdit(BuildContext context) {
    return EditableBuilder(borderColor: Colors.pink, overlayElement: this);
  }

  /// This will be called from the [OverlayManager] automatically to build a [ChangeNotifierProvider] around a
  /// [OverlayElementWidget] for this this element depending on the [editInsteadOfOverlay].
  ChangeNotifierProvider<OverlayElement> build(BuildContext context, {required bool editInsteadOfOverlay}) {
    return ChangeNotifierProvider<OverlayElement>.value(
      value: this,
      builder: (BuildContext context, Widget? child) {
        return OverlayElementWidget(editInsteadOfOverlay: editInsteadOfOverlay);
      },
    );
  }

  static const String JSON_VISIBLE = "Visible";
  static const String JSON_BOUNDS = "Bounds";

  /// This is called from [loadOrSaveToStorage] to convert this into a json map for storage. When overriding call
  /// super method as well to apply the values!
  ///
  /// Only affects [visible] and [bounds], because [editable] is final and the identifier is used as file name!
  @override
  @mustCallSuper
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JSON_VISIBLE: _visible,
      JSON_BOUNDS: _bounds.toJson(),
    };
  }

  /// This is called from [loadOrSaveToStorage] to load dynamic members out of the json file. When overriding call
  /// super method as well to apply the values!
  ///
  /// Only affects [visible] and [bounds], because [editable] is final and the identifier is used as file name!
  @mustCallSuper
  void fromJson(Map<String, dynamic> json) {
    _visible = json[JSON_VISIBLE] as bool;
    _bounds = ScaledBounds<int>.fromJson(json[JSON_BOUNDS] as Map<String, dynamic>);
    notifyListeners();
  }

  @override
  @mustCallSuper
  bool operator ==(Object other) =>
      other is OverlayElement && other.runtimeType == runtimeType && identifier == other.identifier;

  @override
  @mustCallSuper
  int get hashCode => identifier.hashCode;

  @override
  String toString() => "$runtimeType(identifier: $identifier, editable: $editable, visible: $visible, bounds: $bounds)";

  /// Quick reference to [OverlayManager.overlayElements]
  OverlayElementsList get overlayElementsList => OverlayManager.overlayManager().overlayElements;
}
