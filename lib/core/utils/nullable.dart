/// Manages nullable parameter for copyWith constructors.
///
/// If the Nullable Object itself is null, then it will not be used. Otherwise it's value is used to override the previous
/// value (with either null, or a concrete value)
class Nullable<T> {
  final T? _value;

  const Nullable(this._value);

  T? get value => _value;
}
