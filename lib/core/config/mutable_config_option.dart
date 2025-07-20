part of 'package:game_tools_lib/core/config/mutable_config.dart';

/// Config option that is stored in a file for usage in [MutableConfig]
///
/// Values of type [T] may also be [null]
///
/// Use [getValue], [valueNotNull], [setValue], [deleteValue] to interact with the value.
/// You can also use the [_updateCallback] to get updates after [setValue] before the other listeners from the
/// [ChangeNotifier] will get notified. Remember that you can also manage those listeners manually with [addListener]
/// and [removeListener]! Remember that on startup at the end of [GameToolsLib.initGameToolsLib] this is also
/// notified for updates once!
///
/// You can also access the cached value in a sync way with [cachedValue] (But [getValue] needs to be called at least
/// once before!)
sealed class MutableConfigOption<T> with ChangeNotifier {
  /// The key to locate this saved value in the database (must be a unique identifier string).
  /// But also the identifier label text (or translation key) for the ui (if this config option is editable in ui)
  final String key;

  /// Added to the [key] internally in the storage
  static const String KEY_PREFIX = "CONFIG_";

  /// Cached Value
  T? _value;

  /// Optional update callback that is called after [setValue] to update data references elsewhere
  FutureOr<void> Function(T?)? _updateCallback;

  /// Optional default value that will be used if saved data is null (if [setValue] is called with [null], or
  /// [deleteValue] is called, then this will also be set to [null]
  T? defaultValue;

  /// For larger data sets this should be [true] to only load the data into memory on demand when its used.
  /// Defaults to [false] where all data is always kept in memory since the start of the program when the database is
  /// initialized!
  final bool _lazyLoaded;

  /// [updateCallback] Optional update callback that is called after [setValue] to update data references elsewhere
  /// and it is also called once at the end of [GameToolsLib.initGameToolsLib] on startup!
  /// [lazyLoaded] For big data this should be [true] to load on demand. Defaults to [false] (all data is kept in memory)
  MutableConfigOption({
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
  /// Also updates [_value]. And if [updateListeners] is true, this will also call [_onValueChange] if this loaded
  /// different new that than the current value (mostly not used)!
  Future<T?> getValue({bool updateListeners = false}) async {
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
    final T? newData = _stringToData(await _read());
    if (updateListeners) {
      await _onValueChange(newData); // update cache
    } else {
      _value = newData;
      if (newData != _value) {
        Logger.verbose("First load called for $this");
      }
    }
    return _value;
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
  /// Only sets [_value] and calls [_onValueChange] (unawaited!), but does not call [_write] to storage.
  void onlyUpdateCachedValue(T? data) {
    unawaited(_onValueChange(data)); // updates cache
  }

  /// Converts and writes the value and calls [_onValueChange] afterwards. And also updates the [_value].
  /// Can also explicitly set the stored [_value] to [null] so that null is returned instead of the [defaultValue].
  Future<void> setValue(T? data) async {
    await _write(_dataToString(data));
    await _onValueChange(data); // updates cache
  }

  /// Deletes from storage (NOT THE SAME AS SETTING TO NULL).
  /// Also updates [_value]
  Future<void> deleteValue() async {
    await GameToolsLib.database.deleteFromHive(
      key: _transformedKey,
      databaseKey: _dataBase,
    );
    await _onValueChange(null); // updates cache
  }

  /// This will be called at the end of [onlyUpdateCachedValue], [setValue] and [deleteValue] (and conditionally also
  /// in [getValue] to first change the [_value] and then if it was different than the old data call
  /// [_updateCallback] first and [notifyListeners] afterwards to update the listeners when this config option was
  /// changed.
  ///
  /// This is also called once on startup at the end of [GameToolsLib.initGameToolsLib] when all config
  /// values get loaded!
  ///
  /// Remember that this can also throw the exceptions of the [_updateCallback] if its set!
  Future<void> _onValueChange(T? data) async {
    final bool changed = _value != data;
    _value = data; // first change data
    if (changed) {
      Logger.debug("$this changed and updated listeners");
      await _updateCallback?.call(_value);
      notifyListeners();
    }
  }

  @override
  String toString() => "$runtimeType(key: $key, value: $_value)";

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
