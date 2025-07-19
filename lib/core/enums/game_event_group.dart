import 'package:game_tools_lib/game_tools_lib.dart' show GameEvent;

/// This is used to group up different [GameEvent] together.
/// If you want to assign multiple groups to an event, then use the bitwise OR operator [|] to put them together (and
/// call the constructor of the event). Or just use [GameEvent.addToGroup] and [GameEvent.removeFromGroup].
/// The group of an event can also be tested with [GameEvent.isInGroup]
///
/// The groups are listed below as static values ([no_group] is special case for when an event is in no group) like
/// [group1], [group2], etc. There are 30 groups in total.
final class GameEventGroup {
  /// Stored bit mask to test for groups
  final int bitValue;

  /// Special case, the event is in no group!
  static const GameEventGroup no_group = GameEventGroup(0x00);

  static const GameEventGroup group1 = GameEventGroup(0x001);

  static const GameEventGroup group2 = GameEventGroup(0x002);

  static const GameEventGroup group3 = GameEventGroup(0x004);

  static const GameEventGroup group4 = GameEventGroup(0x008);

  static const GameEventGroup group5 = GameEventGroup(0x010);

  static const GameEventGroup group6 = GameEventGroup(0x020);

  static const GameEventGroup group7 = GameEventGroup(0x040);

  static const GameEventGroup group8 = GameEventGroup(0x080);

  static const GameEventGroup group9 = GameEventGroup(0x0000100);

  static const GameEventGroup group10 = GameEventGroup(0x000200);

  static const GameEventGroup group11 = GameEventGroup(0x000400);

  static const GameEventGroup group12 = GameEventGroup(0x000800);

  static const GameEventGroup group13 = GameEventGroup(0x001000);

  static const GameEventGroup group14 = GameEventGroup(0x002000);

  static const GameEventGroup group15 = GameEventGroup(0x004000);

  static const GameEventGroup group16 = GameEventGroup(0x008000);

  static const GameEventGroup group17 = GameEventGroup(0x010000);

  static const GameEventGroup group18 = GameEventGroup(0x020000);

  static const GameEventGroup group19 = GameEventGroup(0x040000);

  static const GameEventGroup group20 = GameEventGroup(0x080000);

  static const GameEventGroup group21 = GameEventGroup(0x100000);

  static const GameEventGroup group22 = GameEventGroup(0x200000);

  static const GameEventGroup group23 = GameEventGroup(0x400000);

  static const GameEventGroup group24 = GameEventGroup(0x800000);

  static const GameEventGroup group25 = GameEventGroup(0x1000000);

  static const GameEventGroup group26 = GameEventGroup(0x2000000);

  static const GameEventGroup group27 = GameEventGroup(0x4000000);

  static const GameEventGroup group28 = GameEventGroup(0x8000000);

  static const GameEventGroup group29 = GameEventGroup(0x10000000);

  static const GameEventGroup group30 = GameEventGroup(0x20000000);

  const GameEventGroup(this.bitValue);

  GameEventGroup operator |(GameEventGroup other) => GameEventGroup(bitValue | other.bitValue);

  GameEventGroup operator &(GameEventGroup other) => GameEventGroup(bitValue & other.bitValue);

  /// Bitwise negation
  GameEventGroup get inverted => GameEventGroup(~bitValue);

  @override
  bool operator ==(Object other) => identical(this, other) || other is GameEventGroup && bitValue == other.bitValue;

  @override
  int get hashCode => bitValue.hashCode;

  @override
  String toString() => "GameEventGroup($bitValue)";
}
