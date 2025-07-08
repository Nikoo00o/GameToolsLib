part of 'package:game_tools_lib/core/config/mutable_config.dart';

/// Config option that is stored in a file for usage in [MutableConfig]
///
/// Values of type [T] may also be [null]
///
/// Use [getValue], [valueNotNull], [setValue], [deleteValue] to interact with the value. You can also use the
/// [_updateCallback] to get updates after [setValue].
///
/// You can also access the cached value in a sync way with [cachedValue] (But [getValue] needs to be called at least
/// once before!)
sealed class _MutableConfigOption<T> {
  /// The key to locate this saved value in the database (must be a unique identifier string).
  /// You can also use spaces to make the identifier more readable when this is used to build config option ui elements
  final String key;

  /// Added to the [key] internally in the storage
  static const String KEY_PREFIX = "CONFIG_";

  /// Cached Value
  T? _value;

  /// Optional update callback that is called after [setValue] to update data references elsewhere
  final FutureOr<void> Function(T?)? _updateCallback;

  /// Optional default value that will be used if saved data is null (if [setValue] is called with [null], or
  /// [deleteValue] is called, then this will also be set to [null]
  T? defaultValue;

  /// For larger data sets this should be [true] to only load the data into memory on demand when its used.
  /// Defaults to [false] where all data is always kept in memory since the start of the program when the database is
  /// initialized!
  final bool _lazyLoaded;

  /// [updateCallback] Optional update callback that is called after [setValue] to update data references elsewhere.
  /// [lazyLoaded] For big data this should be [true] to load on demand. Defaults to [false] (all data is kept in memory)
  _MutableConfigOption({
    required this.key,
    FutureOr<void> Function(T?)? updateCallback,
    this.defaultValue,
    bool lazyLoaded = false,
  }) : _updateCallback = updateCallback,
       _lazyLoaded = lazyLoaded;

  String get _transformedKey => "$KEY_PREFIX$key";

  String get _dataBase => _lazyLoaded ? HiveDatabase.LAZY_DATABASE : HiveDatabase.INSTANT_DATABASE;

  /// Converts and reads the value, or [defaultValue] if data was never set (or deleted with [deleteValue]]
  ///
  /// Also updates [_value]
  Future<T?> getValue() async {
    if (_value != null) {
      return _value;
    }
    final bool exists = await GameToolsLib.database.existsInHive(
      key: _transformedKey,
      databaseKey: _dataBase,
    );
    if (exists == false) {
      return defaultValue; // if it was never set (but also not explicitly set to null), return default
    }
    return _value ??= _stringToData(await _read()); // update cache
  }

  /// Uses [getValue], but throws a [ConfigException] if the data is null and no [defaultValue] is set
  Future<T> valueNotNull() async {
    final T? data = await getValue();
    if (data != null) {
      return data;
    } else {
      throw ConfigException(message: "Config option is not nullable, but data is null");
    }
  }

  /// Returns the [_value] if its not null and otherwise the [defaultValue]
  /// Can return null if both are null. This should only be called after [getValue] was called at least once!
  ///
  /// IMPORTANT: this can not check if the database has an explicit null value and it would still return the
  /// [defaultValue] even tho its not the correct behaviour!
  T? cachedValue() {
    return _value ?? defaultValue;
  }

  /// Uses [cachedValue], but throws a [ConfigException] if the data is null and no [defaultValue] is set
  T cachedValueNotNull() {
    final T? data = cachedValue();
    if (data != null) {
      return data;
    } else {
      throw ConfigException(message: "Config option is not nullable, but cached data is null");
    }
  }

  /// Mostly only used for testing without any other purpose.
  /// Only sets [_value] and calls [_updateCallback] (unawaited!), but does not call [_write] to storage.
  /// Remember that this can also throw the exceptions of the [_updateCallback] if its set!
  /// And if [_updateCallback], then it might not finish after this method returns!
  void onlyUpdateCachedValue(T? data) {
    _value = data;
    _updateCallback?.call(data);
  }

  /// Converts and writes the value and calls the [_updateCallback] afterwards. And also updates the [_value].
  /// Can also explicitly set the stored [_value] to [null] so that null is returned instead of the [defaultValue].
  /// Remember that this can also throw the exceptions of the [_updateCallback] if its set!
  Future<void> setValue(T? data) async {
    _value = data; // update cache
    await _write(_dataToString(data));
    await _updateCallback?.call(data);
  }

  /// Deletes from storage (NOT THE SAME AS SETTING TO NULL).
  /// Also updates [_value]
  Future<void> deleteValue() async {
    _value = null; // update cache!
    return GameToolsLib.database.deleteFromHive(
      key: _transformedKey,
      databaseKey: _dataBase,
    );
  }

