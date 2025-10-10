import 'package:flutter/foundation.dart';
import 'package:game_tools_lib/core/config/fixed_config.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/utils/string_utils.dart';
import 'package:game_tools_lib/domain/entities/web_response.dart';
import 'package:game_tools_lib/domain/game/web_manager.dart';
import 'package:game_tools_lib/presentation/pages/home/gt_home_page.dart';
import 'package:game_tools_lib/presentation/widgets/functional/gt_version_check.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// If you want to use a sub class of this, then set the [instance] to an object instance of your sub class!
///
/// This is used inside of the [GTVersionCheck] widget mostly in [GTHomePage].
base class UpdateChecker {
  /// Returns the the [UpdateChecker.instance] with type [T], otherwise throws a [ConfigException]
  static T updateChecker<T extends UpdateChecker>() {
    if (instance is T) {
      return instance as T;
    } else {
      throw ConfigException(message: "Wrong type $T for $instance");
    }
  }

  /// The base path to the github repository like for example https://github.com/Nikoo00o/GameToolsLib
  String get baseGitProjectPath => FixedConfig.fixedConfig.versionPathToGitProject;

  /// The download path to raw files of github for the main branch like for example
  /// https://raw.githubusercontent.com/Nikoo00o/GameToolsLib/refs/heads/main
  @protected
  String get rawGitFilePath {
    String path = baseGitProjectPath;
    path = path.substring("https://github.com/".length);
    return "https://raw.githubusercontent.com/$path/refs/heads/main/";
  }

  /// Download raw file path like for example
  /// https://raw.githubusercontent.com/Nikoo00o/GameToolsLib/refs/heads/main/pubspec.yaml
  @protected
  String get onlinePubspecPath => "$rawGitFilePath/pubspec.yaml";

  /// Download raw file path like for example
  /// https://raw.githubusercontent.com/Nikoo00o/GameToolsLib/refs/heads/main/CHANGELOG.md
  @protected
  String get onlineChangelogPath => "$rawGitFilePath/CHANGELOG.md";

  /// Local version from pubspec.yaml last build
  Future<String> getMyVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// This may throw an [WebException] and otherwise returns version string of pubspec.yaml if found and otherwise
  /// empty string
  Future<String> getNewestVersion() async {
    final StringResponse response = await WebManager.webManager().get(url: Uri.parse(onlinePubspecPath));
    final List<String> lines = StringUtils.splitIntoLines(response.responseData);
    for (final String line in lines) {
      const String needle = "version: ";
      if (line.startsWith(needle)) {
        String part = line.substring(needle.length);
        if (part.contains(" ")) {
          part = part.substring(0, part.indexOf(" "));
        } else if (part.contains("#")) {
          part = part.substring(0, part.indexOf("#"));
        }
        return part;
      }
    }
    return "";
  }

  /// This returns the full file data of CHANGELOG.md but on error (if no changelog exists, etc), then it just
  /// returns an empty string
  Future<String> getChangelog() async {
    try {
      final StringResponse response = await WebManager.webManager().get(url: Uri.parse(onlineChangelogPath));
      return response.responseData;
    } catch (_) {
      return "";
    }
  }

  /// Concrete instance of this which can be replaced with sub classes
  static UpdateChecker instance = UpdateChecker();
}
