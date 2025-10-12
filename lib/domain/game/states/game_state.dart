part of 'package:game_tools_lib/game_tools_lib.dart';

/// Base class for all game states which you have to extend from with custom subclasses that at least override
/// [onUpdate] to do the periodic work while this state is active.
///
/// States are added with [GameToolsLib.changeState] for example in [GameManager.onStart] and the current state is
/// saved in [GameToolsLib.currentState].
///
/// The first and last states (on start and on finish) will always be [GameClosedState].
///
/// You can also override the following: [onStart], [onStop], [onOpenChange], [onFocusChange].
///
/// In subclasses you can do your custom initialization in the constructor and you can access everything there!
///
/// If you want to compare objects of this, you have to implement custom equality yourself in your sub classes! Per
/// default it compares if references point to the same object.
///
/// For an example look at [ExampleState]. Also look at [ChildGameState] for another option to extend when you have
/// parent + child states.
abstract base class GameState {
  /// Internal counter for better logging [_idCounter]
  final int _id;

  static int _idCounter = 0;

  /// This logs something, so only use this after [GameToolsLib.initGameToolsLib]!
  GameState() : _id = _idCounter++ {
    Logger.verbose("Created new state $this");
  }

  /// Is called when the open status changes for [window]. This will also be called when it opens for the first time!
  /// Don't use any delays inside of this!
  Future<void> onOpenChange(GameWindow window) async {}

  /// Is called when the focus changes for [window]. This will also be called when it receives focus for the first time!
  /// Don't use any delays inside of this!
  Future<void> onFocusChange(GameWindow window) async {}

  /// Is called internally when this state becomes active and also receives the previous [oldState] (which would only
  /// be null for the first state which is [GameClosedState] for which this method is not called!).
  ///
  /// This is called after [onStop] for the old state. Should not have any internal await delays!
  ///
  /// If you want to call this super class method on your sub class, then it will automatically [Logger.info] log the
  /// [welcomeMessage] which may also be overridden in sub classes!
  Future<void> onStart(GameState oldState) async {
    Logger.info(welcomeMessage);
  }

  /// Will be called when this state becomes inactive and also receives the next [newState].
  /// On closing the program with [GameToolsLib.close], this is also called with [GameClosedState] for the last state!
  ///
  /// This is called before [onStart] for the new state. Should not have any internal await delays! Can be used for
  /// cleanup.
  Future<void> onStop(GameState newState) async {}

  /// This is the periodic callback for your periodic update work while this state is active.
  /// This will always be called at the start of the internal game tools lib event loop after [GameManager.onUpdate],
  /// but it wont be awaited
  ///
  /// Instead of awaiting delays internally here, you should return a [Duration] as a delay to the next action
  /// (depending on the [GameEventStatus] you return). Otherwise just return [Duration.zero] in the record!
  ///
  /// You should avoid awaiting delays internally here, but if you do, you have to check the following more often
  /// [GameWindow.isOpen] and [GameWindow.hasFocus] for [GameToolsLib.mainGameWindow], or you can control it with
  /// member variables and [onOpenChange] and [onFocusChange]. (because they might have been changed in the meantime)
  Future<void> onUpdate();

  /// Can be overridden in sub classes to return some message that will be logged in the [onStart] if you call
  /// "super.onStart" in your sub class.
  ///
  /// Per default it only returns "Switched to [runtimeType]" but it can be any other meaningful info like joined area!
  String get welcomeMessage => "Switched to $runtimeType";

  @override
  String toString() => "$runtimeType($_id)";
}
