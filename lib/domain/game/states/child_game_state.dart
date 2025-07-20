import 'package:flutter/foundation.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

/// This is also a base class for some specific game states which further modify/specify some parent state as a child
/// state and should be able to easily navigate back to the old state. (extends the default [GameState])
///
/// For this, the old previous state must be of [ParentStateType], otherwise [onStart] will throw a [StateException]!
///
/// Important: if you override [onStart] in sub classes of this, you must always call [super.onStart] first!
///
/// You can use [navigateBack] to navigate back to the previous [parentState]!
abstract base class ChildGameState<ParentStateType extends GameState> extends GameState {
  /// This contains the previous state which will be set in [onStart]
  late final ParentStateType parentState;

  @override
  @mustCallSuper
  Future<void> onStart(GameState oldState) async {
    if (oldState is ParentStateType) {
      parentState = oldState;
    } else {
      throw StateException(message: "State type of $oldState was not $ParentStateType for $this");
    }
  }

  /// Changes back to the previous [parentState]!
  void navigateBack() {
    GameToolsLib.changeState(parentState);
  }
}
