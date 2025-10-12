part of 'package:game_tools_lib/game_tools_lib.dart';

typedef GameEventStepCallback = Future<(GameEventStatus, Duration)> Function();

/// Base class for all game events which you have to extend from with custom subclasses that at least override
/// [onStep1] to do the event work when they are updated. You can overload up to 15 steps to [onStep15] for the auto
/// navigation with the return type of the steps (but you can also manually change to your custom steps with
/// [changeToStep]. Also in addition to the auto deletion, you can manually delete this event with [remove] and you
/// can add other events with [addEvent].
///
/// You can also override the following: [onStart], [onStop], [onOpenChange], [onFocusChange], [onStateChange],
/// [onOverlayModeChanged] and [onData] for the data from other events [sendDataToEventsT] + [sendDataToEventsG]!
///
/// As a quicker shortcut outside of overriding, you can also use [checkCorrectState] periodically in your [onStep1]
/// and then use [getCurrentState] if you need specific subtype data access for your state!
///
/// The [priority] can only be set once in the constructor and dictates how and when your event is executed.
/// The [GameEventGroup]s [_groups] can be set in the constructor, but also be modified afterwards with [addToGroup],
/// [removeFromGroup] and [isInGroup] and of course you can also use multiple groups in the constructor (chain them
/// together with the bitwise or operator).
///
/// If you want to compare objects of this, you have to implement custom equality yourself in your sub classes! Per
/// default it compares if references point to the same object.
///
/// Initialization can be done in the constructor, or in [onStart]
///
/// For an example look at [ExampleEvent]
abstract base class GameEvent {
  /// The priority of this event, if this is [GameEventPriority.INSTANT], then this will instantly be executed when
  /// adding the event with for example [addEvent] unawaited! Otherwise it will be processed later in the event queue!
  /// IMPORTANT: instant events will only complete [onStep1] and then will directly be removed (see [remove])
  final GameEventPriority priority;

  /// Function that will be called on updating (will be [onStep1] first. if this is null, then this will be removed)
  GameEventStepCallback? _currentStep;

  /// If not null, then the next action is delayed (will be null at first)
  DateTime? _delayedUntil;

  /// Internal toggle for [onStart]
  bool _alreadyCalledStart = false;

  /// The groups this event is assigned to currently (0 means no group and otherwise the group bits are set)
  GameEventGroup _groups;

  /// Only used internally for debugging and logging to keep track of the event order
  late final int _id;

  static int _idCounter = 0;

  static final SpamIdentifier _stepLog = SpamIdentifier();

  /// The default parameter will add this event last in the queue and [GameEventGroup.no_group].
  /// If you want to have this event be in multiple groups, use the bitwise operator like for example:
  /// "[GameEventGroup.group1] | [GameEventGroup.group2]" for the "groups" parameter
  GameEvent({
    this.priority = GameEventPriority.LAST,
    GameEventGroup groups = GameEventGroup.no_group,
  }) : _groups = groups {
    _currentStep = onStep1; // always start on first step!
    _id = _idCounter++;
  }

  /// Marks this event as being in the [group] (you can add events to as many groups of [GameEventGroup] as you like!)
  void addToGroup(GameEventGroup group) {
    _groups = _groups | group;
    Logger.spam("Added ", this, " to group ", group);
  }

  /// Marks this event as no longer being a part of [group]
  void removeFromGroup(GameEventGroup group) {
    _groups = _groups & group.inverted;
    Logger.spam("Removed ", this, " from group ", group);
  }

  /// Returns if this event is marked as being in the [group]
  bool isInGroup(GameEventGroup group) => (_groups & group) != GameEventGroup.no_group;

  /// Removes this event from the internal event queue
  Future<void> remove() async => _GameToolsLibEventLoop._removeEventInternal(this);

  /// Just shortcut for [GameToolsLib.addEvent] to add a new event
  void addEvent(GameEvent event) => GameToolsLib.addEvent(event);

  /// You can also use this to switch to an explicit [stepCallback] before your step callback returns. But you have
  /// to return [GameEventStatus.SAME_STEP] in your callback then! And afterwards you can no longer use
  /// [GameEventStatus.NEXT_STEP] or [GameEventStatus.PREV_STEP]
  void changeToStep(GameEventStepCallback stepCallback) {
    _currentStep = stepCallback;
    Logger.spamPeriodic(_stepLog, this, " changed step from ", _currentStep, " to custom ", stepCallback);
  }

  /// Is called when the open status changes for [window]. This will also be called when it opens for the first time!
  /// Don't use any delays inside of this!
  Future<void> onOpenChange(GameWindow window) async {}

  /// Is called when the focus changes for [window]. This will also be called when it receives focus for the first time!
  /// Don't use any delays inside of this!
  Future<void> onFocusChange(GameWindow window) async {}

  /// Is called internally once  before this event starts updating with [onStep1] (should not await any delays!)
  /// So this can be used for custom async initialisation or actions that should only happen once in total, because
  /// step1 can be called multiple times.
  Future<void> onStart() async {}

  /// Will be called from the remover after this event is removed from the event queue by [remove] (should not
  /// await any delays inside!). So this can be used for any clean up!
  Future<void> onStop() async {}

  /// Is called after the state is changed from [oldState] to [newState] with [GameToolsLib.changeState].
  /// Don't use any delays inside of this! Important: the first and last state on start and end of the game itself will
  /// always be [GameClosedState] and this callback will only be called after the initial state is set, so [oldState]
  /// will never be null (but the callback will also be called at the end)!
  ///
  /// Of course you could also instead always check the [GameToolsLib.currentState] in your [onStep1].
  ///
  /// For example you could check if the [newState] becomes [GameClosedState] and then call [remove] on this so that
  /// the cleanup from [onStop] can be executed.
  Future<void> onStateChange(GameState oldState, GameState newState) async {}

  /// This is a quick shortcut to check if the [GameToolsLib.mainGameWindow] is open (if [requiresOpen] is true) and
  /// if it also has focus(if [requiresFocus] is true) and if the [GameToolsLib.currentState] is of type [StateType].
  ///
  /// This is an alternative for comparing outside of [onOpenChange], [onFocusChange] and [onStateChange]!
  ///
  /// If you don't care about the current state, then just use [GameState] as [StateType].
  bool checkCorrectState<StateType extends GameState>({bool requiresOpen = true, bool requiresFocus = true}) {
    final GameWindow window = GameToolsLib.mainGameWindow;
    if (requiresOpen && window.isOpen == false) {
      return false;
    }
    if (requiresFocus && window.hasFocus == false) {
      return false;
    }
    if (GameToolsLib.currentState is! StateType) {
      return false;
    }
    return true;
  }

  /// This can optionally be overridden to react to changes when the [OverlayMode] of [OverlayManager] changes to
  /// maybe render something conditionally like for example only in [OverlayMode.VISIBLE].
  /// The [oldMode] will only be null for the first call!
  void onOverlayModeChanged(OverlayMode? oldMode, OverlayMode newMode) {}

  /// Shortcut that returns the [GameToolsLib.currentState] as [StateType]
  StateType getCurrentState<StateType>() => GameToolsLib.currentState as StateType;

  /// Synchronously receives [data] from other events sent from [sendDataToEventsT], or [sendDataToEventsG].
  void onData(dynamic data) {}

  /// Synchronously sends some [data] to all currently active [GameEvent]s that match the [EventType] in their [onData]
  /// callback!
  void sendDataToEventsT<EventType>(dynamic data) {
    Logger.spam("Sending data from ", this, " to other events...");
    _GameToolsLibEventLoop._runForAllEvents((GameEvent event) {
      if (event != this && event is EventType) {
        event.onData(data);
        Logger.spam(event, " received the data");
      }
    });
  }

  /// Synchronously sends some [data] to all currently active [GameEvent]s that are in the group [group] in their
  /// [onData] callback!
  void sendDataToEventsG(GameEventGroup group, dynamic data) {
    Logger.spam("Sending data from ", this, " to other events...");
    _GameToolsLibEventLoop._runForAllEvents((GameEvent event) {
      if (event != this && event.isInGroup(group)) {
        event.onData(data);
        Logger.spam(event, " received the data");
      }
    });
  }

  /// This is the first part of this [GameEvent] where you do your periodic update work until this event should be done.
  /// This will always be called at the end of the internal game tools lib event loop, but it wont be awaited (it's
  /// only guaranteed that the events are executed after another in order)!
  ///
  /// Instead of awaiting delays internally here, you should return a [Duration] as a delay to the next action
  /// (depending on the [GameEventStatus] you return). Otherwise just return [Duration.zero] in the record!
  ///
  /// For most events and steps you should also internally check
  /// [GameWindow.isOpen] and [GameWindow.hasFocus] for [GameToolsLib.mainGameWindow], or you can control it with
  /// member variables and [onOpenChange] and [onFocusChange]
  ///
  /// This and any other step callbacks also have to return a [GameEventStatus] in the record depending on the status
  /// how this event should be further processed!
  ///
  /// There are 15 (see [onStep2]) step callbacks that can be iterated through with [GameEventStatus.NEXT_STEP] and
  /// [GameEventStatus.PREV_STEP], but you can also just always return [GameEventStatus.SAME_STEP] and switch to a
  /// custom step before by using [changeToStep].
  ///
  /// As soon as this method returns [GameEventStatus.DONE], then this event will be removed with [remove] after the
  /// delay!
  Future<(GameEventStatus, Duration)> onStep1();

  /// Override in sub class, see documentation for [onStep1]
  Future<(GameEventStatus, Duration)> onStep2() async => (GameEventStatus.DONE, Duration.zero);

  /// Override in sub class, see documentation for [onStep1]
  Future<(GameEventStatus, Duration)> onStep3() async => (GameEventStatus.DONE, Duration.zero);

  /// Override in sub class, see documentation for [onStep1]
  Future<(GameEventStatus, Duration)> onStep4() async => (GameEventStatus.DONE, Duration.zero);

  /// Override in sub class, see documentation for [onStep1]
  Future<(GameEventStatus, Duration)> onStep5() async => (GameEventStatus.DONE, Duration.zero);

  /// Override in sub class, see documentation for [onStep1]
  Future<(GameEventStatus, Duration)> onStep6() async => (GameEventStatus.DONE, Duration.zero);

  /// Override in sub class, see documentation for [onStep1]
  Future<(GameEventStatus, Duration)> onStep7() async => (GameEventStatus.DONE, Duration.zero);

  /// Override in sub class, see documentation for [onStep1]
  Future<(GameEventStatus, Duration)> onStep8() async => (GameEventStatus.DONE, Duration.zero);

  /// Override in sub class, see documentation for [onStep1]
  Future<(GameEventStatus, Duration)> onStep9() async => (GameEventStatus.DONE, Duration.zero);

  /// Override in sub class, see documentation for [onStep1]
  Future<(GameEventStatus, Duration)> onStep10() async => (GameEventStatus.DONE, Duration.zero);

  /// Override in sub class, see documentation for [onStep1]
  Future<(GameEventStatus, Duration)> onStep11() async => (GameEventStatus.DONE, Duration.zero);

  /// Override in sub class, see documentation for [onStep1]
  Future<(GameEventStatus, Duration)> onStep12() async => (GameEventStatus.DONE, Duration.zero);

  /// Override in sub class, see documentation for [onStep1]
  Future<(GameEventStatus, Duration)> onStep13() async => (GameEventStatus.DONE, Duration.zero);

  /// Override in sub class, see documentation for [onStep1]
  Future<(GameEventStatus, Duration)> onStep14() async => (GameEventStatus.DONE, Duration.zero);

  /// Override in sub class, see documentation for [onStep1]
  Future<(GameEventStatus, Duration)> onStep15() async => (GameEventStatus.DONE, Duration.zero);

  /// Returns true if this was removed
  Future<bool> _onLoop() async {
    final DateTime now = DateTime.now();
    if (priority == GameEventPriority.INSTANT) {
      Logger.spamPeriodic(_stepLog, this, " instantly calling start onStep1 and remove");
      await onStart();
      final (GameEventStatus result, Duration delay) = await onStep1();
      if (result != GameEventStatus.DONE || delay != Duration.zero) {
        Logger.warn("$this should return GameEventStatus.DONE, Duration.zero in onStep1 instead of $result and $delay");
      }
      await remove();
    } else if (_delayedUntil == null || _delayedUntil!.isBefore(now)) {
      if (_currentStep != null) {
        if (!_alreadyCalledStart) {
          _alreadyCalledStart = true;
          Logger.spamPeriodic(_stepLog, this, " calling onStart and then the first onStep1");
          await onStart();
        }
        final (GameEventStatus result, Duration delay) = await _currentStep!.call();
        if (delay > Duration.zero) {
          _delayedUntil = now.add(delay);
        } else {
          _delayedUntil = null;
        }
        switch (result) {
          case GameEventStatus.SAME_STEP:
            Logger.spamPeriodic(_stepLog, this, " will stay on the same step"); // nothing else
          case GameEventStatus.DONE:
            _currentStep = null; // mark for deletion in next run, so that remove is called below
          case GameEventStatus.PREV_STEP:
            if (await _prevStep()) {
              return true;
            }
          case GameEventStatus.NEXT_STEP:
            if (await _nextStep()) {
              return true;
            }
        }
        return false;
      } else {
        await remove();
      }
    }
    return true;
  }

  /// Returns true if this was removed
  Future<bool> _prevStep() async {
    int stepCount = 0;
    if (_currentStep == onStep1) {
      Logger.warn("GameEvent $this tried to go to previous step when it was on onStep1, deleting...");
      await remove();
      return true;
    } else if (_currentStep == onStep2) {
      _currentStep = onStep1;
      stepCount = 1;
    } else if (_currentStep == onStep3) {
      _currentStep = onStep2;
      stepCount = 2;
    } else if (_currentStep == onStep4) {
      _currentStep = onStep3;
      stepCount = 3;
    } else if (_currentStep == onStep5) {
      _currentStep = onStep4;
      stepCount = 4;
    } else if (_currentStep == onStep6) {
      _currentStep = onStep5;
      stepCount = 5;
    } else if (_currentStep == onStep7) {
      _currentStep = onStep6;
      stepCount = 6;
    } else if (_currentStep == onStep8) {
      _currentStep = onStep7;
      stepCount = 7;
    } else if (_currentStep == onStep9) {
      _currentStep = onStep8;
      stepCount = 8;
    } else if (_currentStep == onStep10) {
      _currentStep = onStep9;
      stepCount = 9;
    } else if (_currentStep == onStep11) {
      _currentStep = onStep10;
      stepCount = 10;
    } else if (_currentStep == onStep12) {
      _currentStep = onStep11;
      stepCount = 11;
    } else if (_currentStep == onStep13) {
      _currentStep = onStep12;
      stepCount = 12;
    } else if (_currentStep == onStep14) {
      _currentStep = onStep13;
      stepCount = 13;
    } else if (_currentStep == onStep15) {
      _currentStep = onStep14;
      stepCount = 14;
    }
    Logger.spamPeriodic(_stepLog, this, " moves to the previous step ", stepCount);
    return false;
  }

  /// Returns true if this was removed
  Future<bool> _nextStep() async {
    int stepCount = 0;
    if (_currentStep == onStep1) {
      _currentStep = onStep2;
      stepCount = 2;
    } else if (_currentStep == onStep2) {
      _currentStep = onStep3;
      stepCount = 3;
    } else if (_currentStep == onStep3) {
      _currentStep = onStep4;
      stepCount = 4;
    } else if (_currentStep == onStep4) {
      _currentStep = onStep5;
      stepCount = 5;
    } else if (_currentStep == onStep5) {
      _currentStep = onStep6;
      stepCount = 6;
    } else if (_currentStep == onStep6) {
      _currentStep = onStep7;
      stepCount = 7;
    } else if (_currentStep == onStep7) {
      _currentStep = onStep8;
      stepCount = 8;
    } else if (_currentStep == onStep8) {
      _currentStep = onStep9;
      stepCount = 9;
    } else if (_currentStep == onStep9) {
      _currentStep = onStep10;
      stepCount = 10;
    } else if (_currentStep == onStep10) {
      _currentStep = onStep11;
      stepCount = 11;
    } else if (_currentStep == onStep11) {
      _currentStep = onStep12;
      stepCount = 12;
    } else if (_currentStep == onStep12) {
      _currentStep = onStep13;
      stepCount = 13;
    } else if (_currentStep == onStep13) {
      _currentStep = onStep14;
      stepCount = 14;
    } else if (_currentStep == onStep14) {
      _currentStep = onStep15;
      stepCount = 15;
    } else if (_currentStep == onStep15) {
      Logger.warn("GameEvent $this tried to go to next step when it was on onStep15, deleting...");
      await remove();
      return true;
    }
    Logger.spamPeriodic(_stepLog, this, " moves to the next step ", stepCount);
    return false;
  }

  @override
  String toString() => "$runtimeType(id: $_id, p: $priority, group: $_groups)";
}
