import 'dart:convert';
import 'dart:io';
import 'dart:math' show max;
import 'dart:typed_data';
import 'package:game_tools_lib/core/encoding/utf16.dart';
import 'package:game_tools_lib/core/utils/string_utils.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import "package:path/path.dart" as p;

abstract final class FileUtils {
  /// Returns the absolute full file path for a local relative file path inside of the parent directory of the script
  /// (like for example inside of a \"res\" folder, or \"assets\" folder).
  ///
  /// Important: the working directory (accessed with [workingDirectory]) might be different depending on how the
  /// script was run!!!!
  ///
  /// If this was run from testing, then it will return [workingDirectory] so that tests work without any errors!
  ///
  static String getLocalFilePath(String localPath) {
    if (wasRunFromTests) {
      return absolutePath(combinePath(<String>[workingDirectory, localPath]));
    }
    return absolutePath(combinePath(<String>[p.dirname(Platform.resolvedExecutable), localPath]));
  }

  /// Combines the [parts] with [Platform.pathSeparator] in between them (if no seperator), but not at the start and
  /// end!
  static String combinePath(List<String> parts) {
    final StringBuffer output = StringBuffer("");
    for (int i = 0; i < parts.length; ++i) {
      output.write(parts.elementAt(i));
      if (i < parts.length - 1 && parts.elementAt(i).endsWith(Platform.pathSeparator) == false) {
        output.write(Platform.pathSeparator);
      }
    }
    return output.toString();
  }

  /// Looks into "data/flutter_assets/assets" and multiple "data/flutter_assets/packages/PACKAGE_NAME/assets" local
  /// folders relative to the execution of this (if this is compiled into a program) and returns a list of absolute
  /// file paths to the [subFolderPath] for the packages that include it (important: first entry will always be the
  /// "game_tools_lib" package and the last entry will always be your application!).
  ///
  /// If this is run from tests, it will point to the project asset folder instead!
  static List<String> getAssetFoldersFor(String subFolderPath) {
    if (wasRunFromTests) {
      return <String>[
        absolutePath(combinePath(<String>[workingDirectory, "assets"])),
      ];
    }
    final String assets = combinePath(<String>[GameToolsConfig.resourceFolderPath, "flutter_assets"]);
    final String packages = combinePath(<String>[assets, "packages"]);
    final String lastSearchPart = combinePath(<String>["assets", subFolderPath]);
    final List<Directory> libs = FileUtils.searchSubFoldersInDir(packages, lastSearchPart);
    final Directory app = Directory(combinePath(<String>[assets, lastSearchPart]));
    final List<String> paths = <String>[];
    final String gameToolsEnding = combinePath(<String>["game_tools_lib", lastSearchPart]);
    for (final Directory dir in libs) {
      if (dir.path.endsWith(gameToolsEnding) == false) {
        paths.add(absolutePathF(dir));
      }
    }
    for (final Directory dir in libs) {
      if (dir.path.endsWith(gameToolsEnding)) {
        paths.insert(0, absolutePathF(dir));
      }
    }
    if (app.existsSync()) {
      paths.add(absolutePathF(app));
    }
    return paths;
  }

  /// Returns the absolute system file path to the local [relativePath].
  /// Also canonicalizes paths (for example on windows no capitalization)
  static String absolutePath(String relativePath) => p.canonicalize(relativePath);

  /// Same as [absolutePath], but with a [file].
  /// Also canonicalizes paths (for example on windows no capitalization)
  static String absolutePathF(FileSystemEntity file) => p.canonicalize(file.absolute.path);

  /// Same as [absolutePath], but with a list of [parts] (see [combinePath].
  /// Also canonicalizes paths (for example on windows no capitalization)
  static String absolutePathP(List<String> parts) => p.canonicalize(combinePath(parts));

  /// Run as exe and not from debugger
  static bool get wasRunFromTests =>
      p.basenameWithoutExtension(Platform.resolvedExecutable) == "tester" ||
      p.basenameWithoutExtension(Platform.resolvedExecutable) == "flutter_tester";

  /// Returns the path to the working directory from where the script was executed
  static String get workingDirectory => Directory.current.path;

  /// Returns [File] from [path] and creates it recursively
  static File _createFileIfNotExists(String path) {
    final File file = File(path);
    if (file.existsSync() == false) {
      file.createSync(recursive: true);
    }
    return file;
  }

  /// Read the utf8/utf16 content of the file as string.
  ///
  /// Important: the [encoding] should either be [utf8], or [utf16]! Default is [utf8] which is mostly used!
  /// Also for [utf16] on windows you might get "\n" linebreaks instead of the expected "\r\n"
  ///
  /// Throws a [FileSystemException] if the file at [path] could not be found, or if you are using [utf8] as the
  /// [encoding] for a file that would need [utf16]!
  ///
  /// You can also combine this with [StringUtils.splitIntoLines!
  static Future<String> readFile(String path, {Encoding encoding = utf8}) async {
    final File file = File(path);
    assert(file.existsSync(), "error, file $path does not exist");
    return File(path).readAsString(encoding: encoding);
  }

