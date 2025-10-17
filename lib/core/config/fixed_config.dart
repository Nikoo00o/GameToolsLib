import 'dart:math' show Point;
import 'dart:ui' show Locale;

import 'package:game_tools_lib/core/config/mutable_config.dart';
import 'package:game_tools_lib/core/enums/log_level.dart';
import 'package:game_tools_lib/core/utils/locale_extension.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:game_tools_lib/presentation/overlay/ui_elements/overlay_element.dart';

/// Base class storing all fixed config values stored in dart classes which can be overridden in getters of sub classes
/// (and new ones can be added) and may change when compiling a new version (like [logIntoStorage]).
///
/// Sub classes should not have any dynamic member variables and the getters should always return const objects!
///
/// For more info (and an example) look at the general documentation of [GameToolsConfig]
base class FixedConfig {
  /// You should override this in your subclass if you want to support different locales!
  /// Remember to also provide translation files for each language (for example here "en.json")
  /// And also add a translation string for the locale name like for example here "locale.en" : "English"
  /// In both cases you always have to use only the first part of the language code of your language (two letter)!
  /// [LocaleExtension.translationKey] will be used internally!
  ///
  /// Keep one [null] entry in this list so that the user may also select the system locale in
  /// [MutableConfig.currentLocale]! If that one is not supported, then the first entry of the list is used as
  /// default, so the first entry may never be null!
  ///
  /// Only the translation file "en.json" and "de.json" are bundled with this library and will be loaded before your
  /// "en.json" and "de.json" files, but your values may replace the old ones! (also locale files from other packages
  /// plugins will be loaded before your final application). Also look at [LocaleAsset] for more info.
  List<Locale?> get supportedLocales => const <Locale?>[Locale("en"), Locale("de"), null];

  /// if the logger should save log files
  bool get logIntoStorage => true;

  /// if the logger should log into the console
  bool get logIntoConsole => true;

  /// if the user interface should contain a log window
  bool get logIntoUI => true;

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

  /// How many times per second key events/etc are processed in the internal game tools lib loop and also how often
  /// [GameManager.onUpdate] is called! Per default with 40 each loop should take at least 25 milliseconds.
  int get updatesPerSecond => 40;

  /// How many normal update ticks it would take until the window size is updated and the overlay ui elements are
  /// refreshed/rebuild (see [OverlayManager.onWindowResize]).
  ///
  /// So the window size is checked [updatesPerSecond] / [overlayRefreshTicks] times per second! Setting this to 1
  /// will refresh on every update tick! So per default every 100 ms.
  ///
  /// This offers another lever for performance vs interactivity and reaction time!
  ///
  /// This also affects how fast the overlay window tracks the game window and how quickly ui overlay elements react to
  /// clicks ([OverlayElement.clickable]). Also look at [OverlayManager.checkWindowPosition],
  /// [OverlayManager.checkMouseForClickableOverlayElements].
  int get overlayRefreshTicks => 4;

  /// Like [MutableConfig.logLevel], but this here should instead constraint which logs are able to be logged into the
  /// UI (other logs can be accessed dynamically as well in the ui tho)
  LogLevel get defaultUiLogLevel => LogLevel.DEBUG;

  /// The path to the root dir github project of the pubspec.yaml file of the project that contains the "version" which
  /// is used for the version update checker. Important: the first part of the list is just the base github repository
  /// url and the second path might be a sub folder of the root project where the pubspec.yaml (with the version) and
  /// changelog.md files are put (if they are root, then second part must be empty)!
  List<String> get versionPathToGitProject => <String>["https://github.com/Nikoo00o/GameToolsLib", ""];

  /// Direct reference to the current instance of this
  static FixedConfig get fixedConfig => GameToolsConfig.baseConfig.fixed;

  const FixedConfig();
}
