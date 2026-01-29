import 'package:game_tools_lib/game_tools_lib.dart';

/// Return type of [GameToolsLib.initGameToolsLib]. Provides [hasError] getter to quick check if not [SUCCESS].
enum InitResult {
  /// The default case where the init returned without any errors
  SUCCESS,

  /// could not init db
  DATABASE_ERROR,

  /// some c code could not be loaded
  NATIVE_CODE_ERROR,

  /// outdated c library version
  NATIVE_WRONG_VERSION,

  /// opencv path not set
  NATIVE_OPENCV_MISSING,

  /// no default paths were given to the game log watcher
  LOG_NO_PATHS_GIVEN,

  /// the game log file was not found at the used paths. SPECIAL CASE WHICH OPENS a dialog on [GameToolsLib.runLoop]!
  LOG_NOT_FOUND,

  /// no game config file exists at path
  GAME_CONFIG_NOT_FOUND,

  /// not in a valid json structure
  GAME_CONFIG_INVALID
  ;

  @override
  String toString() {
    return name;
  }

  /// If [this] is different than [SUCCESS]
  bool get hasError => this != SUCCESS;

  factory InitResult.fromString(String data) {
    return values.firstWhere((InitResult element) => element.name == data);
  }
}
