part of 'package:game_tools_lib/game_tools_lib.dart';

/// Used to interact with a local database with [writeToHive] and [readFromHive].
///
/// You can also manipulate files in the [GameToolsConfig.databaseFolder] with [readFile], [writeFile], [renameFile],
/// [deleteFile], [readJson] and [writeJson] directly!
///
/// Everything here is stored in the [GameToolsConfig.databaseFolder] and can be deleted with [deleteDatabaseFolder].
final class HiveDatabase {
  /// The database identifier of the hive box that contains the bigger lazy loaded config values.
  /// Those are loaded on demand and not kept in memory
  static const String LAZY_DATABASE = "lazy_data";

  /// The database identifier of the hive box that contains general config values.
  /// Here all data is kept in memory after opening the database in [_init]
  static const String INSTANT_DATABASE = "instant_data";

  static HiveDatabase? _instance;

  /// Returns the the [HiveDatabase._instance] if already set, otherwise throws a [FileNotFoundException]
  static HiveDatabase get database {
    if (_instance == null) {
      throw FileNotFoundException(message: "HiveDatabase._init was not called yet");
    }
    return _instance!;
  }

  HiveDatabase._();

  /// contains the hive boxes which are used with the [database] parameter
  Map<String, BoxBase<dynamic>>? _hiveDatabases;

  /// Returns [GameToolsConfig.databaseFolder] as the database path
  String get basePath => GameToolsConfig.baseConfig.databaseFolder;

  /// Must be called at the start of the program to initialize the database!
  /// Also loads the hive boxes [_hiveDatabases]
  Future<void> _init() async {
    if (_hiveDatabases == null) {
      FileUtils.createDirectory(basePath);
      Hive.init(basePath);
      _hiveDatabases = <String, BoxBase<dynamic>>{
        LAZY_DATABASE: await Hive.openLazyBox<String?>(LAZY_DATABASE),
        INSTANT_DATABASE: await Hive.openBox<String?>(INSTANT_DATABASE),
      };
    }
  }

  /// Deletes the database directory of the program, so everything stored at [GameToolsConfig.databaseFolder]
  Future<void> deleteDatabaseFolder() async {
    await deleteAllHiveDatabases();
    final List<String> files = await FileUtils.getFilesInDirectory(basePath);
    for (final String path in files) {
      bool exists = await FileUtils.deleteFile(path);
      if (exists) {
        Logger.debug("deleted file $path");
      } else {
        exists = await FileUtils.deleteDirectory(path);
        final Directory dir = Directory(path);
        if (dir.existsSync()) {
          Logger.debug("deleting folder ${dir.path}");
          await dir.delete(recursive: true);
        }
      }
    }
  }

  /// returns target box
  BoxBase<T> _getHiveBox<T>(String databaseKey) {
    if (_hiveDatabases?.containsKey(databaseKey) == false) {
      throw FileNotFoundException(message: "hive box $databaseKey does not exist");
    }
    return _hiveDatabases![databaseKey] as BoxBase<T>;
  }

  /// Helper method to access the hive boxes
  /// Writes a [value] that can be accessed with the [key].
  /// Calls can also explicitly use a [value] that is [null].
  ///
  /// The [databaseKey] key parameter is used to identify which data base stores the [key] [value] pair!
  Future<void> writeToHive({required String key, required String? value, required String databaseKey}) async {
    final BoxBase<String?> hiveBox = _getHiveBox(databaseKey);
    await hiveBox.put(key, value);
  }

  /// Helper method to access the hive boxes.
  /// Returns the String value for the [key], or null if the key was not found.
  ///
  /// The [databaseKey] key parameter is used to identify which data base stores the [key] [value] pair!
  Future<String?> readFromHive({required String key, required String databaseKey}) async {
    final BoxBase<String?> hiveBox = _getHiveBox(databaseKey);
    if (hiveBox is LazyBox<String?>) {
      return hiveBox.get(key);
    } else if (hiveBox is Box<String?>) {
      return hiveBox.get(key);
    }
    return null;
  }

  /// Returns if the [key] is contained in the data base for the [databaseKey]
  Future<bool> existsInHive({required String key, required String databaseKey}) async {
    final BoxBase<String?> hiveBox = _getHiveBox(databaseKey);
    if (hiveBox is LazyBox<String?>) {
      return hiveBox.containsKey(key);
    } else if (hiveBox is Box<String?>) {
      return hiveBox.containsKey(key);
    }
    return false;
  }

