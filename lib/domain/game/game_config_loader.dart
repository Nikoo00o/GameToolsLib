part of 'package:game_tools_lib/game_tools_lib.dart';

/// This, or a subclass from this (with overridden [parseUnknownConfig]) can be used to load config values from the
/// config file of the game itself if needed. [readConfig] is called automatically in [GameToolsLib.initGameToolsLib]
/// and then afterwards you can access the config values with [value] or [hotkey].
///
/// Of course sub classes can also define getter methods for config values with static identifier key strings!
///
/// Important: sub classes should also override [gameLanguage] if its contained in the config and if you need
/// multi language assets!
base class GameConfigLoader {
  final String filePath;

  Map<String, String> _entries = <String, String>{};

  GameConfigLoader({
    required this.filePath,
  });

  /// Per default returns null, but should parse the game language from the config and convert it to a locale with
  /// [LocaleExtension.getLocaleByName] which then overrides the default of [GameToolsLib.gameLanguage] to be used for
  /// multi language [GTAsset].
  ///
  /// Of course you could also always return a static locale for the game here and always expect that!
  Locale? get gameLanguage => null;

  /// Returns true if the config was read successfully.
  /// If [filePath] ends with .ini then it will split config entries at "=" if the lines do not start with ";", or "["
  ///
  /// Else if [filePath] ends with .json then it will read the file as json and split config entries that way and
  /// convert values to string.
  ///
  /// Otherwise [parseUnknownConfig] is used which needs to be overridden in sub classes (or throws [ConfigException]).
  ///
  /// This is called automatically in [GameToolsLib.initGameToolsLib].
  Future<bool> readConfig() async {
    if (FileUtils.fileExists(filePath) == false) {
      Logger.error("Game Config $filePath does not exist!");
      return false;
    }
    final String data = await FileUtils.readFile(filePath);
    if (filePath.endsWith(".ini")) {
      final List<String> lines = StringUtils.splitIntoLines(data);
      _entries.clear();
      for (final String line in lines) {
        if (line.length <= 1 || line.startsWith("[") || line.startsWith(";")) {
          // skip comments and group tags and empty lines
        } else if (line.contains("=")) {
          final List<String> split = line.split("=");
          _entries[split[0]] = split[1];
        }
      }
    } else if (filePath.endsWith(".json")) {
      final Map<String, dynamic>? map = jsonDecode(data) as Map<String, dynamic>?;
      if (map != null) {
        _entries = map.map((String key, dynamic value) => MapEntry<String, String>(key, value?.toString() ?? ""));
      } else {
        Logger.error("Could not load json from Game Config $filePath");
        return false;
      }
    } else {
      _entries = parseUnknownConfig(data);
    }
    return true;
  }

  /// Should be overridden in sub classes to get the [_entries] from the [fileData] for config files that do not end
  /// with ".ini", or ".json". If not overridden, throws [ConfigException]
  Map<String, String> parseUnknownConfig(String fileData) =>
      throw ConfigException(message: "override GameConfigLoader.parseUnknownConfig in sub class to handle $filePath");

  /// Returns the config value for the [key] identifier of the config file. If it is not found, a [ConfigException]
  /// is thrown! You might need to parse this to your expected data type! For hotkeys use [hotkey]!
  String value(String key) {
    final String? value = _entries[key];
    if (value == null) {
      throw ConfigException(message: "Game config value for identifier $key not found in $filePath");
    }
    return value;
  }

  /// Similar to [value], but tries to directly get a shortcut [BoardKey] from the [key] which might return null if
  /// it could not be parsed. This converts integer char codes, but also directly converts characters. And it can
  /// also parse additional modifier keys like shift, control, alt in addition to the key separated with either "+",
  /// "-", ",", or " ".
  ///
  /// This might not be able to parse special language/region specific keys!
  BoardKey? hotkey(String key) {
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
          keys.add(LogicalKeyboardKeyExtension.fromPlatformCode(int.parse(current)));
        } else {
          keys.add(LogicalKeyboardKeyExtension.fromString(current));
        }
      }
      return BoardKey.fromLogicalKeys(keys);
    } catch (e) {
      Logger.warn("Could not parse config hotkey from $key", e);
      return null;
    }
  }

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
