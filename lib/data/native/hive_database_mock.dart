part of 'package:game_tools_lib/game_tools_lib.dart';

/// Mock Implementation used for testing so that no local files are created
final class HiveDatabaseMock extends HiveDatabase {
  Map<String, String?> lazyStorage = <String, String?>{};
  Map<String, String?> instantStorage = <String, String?>{};

  /// The file paths mapped to the byte lists.
  Map<String, Uint8List> files = <String, Uint8List>{};

  /// the last time a file was written to / deleted
  DateTime lastFileChange = DateTime.now();

  static const String FLUTTER_TEST_PATH = "FLUTTER_TESTS_MOCK";

  @visibleForTesting
  /// If [true], then [_init] throws a [FileNotFoundException]
  static bool throwExceptionInInit = false;

  HiveDatabaseMock._() : super._();

  @override
  Future<void> _init() async {
    Logger.debug("Loaded Test Hive Databases");
    if (throwExceptionInInit) {
      throw FileNotFoundException(message: "test mock database should throw");
    }
  }

  Map<String, String?> _getMapForKey(String databaseKey) {
    if (databaseKey == HiveDatabase.LAZY_DATABASE) {
      return lazyStorage;
    } else if (databaseKey == HiveDatabase.INSTANT_DATABASE) {
      return instantStorage;
    } else {
      throw FileNotFoundException(message: "Test Database not found: $databaseKey");
    }
  }

  @override
  Future<void> writeToHive({required String key, required String? value, required String databaseKey}) async {
    _getMapForKey(databaseKey)[key] = value;
  }

  @override
  Future<String?> readFromHive({required String key, required String databaseKey}) async {
    return _getMapForKey(databaseKey)[key];
  }

  @override
  Future<bool> existsInHive({required String key, required String databaseKey}) async {
    return _getMapForKey(databaseKey).containsKey(key);
  }

  @override
  Future<void> deleteFromHive({required String key, required String databaseKey}) async {
    _getMapForKey(databaseKey).remove(key);
  }

  @override
  Future<void> writeFile({required String localFilePath, required List<int> bytes}) async {
    lastFileChange = DateTime.now();
    files[localFilePath] = Uint8List.fromList(bytes);
  }

  @override
  Future<Uint8List?> readFile({required String localFilePath}) async {
    return files[localFilePath];
  }

  @override
  Future<bool> deleteFile({required String localFilePath}) async {
    final bool contained = files.containsKey(localFilePath);
    files.remove(localFilePath);
    if (contained) {
      lastFileChange = DateTime.now();
    }
    return contained;
  }

  @override
  Future<bool> renameFile({required String oldLocalFilePath, required String newLocalFilePath}) async {
    if (files.containsKey(oldLocalFilePath) == false) {
      return false;
    }
    final Uint8List bytes = files.remove(oldLocalFilePath)!;
    files[newLocalFilePath] = bytes;
    lastFileChange = DateTime.now();
    return true;
  }

  @override
  Future<List<String>> getFilePaths({required String subFolderPath}) async {
    final List<String> filePaths = List<String>.empty(growable: true);
    for (final String path in files.keys) {
      if (subFolderPath.isEmpty || path.startsWith(subFolderPath)) {
        filePaths.add(path);
      }
    }
    return filePaths;
  }

  @override
  Future<void> closeHiveDatabases() async {
    lazyStorage.clear();
    instantStorage.clear();
    files.clear();
  }

  @override
  Future<void> deleteDatabaseFolder() async {
    await closeHiveDatabases();
  }

  @override
  String get basePath => FLUTTER_TEST_PATH;
}