  /// Loads from storage
  Future<String?> _read() async {
    return GameToolsLib.database.readFromHive(
      key: _transformedKey,
      databaseKey: _dataBase,
    );
  }

  /// Saves to storage
  Future<void> _write(String? str) async {
    return GameToolsLib.database.writeToHive(
      key: _transformedKey,
      value: str,
      databaseKey: _dataBase,
    );
  }

  /// Overridden in sub classes for special data conversion that does not use [toString]
  String? _dataToString(T? data) {
    if (T == String) {
      return data as String?;
    }
    return data?.toString();
  }

  /// Overridden in sub classes for data conversion that does not use [parse]
  T? _stringToData(String? str) {
    if (str == null) {
      return null;
    }
    if (T == bool) {
      return bool.parse(str) as T;
    } else if (T == int) {
      return int.parse(str) as T;
    } else if (T == double) {
      return double.parse(str) as T;
    } else if (T == String) {
      return str as T;
    }
    throw UnimplementedError("Type $T is not supported yet and cannot convert $str");
  }
}

/// Wrapper class for the typedefs
final class _TypeConfigOption<T> extends _MutableConfigOption<T> {
  _TypeConfigOption({
    required super.key,
    super.updateCallback,
    super.defaultValue,
    super.lazyLoaded = false,
  });
}

/// Used for bool config options
typedef BoolConfigOption = _TypeConfigOption<bool>;

/// Used for int config options
typedef IntConfigOption = _TypeConfigOption<int>;

/// Used for double config options
typedef DoubleConfigOption = _TypeConfigOption<double>;

/// Used for string config options
typedef StringConfigOption = _TypeConfigOption<String>;

/// Used to store an entity/object implementing the [Model] interface and supporting to/from json conversion!
///
/// Important: you need to supply a [_createNewModelInstance] function that creates a new instance of your specific
/// model subclass [T] with the given json map by calling its [fromJson] factory constructor
///
/// As An example look at [createNewExampleModelInstance]
final class ModelConfigOption<T extends Model> extends _MutableConfigOption<T> {
  /// function that creates a new instance of [T] by calling its fromJson factory constructor
  final T Function(Map<String, dynamic> json) _createNewModelInstance;

  /// [updateCallback] Optional update callback that is called after [setValue] to update data references elsewhere.
  /// [lazyLoaded] For big data this should be [true] to load on demand. Defaults to [false] (all data is kept in memory)
  /// [createNewModelInstance] function that creates a new instance of [T] by calling its fromJson factory constructor
  ModelConfigOption({
    required T Function(Map<String, dynamic> json) createNewModelInstance,
    required super.key,
    super.updateCallback,
    super.defaultValue,
    super.lazyLoaded,
  }) : _createNewModelInstance = createNewModelInstance;

  @override
  String? _dataToString(T? data) {
    if (data == null) {
      return null;
    }
    return jsonEncode(data.toJson());
  }

  @override
  T? _stringToData(String? str) {
    if (str == null) {
      return null;
    }
    final Map<String, dynamic>? json = jsonDecode(str) as Map<String, dynamic>?;
    if (json == null) {
      return null;
    }
    return _createNewModelInstance.call(json);
  }

  /// Example for how [createNewModelInstance] functions should look
  static ExampleModel createNewExampleModelInstance(Map<String, dynamic> json) => ExampleModel.fromJson(json);
}

/// Custom Config option where you have the freedom of deciding how to convert a string into your data of type [T] by
/// using the [_createNewInstance] callback.
///
/// For the other way around, [toString] will just be called on your object of type [T]
final class CustomConfigOption<T> extends _MutableConfigOption<T> {
  /// function that creates a new instance of [T] (or return null)
  final T? Function(String? str) _createNewInstance;

  /// [updateCallback] Optional update callback that is called after [setValue] to update data references elsewhere.
  /// [lazyLoaded] For big data this should be [true] to load on demand. Defaults to [false] (all data is kept in memory)
  /// [createNewInstance] function that creates a new instance of [T] (or return null)
  CustomConfigOption({
    required T? Function(String? str) createNewInstance,
    required super.key,
    super.updateCallback,
    super.defaultValue,
    super.lazyLoaded,
  }) : _createNewInstance = createNewInstance;

  @override
  T? _stringToData(String? str) => _createNewInstance.call(str);
}

/// Special case: LogLevel as a config option
final class LogLevelConfigOption extends _MutableConfigOption<LogLevel> {
  LogLevelConfigOption({
    required super.key,
    super.updateCallback,
    super.defaultValue,
    super.lazyLoaded,
  });

  @override
  LogLevel? _stringToData(String? str) {
    if (str == null) {
      return null;
    }
    return LogLevel.fromString(str);
  }
}
