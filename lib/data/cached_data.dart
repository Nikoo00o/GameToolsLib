import 'package:flutter/foundation.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/file_utils.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

/// Helper class that can be used to store and load data to/from a json file in the [cacheFolderName] which would be
/// for example "data/dynamic_data/cache/name.json".
///
/// The will always at least provide a getter and setter for a [defaultValue] of type [T] with the
/// [defaultJsonIdentifier] being "default" which may be overridden in the sub class to other json tags for the story.
/// Of course this type [T] may only be one of the primitive types that are available to be stored in json String,
/// int, double, bool, List&rl;dynamic&rt;, Map&lt;String, dynamic&rt;! You can also directly use the default types
/// inside of List or Map as the type [T] for [defaultValue] like for example List of String, but not nested like List
/// of List of String. The type [T] may not be nullable!
///
/// Subclasses can then provider additional getter and setter for more member variables that should be stored by
/// using [get] and [set].
///
/// But of course you can also use the [defaultValue] as another map itself and instead of setting it, you just
/// modify it, but in that case you have to manually call [save] at the end of your member setter! Try to not call
/// [save] in the getters to avoid recursion when a listener accesses it! Also listeners may not call save themselves!
///
/// Writing to the json file will be sync blocking, so don't use large files here! And after reading into cache once it
/// will not be loaded from storage again! If the file does not exist yet, the getters will return null per default!
///
/// Important: of course [GameToolsLib.initGameToolsLib] must be called before accessing any member of this!
///
/// This can also be used as a change notifier and [save] will call [notifyListeners]!
base class CachedData<T> with ChangeNotifier {
  /// The base folder where all the cache files with [identifier].json are stored under!
  static String get cacheFolder =>
      FileUtils.combinePath(<String>[GameToolsConfig.baseConfig.dynamicDataFolder, "cache"]);

  /// Default json identifier for [defaultValue] "default" which may be overridden
  String get defaultJsonIdentifier => "default";

  /// Unique name that will also be the filename without file ending used to identify this!
  final String identifier;

  Map<String, dynamic>? _json;

  CachedData({required this.identifier});

  /// The path to this file
  String get path => FileUtils.combinePath(<String>[cacheFolder, "$identifier.json"]);

  Map<String, dynamic> _getJson() {
    if (_json == null) {
      _json = HiveDatabase.database.readJson(absoluteFilePath: path);
      if (_json == null) {
        _json = <String, dynamic>{};
        Logger.spam("CachedData ", identifier, " was not stored yet");
      } else {
        Logger.spam("CachedData ", identifier, " loaded from storage for the first time: ", _json);
      }
    }
    return _json!;
  }

  /// Returns a json value of [VT] for the [key] or null if it does not exist yet! This can directly convert a
  /// dynamic list into a list of any primitive allowed subtype and same with map, but not nested for list of list, etc!
  VT? get<VT>(String key) {
    dynamic dynValue = _getJson()[key];
    if (dynValue != null) {
      if (dynValue is List<dynamic>) {
        if (VT == List<String>) {
          _getJson()[key] = dynValue = List<String>.from(dynValue);
        } else if (VT == List<Map<String, dynamic>>) {
          _getJson()[key] = dynValue = List<Map<String, dynamic>>.from(dynValue);
        } else if (VT == List<List<dynamic>>) {
          _getJson()[key] = dynValue = List<List<dynamic>>.from(dynValue);
        } else if (VT == List<int>) {
          _getJson()[key] = dynValue = List<int>.from(dynValue);
        } else if (VT == List<double>) {
          _getJson()[key] = dynValue = List<double>.from(dynValue);
        } else if (VT == List<bool>) {
          _getJson()[key] = dynValue = List<bool>.from(dynValue);
        }
      } else if (dynValue is Map<String, dynamic>) {
        if (VT == Map<String, String>) {
          _getJson()[key] = dynValue = Map<String, String>.from(dynValue);
        } else if (VT == Map<String, Map<String, dynamic>>) {
          _getJson()[key] = dynValue = Map<String, Map<String, dynamic>>.from(dynValue);
        } else if (VT == Map<String, List<dynamic>>) {
          _getJson()[key] = dynValue = Map<String, List<dynamic>>.from(dynValue);
        } else if (VT == Map<String, int>) {
          _getJson()[key] = dynValue = Map<String, int>.from(dynValue);
        } else if (VT == Map<String, double>) {
          _getJson()[key] = dynValue = Map<String, double>.from(dynValue);
        } else if (VT == Map<String, bool>) {
          _getJson()[key] = dynValue = Map<String, bool>.from(dynValue);
        }
      }
    }
    return dynValue as VT?;
  }

  /// Stores the json [value] of [VT] for the [key] (can also be null!)!
  void set<VT>(String key, VT? value) {
    _getJson()[key] = value;
    save();
    Logger.spam("CachedData $identifier saved to storage");
  }

  /// Used to store changes into the file (called automatically by [set]. But first it will call [notifyListeners].
  void save() {
    notifyListeners();
    HiveDatabase.database.writeJson(absoluteFilePath: path, json: _getJson());
  }

  /// A default member of type [T] with identifier [defaultJsonIdentifier].
  ///
  /// Important: this will not return null if the value does not exist and instead return empty default values to be
  /// modified (which will not be saved yet tho)!
  ///
  /// This may throw a [ConfigException]
  T get defaultValue {
    final T? value = get<T>(defaultJsonIdentifier);
    if (value != null) {
      return value;
    }

    if (T == List<String>) {
      return _getJson()[defaultJsonIdentifier] = <String>[] as T;
    } else if (T == List<Map<String, dynamic>>) {
      return _getJson()[defaultJsonIdentifier] = <Map<String, dynamic>>[] as T;
    } else if (T == List<List<dynamic>>) {
      return _getJson()[defaultJsonIdentifier] = <List<dynamic>>[] as T;
    } else if (T == List<int>) {
      return _getJson()[defaultJsonIdentifier] = <int>[] as T;
    } else if (T == List<double>) {
      return _getJson()[defaultJsonIdentifier] = <double>[] as T;
    } else if (T == List<bool>) {
      return _getJson()[defaultJsonIdentifier] = <bool>[] as T;
    } else if (T == Map<String, String>) {
      return _getJson()[defaultJsonIdentifier] = <String, String>{} as T;
    } else if (T == Map<String, Map<String, dynamic>>) {
      return _getJson()[defaultJsonIdentifier] = <String, Map<String, dynamic>>{} as T;
    } else if (T == Map<String, List<dynamic>>) {
      return _getJson()[defaultJsonIdentifier] = <String, List<dynamic>>{} as T;
    } else if (T == Map<String, int>) {
      return _getJson()[defaultJsonIdentifier] = <String, int>{} as T;
    } else if (T == Map<String, double>) {
      return _getJson()[defaultJsonIdentifier] = <String, double>{} as T;
    } else if (T == Map<String, bool>) {
      return _getJson()[defaultJsonIdentifier] = <String, bool>{} as T;
    } else if (T == bool) {
      return _getJson()[defaultJsonIdentifier] = false as T;
    } else if (T == int) {
      return _getJson()[defaultJsonIdentifier] = 0 as T;
    } else if (T == String) {
      return _getJson()[defaultJsonIdentifier] = "" as T;
    } else if (T == double) {
      return _getJson()[defaultJsonIdentifier] = 0 as T;
    }

    throw ConfigException(message: "Invalid type $T for default value of CachedData $path");
  }

  /// A default member of type [T] with identifier [defaultJsonIdentifier]
  set defaultValue(T newValue) => set<T>(defaultJsonIdentifier, newValue);
}
