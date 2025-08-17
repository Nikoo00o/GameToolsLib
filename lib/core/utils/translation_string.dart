import 'package:flutter/material.dart' show BuildContext, ValueKey;
import 'package:game_tools_lib/presentation/base/gt_base_widget.dart';

/// Alternative Shorter Syntax for [TranslationString]
typedef TS = TranslationString;

/// Can also be used with [TS] for a shorter syntax.
///
/// This is used to provide a [key] which will be translated from the translation files and additional optional
/// [params] which will replace {0}, {1}, etc in the translated string!
///
/// There is also the special constructor [TranslationString.raw] if you want to show some raw text that should not
/// be translated (here the [key] will be empty)!
///
/// And there is another special constructor [TranslationString.combine] if you want to directly translate and
/// combine translation strings together! Or [TranslationString.empty].
final class TranslationString {
  /// The key which will be matched to the translated text of the translation files
  final String? key;

  /// Optional list of parameters which will replace the place holders ("{0}", "{1}", ...) of the translation
  /// string with raw string values of the code
  final List<String>? params;

  // ignore: prefer_initializing_formals
  const TranslationString(String key, [this.params]) : key = key;

  /// Special case to show the [rawValue] directly and not translated ([key] will be null here)
  TranslationString.raw(String rawValue) : key = null, params = <String>[rawValue];

  /// Special case to explicitly set this to be empty (same as using [TranslationString] with an empty string.
  const TranslationString.empty() : key = "", params = null;

  /// Special case to directly translate and combine the [strings] by using the [TranslationString.raw] constructor!
  factory TranslationString.combine(List<TranslationString> strings, BuildContext context) {
    final StringBuffer buff = StringBuffer();
    for (final TranslationString string in strings) {
      buff.write(GTBaseWidget.translateS(string, context));
    }
    return TranslationString.raw(buff.toString());
  }

  /// Used for [ValueKey]'s, etc which either returns [key] together with params added together if not null, or the
  /// first of [params], or [params] added together depending on the constructor used
  String get identifier {
    if (key != null) {
      if (params?.isEmpty ?? true) {
        return key!;
      } else {
        final StringBuffer buff = StringBuffer(key!);
        for (final String param in params!) {
          buff.write(param);
        }
        return buff.toString();
      }
    } else {
      return params!.first;
    }
  }

  @override
  bool operator ==(Object other) => other is TranslationString && other.identifier == identifier;

  @override
  int get hashCode => identifier.hashCode;

  @override
  String toString() => identifier;
}