  /// Helper method to access the hive boxes.
  /// Returns all keys that are stored inside the hive box [databaseKey].
  ///
  /// If there are no [key] [value] pairs stored in the hive box, then the list will be empty.
  Future<List<String>> getKeysFromHiveDatabase({required String databaseKey}) async {
    final BoxBase<String?> hiveBox = _getHiveBox(databaseKey);
    if (hiveBox is LazyBox<String?>) {
      return List<String>.from(hiveBox.keys.toList());
    } else if (hiveBox is Box<String?>) {
      return List<String>.from(hiveBox.keys.toList());
    }
    return <String>[];
  }

  /// Helper method to access the hive boxes.
  /// Deletes the value for the [key] (not the same as setting the value to null).
  ///
  /// The [databaseKey] key parameter is used to identify which data base stores the [key] [value] pair!
  Future<void> deleteFromHive({required String key, required String databaseKey}) async {
    final BoxBase<String?> hiveBox = _getHiveBox(databaseKey);
    await hiveBox.delete(key);
  }

  /// Deletes the hive box with the [databaseKey].
  Future<void> deleteHiveDatabase({required String databaseKey}) async {
    final BoxBase<String?> hiveBox = _getHiveBox(databaseKey);
    await hiveBox.close();
    await hiveBox.deleteFromDisk();
  }

  /// Deletes all hive boxes
  Future<void> deleteAllHiveDatabases() async {
    for (final BoxBase<dynamic> hiveBox in _hiveDatabases!.values) {
      await hiveBox.close();
      await hiveBox.deleteFromDisk();
    }
    _hiveDatabases = null;
  }

  /// Only removes local references and closes boxes
  Future<void> closeHiveDatabases() async {
    for (final BoxBase<dynamic> hiveBox in _hiveDatabases!.values) {
      await hiveBox.close();
    }
    _hiveDatabases = null;
  }

  /// Saves the [bytes] to a file in [localFilePath] relative to [GameToolsConfig.databaseFolder]
  Future<void> writeFile({required String localFilePath, required List<int> bytes}) async {
    return FileUtils.writeFileAsBytes(await _getAbsolutePath(localFilePath), bytes);
  }

  /// Loads the file in [localFilePath] relative to [GameToolsConfig.databaseFolder] as bytes
  Future<Uint8List?> readFile({required String localFilePath}) async {
    return FileUtils.readFileAsBytes(await _getAbsolutePath(localFilePath));
  }

  static final JsonEncoder _encoder = JsonEncoder.withIndent("    ");

  /// Same as [writeFile], but with a [json] map instead of bytes!
  Future<void> writeJson({required String localFilePath, required Map<String, dynamic> json}) async {
    final String data = _encoder.convert(json);
    return FileUtils.writeFile(await _getAbsolutePath(localFilePath), data);
  }

  /// Same as [readFile], but returns a json map instead!
  Future<Map<String, dynamic>?> readJson({required String localFilePath}) async {
    final String data = await FileUtils.readFile(await _getAbsolutePath(localFilePath));
    return jsonDecode(data) as Map<String, dynamic>?;
  }

  /// Deletes the file in [localFilePath] relative to [GameToolsConfig.databaseFolder]
  Future<bool> deleteFile({required String localFilePath}) async {
    return FileUtils.deleteFile(await _getAbsolutePath(localFilePath));
  }

  /// Renames file with paths relative to [GameToolsConfig.databaseFolder]. The path can also only be a name!
  Future<bool> renameFile({required String oldLocalFilePath, required String newLocalFilePath}) async {
    final String oldPath = await _getAbsolutePath(oldLocalFilePath);
    if (FileUtils.fileExists(oldPath) == false) {
      return false;
    }
    await FileUtils.moveFile(oldPath, await _getAbsolutePath(newLocalFilePath));
    return true;
  }

  /// Returns a list of paths to all files inside of the relative [subFolderPath] to [GameToolsConfig.databaseFolder]
  Future<List<String>> getFilePaths({required String subFolderPath}) async =>
      FileUtils.getFilesInDirectory(await _getAbsolutePath(subFolderPath));

  /// This returns [localFilePath] after the [GameToolsConfig.databaseFolder]
  Future<String> _getAbsolutePath(String localFilePath) async {
    final String basePath = this.basePath;
    if (localFilePath.isEmpty) {
      return basePath;
    } else if (localFilePath.startsWith(basePath)) {
      return localFilePath;
    } else {
      return FileUtils.combinePath(<String>[basePath, localFilePath]);
    }
  }
}
