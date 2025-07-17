import 'dart:io';
import 'dart:typed_data';
import "package:path/path.dart" as p;

abstract final class FileUtils {
  /// Returns the absolute full file path for a local relative file path inside of the parent directory of the script
  /// (like for example inside of a \"res\" folder, or \"assets\" folder).
  ///
  /// Important: the working directory (accessed with [workingDirectory]) might be different depending on how the
  /// script was run!!!!
  ///
  /// If the script is not compiled, then it will return [workingDirectory] so that tests work without any errors!
  ///
  static String getLocalFilePath(String localPath) {
    if (_isCompiled == false) {
      return absolutePath(combinePath(<String>[workingDirectory, localPath]));
    }
    return absolutePath(combinePath(<String>[p.dirname(Platform.script.toFilePath()), localPath]));
  }

  /// Combines the [parts] with [Platform.pathSeparator] in between them, but not at the start and end!
  static String combinePath(List<String> parts) {
    final StringBuffer output = StringBuffer("");
    for (int i = 0; i < parts.length; ++i) {
      output.write(parts.elementAt(i));
      if (i < parts.length - 1) {
        output.write(Platform.pathSeparator);
      }
    }
    return output.toString();
  }

  /// Returns the absolute system file path to the local [relativePath].
  /// Also canonicalizes paths (for example on windows no capitalization)
  static String absolutePath(String relativePath) => p.canonicalize(relativePath);

  /// Same as [absolutePath], but with a [file].
  /// Also canonicalizes paths (for example on windows no capitalization)
  static String absolutePathF(File file) => p.canonicalize(file.absolute.path);

  /// Same as [absolutePath], but with a list of [parts] (see [combinePath].
  /// Also canonicalizes paths (for example on windows no capitalization)
  static String absolutePathP(List<String> parts) => p.canonicalize(combinePath(parts));

  static bool get _isCompiled => p.basename(Platform.resolvedExecutable) == p.basename(Platform.script.path);

  /// Returns the path to the working directory from where the script was executed
  static String get workingDirectory => Directory.current.path;

  /// Read the content of the file as string.
  ///
  /// Throws an exception if the file at [path] could not be found!
  static String readFile(String path) {
    final File file = File(path);
    assert(file.existsSync(), "error, file $path does not exist");
    return File(path).readAsStringSync();
  }

  /// Write the [content] as a file at the [path] and also creates the parent directories
  static void writeFile(String path, String content) {
    final File file = File(path);
    if (file.existsSync() == false) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(content, flush: true);
  }

  /// Append the [content] to the file at the [path] and also creates the parent directories
  static Future<void> addToFileAsync(String path, String content) async {
    final File file = File(path);
    if ((await file.exists()) == false) {
      await file.create(recursive: true);
    }
    await file.writeAsString(content, mode: FileMode.append, flush: true);
  }

  /// Returns the [bytes] of the file at the [path], or returns [null] if the file was not found!
  ///
  /// An empty file will return an empty [Uint8List]!
  static Future<Uint8List?> readFileAsBytes(String path) async {
    final File file = File(path);
    if (await file.exists()) {
      return file.readAsBytes();
    }
    return null;
  }

  /// Write the [bytes] as a file at the [path] and also creates the parent directories
  static Future<void> writeFileAsBytes(String path, List<int> bytes) async {
    final File file = File(path);
    if ((await file.exists()) == false) {
      await file.create(recursive: true);
    }
    await file.writeAsBytes(bytes, flush: true);
  }