  /// Write the utf8/utf16 [content] as a file at the [path] and also creates the parent directories.
  ///
  /// Important: the [encoding] should either be [utf8], or [utf16]! ! Default is [utf8] which is mostly used!
  /// For utf16 both BE or LE encoding bytes will be stripped automatically!
  static Future<void> writeFile(String path, String content, {Encoding encoding = utf8}) async {
    final File file = _createFileIfNotExists(path);
    await file.writeAsString(content, encoding: encoding, flush: true);
  }

  /// Append the utf8/utf16 [content] to the file at the [path] and also creates the parent directories.
  ///
  /// Important: the [encoding] should either be [utf8], or [utf16]! ! Default is [utf8] which is mostly used!
  static Future<void> addToFile(String path, String content, {Encoding encoding = utf8}) async {
    final File file = _createFileIfNotExists(path);
    await file.writeAsString(content, mode: FileMode.append, encoding: encoding, flush: true);
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
    final File file = _createFileIfNotExists(path);
    await file.writeAsBytes(bytes, flush: true);
  }

  /// Tries to read the bytes after [pos] in the [file] up to a number of [size]. If [size] is null, this will read
  /// to the end of the file! Only works for [utf8] files!
  /// This may throw a [FormatException] if you specified your [size] incorrectly, because maybe your file has some
  /// wide chars that are 2 bytes, or more for special symbols and you only counted the characters and not the bytes!
  static Future<String> readFileAtPos({required File file, required int pos, int? size}) async {
    if (size == 0) {
      return "";
    }
    final int? end = size != null ? pos + size : null;
    final StringBuffer buf = StringBuffer();
    final Stream<List<int>> stream = file.openRead(pos, end);
    await for (final List<int> data in stream) {
      buf.write(utf8.decode(data));
    }
    return buf.toString();
  }

  /// Same as [readFileAtPos], but instead of having a max size, this will instead return a list of strings split at
  /// new line characters! Only works for [utf8] files!
  static Future<List<String>> readFileAtPosInLines({required File file, required int pos}) async {
    final StringBuffer buf = StringBuffer();
    final Stream<List<int>> stream = file.openRead(pos);
    await for (final List<int> data in stream) {
      buf.write(utf8.decode(data));
    }
    final String result = buf.toString();
    return StringUtils.splitIntoLines(result);
  }

  /// Same as [readFileAtPos], but here instead an [endPos] is needed from which on it will search backwards
  /// (EXCLUSIVE, so only the indices before the pos!) for the next linebreak and return the line between the
  /// linebreak as the start and the end pos together with the position as a new index left of the linebreak!
  static Future<(String, int)> readFileLineAtPosBackwards({required File file, required int endPos}) async {
    int currentLastPos = endPos;
    int currentFirstPos = max(currentLastPos - 25, 0);
    final List<int> toDecode = <int>[];
    int newLineDistance = 0;
    bool done = false;
    while (currentFirstPos >= 0) {
      newLineDistance = 0; // no new line character here
      final List<List<int>> bytes = await file.openRead(currentFirstPos, currentLastPos).toList();
      for (int i = bytes.length - 1; i >= 0; --i) {
        for (int j = bytes[i].length - 1; j >= 0; --j) {
          final int byte = bytes[i][j];
          if (byte == 10) {
            newLineDistance = 1; // default only \n
            if (j > 0 && bytes[i][j - 1] == 13) {
              newLineDistance = 2; // \r\n skip 2 chars
            }
            done = true; // \n got end pos
            break;
          } else {
            toDecode.insert(0, byte); // latest byte should be on the front
          }
        }
        if (done) {
          break;
        }
      }
      if (done || currentFirstPos == 0) {
        break;
      } else {
        currentLastPos = currentFirstPos - newLineDistance;
        currentFirstPos = max(currentLastPos - 25, 0);
      }
    }
    return (utf8.decode(toDecode), endPos - toDecode.length - newLineDistance);
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
  static Future<bool> moveFile(String oldPath, String newPath) async {
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
  static Future<bool> deleteDirectory(String path) async {
    final Directory directory = getDirectoryForPath(path);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
      return true;
    }
    return false;
  }

  /// Returns true if the file was deleted (so false if it does not exist at [path])
  static Future<bool> deleteFile(String path) async {
    final File file = File(path);
    if (await file.exists()) {
      await file.delete();
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

  /// First this lists all folders of [parentPath] and then looks if those folders contain a folder, or a file at
  /// [subSearch] and only returns the sub folders at [parentPath]/SOME_FOLDER/[subSearch]
  static List<Directory> searchSubFoldersInDir(String parentPath, String subSearch) {
    final Directory directory = getDirectoryForPath(parentPath);
    if (directory.existsSync() == false) {
      return <Directory>[];
    }
    final List<FileSystemEntity> files = directory.listSync();
    final List<Directory> directories = files.map((FileSystemEntity file) {
      return Directory(combinePath(<String>[file.path, subSearch]));
    }).toList();
    directories.removeWhere((Directory dir) => dir.existsSync() == false);
    return directories;
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
