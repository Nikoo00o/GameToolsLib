import 'dart:math' show Point;

import 'package:game_tools_lib/core/utils/file_utils.dart';
import 'package:game_tools_lib/game_tools_lib.dart';

/// Base class storing all fixed config values stored in dart classes which can be overridden in getters of sub classes
/// (and new ones can be added). sub classes should not have any dynamic member variables.
///
/// For more info (and an example) look at the general documentation of [GameToolsConfig]
base class FixedConfig {
  /// if the logger should save log files
  bool get logIntoStorage => true;

  /// if the logger should log into the console
  bool get logIntoConsole => true;

  /// if the user interface should contain a log window
  bool get logIntoUI => true;

  /// Absolute path to the folder from the working directory where files are stored
  String get resourceFolderPath => FileUtils.getLocalFilePath("gametoolsdata");

  /// Local path to stored log files
  String get logFolder => FileUtils.combinePath(<String>[resourceFolderPath, "logs"]);

  /// Local path to stored database files (for mutable config values) and other files
  String get databaseFolder => FileUtils.combinePath(<String>[resourceFolderPath, "database"]);

  /// Min and max values for a tiny random delay (default is half of [shortDelayMS]. only rarely used)
  Point<int> get tinyDelayMS => const Point<int>(3, 5);

  /// Min and max values for a short random delay (used for most actions)
  Point<int> get shortDelayMS => const Point<int>(7, 11);

  /// Min and max values for a medium random delay
  Point<int> get mediumDelayMS => const Point<int>(15, 26);

  /// Min and max values for a long random delay
  Point<int> get longDelayMS => const Point<int>(80, 150);

  /// Delay in milliseconds for the default value for [SpamIdentifier.delay]
  int get logPeriodicSpamDelayMS => longDelayMS.y;

  /// Reference to the current instance of this
  static FixedConfig get fixedConfig => GameToolsConfig.baseConfig.fixed;
}
