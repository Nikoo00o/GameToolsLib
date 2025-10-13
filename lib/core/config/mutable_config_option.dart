part of 'package:game_tools_lib/core/config/mutable_config.dart';

/// Config option that is stored in a file for usage in [MutableConfig]
///
/// Important: if [T] is not nullable ("[T]?"), then [setValue] can not be used with [null] and [defaultValue] may
/// not be [null]!
///
/// Use [getValue], [valueNotNull], [setValue], [deleteValue] to interact with the value.
/// You can also use the [_updateCallback] to get updates after [setValue] before the other listeners from the
/// [ChangeNotifier] will get notified. Remember that you can also manage those listeners manually with [addListener]
/// and [removeListener]!
///
/// Remember that on startup at the end of [GameToolsLib.initGameToolsLib] the [onInit] is called if not null for the
/// config options contained in [MutableConfig.getConfigurableOptions] together with a call to [getValue] with
/// updateListeners being false to load those options once! Otherwise it will be called when this object is first used.
/// Use this if your config option needs to access other config options, or needs any initialisation!
///
/// You can also access the cached value in a sync way with [cachedValue] (But [getValue] needs to be called at least
/// once before!) (or also [cachedValueNotNull])
///
/// Remember for the ui the [builder] has to be overridden and also [title] and [description] are needed if
/// this option is included in [MutableConfig.getConfigurableOptions]!
sealed class MutableConfigOption<T> with ChangeNotifier {
  /// The [TranslationString.identifier] is used to locate this saved value in the database (must be a unique
  /// identifier string). But this translation string is also used as the identifier label text (or translation
  /// key) for the ui (if this config option / is editable in ui)
  final TranslationString title;

  /// Optional description text for the ui to display in addition to the [title]
  final TranslationString? description;

  /// Added to the [title.identifier] internally in the storage
  static const String KEY_PREFIX = "CONFIG_";

  /// Cached Value loaded from storage and saved to storage
  T? _value;

  /// Optional update callback that is called after [setValue] to update data references elsewhere with the current
  /// [cachedValue] (which may be null depending on what is stored and the default)!
  final FutureOr<void> Function(T?)? _updateCallback;

  /// Optional default value that will be used if saved data is null (if [setValue] is called with [null] then this
  /// will be ignored until [deleteValue] is called). Important: if [T] is not nullable, then this is required!
  ///
  /// If there is a lot of code that's needed to create a const default value, consider moving the declaration to a
  /// different single file as a global static const object!
  final T? defaultValue;

  /// For larger data sets this should be [true] to only load the data into memory on demand when its used.
  /// Defaults to [false] where all data is always kept in memory since the start of the program when the database is
  /// initialized!
  final bool _lazyLoaded;

  /// Internal flag if this config option is currently saved to the storage
  bool _exists = false;

  /// see constructor, or general class configuration
  Future<void> Function(MutableConfigOption<dynamic> configOption)? _onInit;

  /// [updateCallback] Optional update callback that is called after [setValue] to update data references elsewhere!
  /// [lazyLoaded] For big data this should be [true] to load on demand. Defaults to [false] (all data is kept in memory)
  ///
  /// [onInit] is an optional callback that will be called once at the end of [GameToolsLib.initGameToolsLib] on startup
  /// for the config values contained in [MutableConfig.getConfigurableOptions]. Or otherwise the first time this
  /// object is used!
  ///
  /// This can be done for custom initialisation that needs the [FixedConfig] or anything else that is not
  /// initialized yet when the constructor is called.
  /// You have to cast the [configOption] to your type in the callback manually!
  MutableConfigOption({
    required this.title,
    this.description,
    FutureOr<void> Function(T?)? updateCallback,
    this.defaultValue,
    bool lazyLoaded = false,
    Future<void> Function(MutableConfigOption<dynamic> configOption)? onInit,
  }) : _updateCallback = updateCallback,
       _lazyLoaded = lazyLoaded,
       _onInit = onInit {
    if (defaultValue == null && Utils.isNullableType<T>() == false) {
      throw ConfigException(message: "$this had a not nullable type $T, but no default value!");
    }
  }

  /// Calls the [_onInit] which is an optional callback that will be called once at the end of
  /// [GameToolsLib.initGameToolsLib] on startup for the config values contained in
  /// [MutableConfig.getConfigurableOptions].
  ///
  /// Or otherwise it is called the first time this object is used (so in [getValue], [setValue], [deleteValue]!
  ///
  /// This can be done for custom initialisation that needs the [FixedConfig] or anything else that is not
  /// initialized yet when the constructor is called.
  /// You have to cast the [configOption] to your type in the callback manually!
  Future<void> onInit() async {
    if (_onInit != null) {
      await _onInit!.call(this);
      Logger.spam("Custom init callback called for ", this);
      _onInit = null;
    }
  }

  /// This has to be overridden in sub classes to return a subclass of [ConfigOptionBuilder] with a reference to this
  /// that will build the UI for the config option. [ConfigOptionBuilder.buildProviderWithContent] is then used to
  /// build the ui to configure this option!
  ///
  /// A subclass may also return null here, but then it may not be included in [MutableConfig.getConfigurableOptions]!
  ConfigOptionBuilder<T>? get builder;

  String get _transformedKey => "$KEY_PREFIX${title.identifier}";

