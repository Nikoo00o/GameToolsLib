part of 'package:game_tools_lib/game_tools_lib.dart';

/// This, or a subclass from this (with overridden [parseUnknownConfig]) can be used to load config values from the
/// config file of the game itself if needed. [readConfig] is called automatically in [GameToolsLib.initGameToolsLib]
/// and then afterwards you can access the config values with [value] or [hotkey]. Also periodically
/// [reloadConfigIfChanged] is automatically called from [GameToolsLib.runLoop]!
///
/// Of course sub classes can also define getter methods for config values with static identifier key strings!
///
/// Important: sub classes should also override [gameLanguage] if its contained in the config and if you need
/// multi language assets! And they may also override [parseHotkeyFromInt] and [parseHotkeyFromString] for hotkey
/// loading.
base class GameConfigLoader {
  final String filePath;

  Map<String, String> _entries = <String, String>{};

  /// Set in first [readConfig] call!
  DateTime? _lastModified;

  late final int _maxTicks = FixedConfig.fixedConfig.overlayRefreshTicks;
  late int _currentTicks = _maxTicks;

  /// Contains pattern with key, listener
  final List<(String, void Function())> _updateListeners = <(String, void Function())>[];

  GameConfigLoader({
    required this.filePath,
  }) {
    GameToolsLib.checkMultiInstance<GameConfigLoader>(this);
  }

  /// Per default returns null, but should parse the game language from the config and convert it to a locale with
  /// [LocaleExtension.getLocaleByName] which then overrides the default of [GameToolsLib.gameLanguage] to be used for
  /// multi language [GTAsset].
  ///
  /// Of course you could also always return a static locale for the game here and always expect that!
  Locale? get gameLanguage => null;

  /// Automatically called periodically from [GameToolsLib.runLoop] which just calls [readConfig] every
  /// [FixedConfig.overlayRefreshTicks]!
  Future<void> reloadConfigIfChanged() async {
    if (_currentTicks++ >= _maxTicks) {
      _currentTicks = 0;
      await readConfig();
    }
  }

  /// Returns true if the config was read successfully. Only loads new config data if the file was modified since the
  /// last call to this (see [_lastModified]).
  ///
  /// If [filePath] ends with .ini then it will split config entries at "=" if the lines do not start with ";", or "["
  ///
  /// Else if [filePath] ends with .json then it will read the file as json and split config entries that way and
  /// convert values to string.
  ///
  /// Otherwise [parseUnknownConfig] is used which needs to be overridden in sub classes (or throws [ConfigException]).
  ///
  /// This is called automatically in [GameToolsLib.initGameToolsLib].
  Future<InitResult> readConfig() async {
    final DateTime? newModified = FileUtils.lastModified(filePath);
    if (newModified == null) {
      Logger.error("Game Config $filePath does not exist!");
      return InitResult.GAME_CONFIG_NOT_FOUND;
    }
    if (_lastModified != null && !newModified.isAfter(_lastModified!) && _entries.isNotEmpty) {
      return InitResult.SUCCESS; // skip loading because it was not changed!
    }
    _lastModified = newModified;
    final String data = await FileUtils.readFile(filePath);
    Map<String, String> newEntries = <String, String>{};
    if (filePath.endsWith(".ini")) {
      final List<String> lines = StringUtils.splitIntoLines(data);
      for (final String line in lines) {
        if (line.length <= 1 || line.startsWith("[") || line.startsWith(";")) {
          // skip comments and group tags and empty lines
        } else if (line.contains("=")) {
          final List<String> split = line.split("=");
          newEntries[split[0]] = split[1];
        }
      }
    } else if (filePath.endsWith(".json")) {
      final Map<String, dynamic>? map = jsonDecode(data) as Map<String, dynamic>?;
      if (map != null) {
        newEntries = map.map((String key, dynamic value) => MapEntry<String, String>(key, value?.toString() ?? ""));
      } else {
        Logger.error("Could not load json from Game Config $filePath");
        return InitResult.GAME_CONFIG_INVALID;
      }
    } else {
      newEntries = parseUnknownConfig(data);
    }
    _updateEntries(newEntries);
    return InitResult.SUCCESS;
  }

  /// Only used in [readConfig]
  void _updateEntries(Map<String, String> newEntries) {
    final Map<String, String> oldEntries = _entries;
    _entries = newEntries;
    for (final (String, void Function()) listener in _updateListeners) {
      final String key = listener.$1;
      if (newEntries[key] != oldEntries[key]) {
        listener.$2.call();
      }
    }
  }

  /// Should be overridden in sub classes to get the [_entries] from the [fileData] for config files that do not end
  /// with ".ini", or ".json". If not overridden, throws [ConfigException]
  Map<String, String> parseUnknownConfig(String fileData) =>
      throw ConfigException(message: "override GameConfigLoader.parseUnknownConfig in sub class to handle $filePath");

  /// Needs to be called if [value] or [hotkey] are frequently used with listeners that should be removed again.
  /// Removes the function pointer by reference.
  void removeUpdateListener(void Function() updateListener) {
    _updateListeners.removeWhere(((String, void Function()) pattern) => pattern.$2 == updateListener);
  }

  /// Returns the config value for the [key] identifier of the config file. If it is not found, a [ConfigException]
  /// is thrown! You might need to parse this to your expected data type! For hotkeys use [hotkey]!
  ///
  /// Optionally you can also pass a [updateListener] which will be called if the value changes (on config reload).
  /// IMPORTANT: only use an unnamed lambda callback function if you use this during the constructor of a long lived
  /// class. Otherwise you should use pointers to member functions (or function variables) that you remove with a
  /// call to [removeUpdateListener] after your work is done! Inside of the update listener you can then use your
  /// custom getter to get your variable (but remember to not add another listener inside of the callback!!!).
  String value(String key, {void Function()? updateListener}) {
    final String? value = _entries[key];
    if (value == null) {
      throw ConfigException(message: "Game config value for identifier $key not found in $filePath");
    }
    if (updateListener != null) {
      _updateListeners.add((key, updateListener));
    }
    return value;
  }

  /// Similar to [value], but tries to directly get a shortcut [BoardKey] from the [key] which might return null if
  /// it could not be parsed. This converts integer char codes, but also directly converts characters. And it can
  /// also parse additional modifier keys like shift, control, alt in addition to the key separated with either "+",
  /// "-", ",", or " ".
  ///
  /// This might not be able to parse special language/region specific keys!
  ///
  /// Optionally you can also pass a [updateListener] which will be called if the value changes (on config reload).
  /// IMPORTANT: only use an unnamed lambda callback function if you use this during the constructor of a long lived
  /// class. Otherwise you should use pointers to member functions (or function variables) that you remove with a
  /// call to [removeUpdateListener] after your work is done! Inside of the update listener you can then use your
  /// custom getter to get your variable (but remember to not add another listener inside of the callback!!!).
  /// The listener is only added if this completes successfully!
  ///
  /// This uses both [parseHotkeyFromInt] and [parseHotkeyFromString] which may be overridden.
  BoardKey? hotkey(String key, {void Function()? updateListener}) {
    final String value = this.value(key);
    final List<String> split = <String>[];
    if (value.length > 1) {
      _splitAtChar("+", split, value);
      _splitAtChar(",", split, value);
      _splitAtChar("-", split, value);
      _splitAtChar(" ", split, value);
    }
    if (split.isEmpty) {
      split.add(value);
    }
    final List<LogicalKeyboardKey> keys = <LogicalKeyboardKey>[];
    final RegExp isNumeric = RegExp(r"^\d*$");
    try {
      for (final String current in split) {
        if (isNumeric.hasMatch(current)) {
          keys.add(parseHotkeyFromInt(int.parse(current)));
        } else {
          keys.add(parseHotkeyFromString(current));
        }
      }
      if (updateListener != null) {
        _updateListeners.add((key, updateListener));
      }
      return BoardKey.fromLogicalKeys(keys);
    } catch (e) {
      Logger.warn("Could not parse config hotkey from $key", e);
      return null;
    }
  }

  @protected
  /// In most cases just parses the keycode, but could also have specific meaning for modifier keys like for example "
  /// 1" = shift, "2"= ctrl, "3" = alt. May be overridden for custom loading in [hotkey] from config.
  LogicalKeyboardKey parseHotkeyFromInt(int keyCode) => switch (keyCode) {
    1 => LogicalKeyboardKey.shift,
    2 => LogicalKeyboardKey.control,
    3 => LogicalKeyboardKey.alt,
    _ => LogicalKeyboardKeyExtension.fromPlatformCode(keyCode),
  };

  @protected
  /// Per default just parses a named key. May be overridden for custom loading in [hotkey] from config.
  LogicalKeyboardKey parseHotkeyFromString(String keyName) => LogicalKeyboardKeyExtension.fromString(keyName);

  void _splitAtChar(String char, List<String> split, String value) {
    if (split.isEmpty && value.contains(char)) {
      split.addAll(value.split(char));
    }
  }

  /// Concrete instance of this controlled by [GameToolsLib]
  static GameConfigLoader? _instance;

  /// Returns the the [GameConfigLoader._instance] if it is set, otherwise throws a [ConfigException]
  ///
  /// But this can also be accessed with a nullable type to not throw an exception in that case!
  static T configLoader<T extends GameConfigLoader?>() {
    if (_instance == null) {
      if (null is T) {
        return null as T; // special case accessed with nullable type
      }
      throw const ConfigException(message: "GameConfigLoader was not initialized yet ");
    } else if (_instance is T) {
      return _instance as T;
    } else {
      throw ConfigException(message: "Wrong type $T for $_instance");
    }
  }
}
