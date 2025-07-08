import 'package:equatable/equatable.dart';
import 'package:game_tools_lib/core/utils/string_utils.dart';


/// Used for easy comparison for immutable objects that only have final member variables which should be included in the
/// comparison. They will be passed to the constructor as a map with descriptions and they will be used with the
/// [properties] getter in the [props] getter which is then used for comparison.
///
/// This class overrides the operator== to not compare references, but the properties list instead!
///
/// Important: If the sub class has non-final members that can change and should be used for comparison, then you have to
/// override the [props], or [properties] getter and always return a new list of member variables which will be used,
/// because otherwise the changed data will not be used for comparison!
///
/// But: don't use mutable classes with non final fields for hash collections (for example map keys)!!!
///
/// If you have nested sub classes, then they either need to combine all properties maps together in the constructor, so
/// the final map includes all member variables, or you only use the properties map in the top most class to provide the
/// most member variables and then in sub classes you override the [props], or [properties] getter and add the remaining
/// members to the call of the getter of the super class.
///
/// Best practice is to always make sub classes of this class immutable with only final members and then provide a
/// copyWith function that returns a new object with modified members from the parameters!
/// If that function is used in a subclass, then all deeper sub classes should implement the method again. And if the same
/// parameters are used for example inside of a model for an entity, then it is a valid override for the method of the
/// entity and can also be called with an entity reference.
abstract class ImmutableEquatable extends Equatable {
  final Map<String, Object?> _properties;

  /// The keys of the [properties] map are descriptions for the values which should contain all final member variables of
  /// the sub class that should be used for comparison!
  const ImmutableEquatable(Map<String, Object?> properties) : _properties = properties;

  @override
  List<Object?> get props => properties.values.toList();

  /// Returns the properties map set in the constructor which is used for comparison and for the [toString] method.
  /// You could override this getter in a sub class to always return a new map of your member variables if you have non
  /// final members that are used for comparison and can change.
  Map<String, Object?> get properties => _properties;

  // The custom toString method is the main reason for this class
  @override
  String toString() {
    return StringUtils.toStringPretty(this, properties);
  }
}