  String get _dataBase => _lazyLoaded ? HiveDatabase.LAZY_DATABASE : HiveDatabase.INSTANT_DATABASE;

  /// This will instantly return the stored data [_value] if this exists on storage ([_exists] is true) and will not
  /// load it again!
  ///
  /// Otherwise it will update the status if this exists on storage and load new data from the storage  and then
  /// also update the cached data [_value].
  ///
  /// Then at the end it returns [cachedValue] which returns the [_value] if it [_exists] and otherwise the
  /// [defaultValue] (but of course both could be null by for example explicitly setting the stored data to null)
  ///
  /// If [updateListeners] is true, this will also call [_onValueChange] if this loaded a different new value that
  /// than the current value (this is only false at the end of [GameToolsLib.initGameToolsLib] where the
  /// [MutableConfig.getConfigurableOptions] are loaded)! And it being true affects only those config options not
  /// contained there when they are loaded for the first time!
  Future<T?> getValue({bool updateListeners = true}) async {
    if (_exists) {
      return _value;
    }
    await onInit();
    final bool exists = await _existsInStorage();
    final T? newData = exists ? _stringToData(await _read()) : null;
    if (updateListeners) {
      await _onValueChange(newData, exists); // update cache (only when current value not null)
    } else {
      _value = newData;
      _exists = exists;
      if (newData != _value) {
        Logger.verbose("First load called for $this");
      }
    }
    return cachedValue();
  }

  /// Uses [getValue], but throws a [ConfigException] if it would return null(and if the return type [T] is not
  /// nullable).
  ///
  /// This also has the special case that it first checks the stored value and if that one is null, it will also
  /// check the default value afterwards once (which is different behaviour!)
  Future<T> valueNotNull() async {
    final T? data = await getValue();
    if (data != null) {
      return data;
    } else if (defaultValue != null) {
      return defaultValue!;
    } else if (data is! T) {
      throw const ConfigException(message: "Config option is not nullable, but data is null");
    }
    return data;
  }

  /// Returns the stored data [_value] if this exists on storage ([_exists]) and otherwise it will return the default
  /// value!
  ///
  /// Of course in both cases it can return null (because you could explicitly store null in the database, or set the
  /// default value to null as well!)
  ///
  /// This should only be called after [getValue] was called at least once!
  T? cachedValue() {
    return _exists ? _value : defaultValue;
  }

  /// Uses [cachedValue], but throws a [ConfigException] if it would return null (and if the return type [T] is not
  /// nullable).
  ///
  /// This also has the special case that it first checks the stored value and if that one is null, it will also
  /// check the default value afterwards once (which is different behaviour!)
  T cachedValueNotNull() {
    final T? data = cachedValue();
    if (data != null) {
      return data;
    } else if (defaultValue != null) {
      return defaultValue!;
    } else if (data is! T) {
      throw const ConfigException(message: "Config option is not nullable, but cached data is null");
    }
    return data;
  }

  /// Mostly only used for testing without any other purpose (this can also not be used for deleting).
  /// Only sets the cached [_value] and calls [_onValueChange] (unawaited!), but does not call [_write] to storage.
  void onlyUpdateCachedValue(T data) {
    unawaited(_onValueChange(data, true)); // updates cache
  }

  /// Converts and writes the value and calls [_onValueChange] afterwards. And also updates the [_value].
  /// Can also explicitly set the stored [_value] to [null] (if [T] is nullable) so that null is returned instead of
  /// the [defaultValue]. To then have [cachedValue] return the [defaultValue] again, use [deleteValue] in the future.
  Future<void> setValue(T data) async {
    await onInit();
    await _write(_dataToString(data));
    await _onValueChange(data, true); // updates cache
  }

  /// Deletes from storage (NOT THE SAME AS SETTING TO NULL) so that [cachedValue] returns the [defaultValue] again.
  /// Also updates [_value] and sets exists to false!
  Future<void> deleteValue() async {
    await onInit();
    await GameToolsLib.database.deleteFromHive(
      key: _transformedKey,
      databaseKey: _dataBase,
    );
    await _onValueChange(null, false); // updates cache
  }

  /// This will be called at the end of [onlyUpdateCachedValue], [setValue] and [deleteValue] (and conditionally also
  /// in [getValue] to first change the [_value] and then if it was different than the old data call
  /// [_updateCallback] first and [notifyListeners] afterwards to update the listeners when this config option was
  /// changed.
  ///
  /// Remember that this can also throw the exceptions of the [_updateCallback] if its set!
  Future<void> _onValueChange(T? data, bool exists) async {
    late final bool changed;
    if (exists && !_exists) {
      changed = data != defaultValue;
    } else if (!exists && _exists) {
      changed = _value != defaultValue;
    } else {
      changed = _value != data;
    }
    _value = data; // first change data
    _exists = exists;
    if (changed) {
      Logger.debug("Updating config option listeners for new data for: $this");
      await _updateCallback?.call(cachedValue());
      notifyListeners();
    }
  }

  @override
  String toString() => "$runtimeType(key: $title, value: $_value)";

  /// First always check storage
  Future<bool> _existsInStorage() => GameToolsLib.database.existsInHive(
    key: _transformedKey,
    databaseKey: _dataBase,
  );

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
