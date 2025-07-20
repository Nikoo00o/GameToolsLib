import 'dart:collection';

import 'package:game_tools_lib/core/utils/immutable_equatable.dart';
import 'package:game_tools_lib/core/utils/list_utils.dart';
import 'package:game_tools_lib/core/utils/nullable.dart';

/// Base class for all entities. Entities should made immutable with only final members most of the times!
///
/// If an entity does have non-final values that can be changed and should be used in comparison, override the
/// [props], or [properties] getter (look at [ImmutableEquatable] for more details and restrictions).
///
/// Otherwise use the [properties] map of the constructor and pass all final member variables that will be used for
/// comparison with description keys.
///
/// Best practice is to always make sub classes of this class immutable with only final members and then provide a
/// copyWith function that returns a new object with modified members!
///
/// For An example look at [ExampleEntity]
abstract base class Entity extends ImmutableEquatable {
  const Entity(super.properties);

  /// This can be returned inside of the [operator ==] if you want to compare the entities without their runtimetype.
  ///
  /// This is useful so that comparing models and entities still returns true!
  bool compareWithoutRuntimeType(Object other) =>
      identical(this, other) || other is Entity && ListUtils.equals(props, other.props);
}

/// An Example on how to create an entity that is unmodifiable (except by creating a new one with the [copyWith]
/// constructor.
base class ExampleEntity extends Entity {
  /// Unmodifiable Optional Nullable Data
  final int? someData;

  /// In theory this data could be modified, so it would be better to only allow access with an unmodifiable list
  final List<ExampleEntity> _modifiableData;

  /// Returns unmodifiable reference to [_modifiableData]
  UnmodifiableListView<ExampleEntity> get modifiableData => UnmodifiableListView<ExampleEntity>(_modifiableData);

  /// Constructor passes values for print and equality comparison in map
  ExampleEntity({
    this.someData,
    required List<ExampleEntity> modifiableData,
  }) : _modifiableData = modifiableData,
       super(<String, Object?>{
         "someData": someData,
         "modifiableData": modifiableData,
       });

  /// Method to change values of this entity by making a deep copy
  ///
  /// Important here is that [newSomeData] has a [Nullable] wrapper so it can also explicitly be set to null!
  ExampleEntity copyWith({
    Nullable<int>? newSomeData,
    List<ExampleEntity>? newModifiableData,
  }) {
    return ExampleEntity(
      someData: newSomeData != null ? newSomeData.value : someData,
      modifiableData: newModifiableData ?? _modifiableData,
    );
  }
}