  /// Returns true if the file was deleted (so false if it does not exist at [path])
  static bool deleteFile(String path) {
    final File file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
      return true;
    }
    return false;
  }

  /// Returns true if the file was deleted (so false if it does not exist at [path])
  static Future<bool> deleteFileAsync(String path) async {
    final File file = File(path);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  static bool fileExists(String? path) {
    if (path?.isEmpty ?? true) {
      return false;
    }
    return File(path!).existsSync();
  }

  static bool dirExists(String? path) {
    if (path?.isEmpty ?? true) {
      return false;
    }
    return Directory(path!).existsSync();
  }

  static Future<bool> fileExistsAsync(String? path) async {
    if (path?.isEmpty ?? true) {
      return false;
    }
    final File file = File(path!);
    return file.exists();
  }

  /// The [oldPath] file must exist for this to work! Otherwise returns false!
  ///
  /// This will create the parent directories for [newPath]
  static bool copyFile(String oldPath, String newPath) {
    final File oldFile = File(oldPath);
    final File newFile = File(newPath);
    if (oldFile.existsSync() == false) {
      return false;
    }
    if (newFile.parent.existsSync() == false) {
      newFile.parent.createSync();
    }
    oldFile.copySync(newFile.path);
    return true;
  }

  /// The [oldPath] file must exist for this to work!  Otherwise returns false!
  ///
  /// This will create the parent directories for [newPath]
  static bool moveFile(String oldPath, String newPath) {
    final File oldFile = File(oldPath);
    final File newFile = File(newPath);
    if (oldFile.existsSync() == false) {
      return false;
    }
    if (newFile.parent.existsSync() == false) {
      newFile.parent.createSync();
    }
    newFile.parent.renameSync(newPath);
    return true;
  }

  /// The [oldPath] file must exist for this to work!  Otherwise returns false!
  ///
  /// This will create the parent directories for [newPath]
  static Future<bool> moveFileAsync(String oldPath, String newPath) async {
    final File oldFile = File(oldPath);
    final File newFile = File(newPath);
    final bool exists = await oldFile.exists();
    if (exists == false) {
      return false;
    }
    final bool newParentExists = await newFile.parent.exists();
    if (newParentExists == false) {
      await newFile.parent.create();
    }
    await oldFile.rename(newFile.path);
    return true;
  }

  /// Creates the path structure with directories for the directory at the path.
  /// If the [path] points to a file, then it will only create the parent directory.
  static void createDirectory(String path) {
    final Directory directory = getDirectoryForPath(path);
    if (directory.existsSync() == false) {
      directory.createSync(recursive: true);
    }
  }

  /// Returns true if the directory at the [path] was deleted and otherwise false if it does not exist
  ///
  /// If the [path] points to a File, then the parent directory is deleted
  static bool deleteDirectory(String path) {
    final Directory directory = getDirectoryForPath(path);
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
      return true;
    }
    return false;
  }

  /// Returns true if the directory at the [path] was deleted and otherwise false if it does not exist
  ///
  /// If the [path] points to a File, then the parent directory is deleted
  static Future<bool> deleteDirectoryAsync(String path) async {
    final Directory directory = getDirectoryForPath(path);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
      return true;
    }
    return false;
  }

  /// Returns a list of files of either the directory at [path], or the parent directory if [path] is a file.
  ///
  /// The list will be empty if the directory does not exist and the list will only contain the direct files and sub
  /// directories and not recurse into them!
  static Future<List<String>> getFilesInDirectory(String path) async {
    final Directory directory = getDirectoryForPath(path);
    if (directory.existsSync() == false) {
      return <String>[];
    }
    final List<FileSystemEntity> files = await directory.list().toList();
    return files.map((FileSystemEntity file) => file.path).toList();
  }

  /// Returns either the directory at [path], or the parent directory if [path] is a file
  static Directory getDirectoryForPath(String path) {
    if (File(path).existsSync()) {
      return File(path).parent;
    } else {
      return Directory(path);
    }
  }

  /// Returns the file extension (.txt) from a file path
  static String getExtension(String path) {
    if (path.isEmpty) {
      return "";
    }
    return p.extension(path);
  }

  /// Returns the file name (test.txt) from a file path
  static String getFileName(String path) {
    if (path.isEmpty) {
      return "";
    }
    return p.basename(path);
  }

  /// Returns a new path to the parent directory of [path].
  /// If there is no parent directory, then this returns "."
  static String parentPath(String path) => p.dirname(path);
}
