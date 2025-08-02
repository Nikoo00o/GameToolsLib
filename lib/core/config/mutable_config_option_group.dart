part of 'package:game_tools_lib/core/config/mutable_config.dart';

/// This is a special case used to build the group menu entries for the [MutableConfigOption]'s grouped with this.
///
/// This is not a normal config option that can be used!!! And [onInit] and [getValue] do custom work for the
/// initialisation at the end of [GameToolsLib.initGameToolsLib] to load all children
final class MutableConfigOptionGroup extends MutableConfigOption<List<MutableConfigOption<dynamic>>> {
  MutableConfigOptionGroup({
    required super.titleKey,
    required List<MutableConfigOption<dynamic>> configOptions,
  }) : super(onInit: _callInitForValues, defaultValue: configOptions) {
    _value = configOptions; // same as default value, just always return the list of options!
    _exists = true; // config option groups always exist, because they are not saved to storage
  }

  static Future<void> _callInitForValues(MutableConfigOption<dynamic> configOption) async {
    final MutableConfigOptionGroup group = configOption as MutableConfigOptionGroup;
    final List<MutableConfigOption<dynamic>>? options = group._value;
    if (options == null || options.isEmpty) {
      throw ConfigException(message: "Error calling onInit for $group, because it has no children");
    }
    for (final MutableConfigOption<dynamic> option in options) {
      await option.onInit();
    }
  }

  @override
  String toString() => StringUtils.toStringPretty(this, <String, Object?>{"key": titleKey, "value": _value});

  @override
  ConfigOptionBuilder<List<MutableConfigOption<dynamic>>> get builder => ConfigOptionBuilderGroup(configOption: this);

  @override
  Future<List<MutableConfigOption<dynamic>>?> getValue({bool updateListeners = true}) async {
    if (updateListeners == false && _value != null) {
      for (final MutableConfigOption<dynamic> option in _value!) {
        await option.getValue(updateListeners: updateListeners); // important: load all children in gametoolslib.init
      }
    } else {
      Logger.error("getValue called on $this");
    }
    return _value;
  }

  @override
  Future<void> deleteValue() async {
    Logger.error("Delete called on $this");
  }

  @override
  Future<String?> _read() async {
    Logger.error("Read called on $this");
    return null;
  }

  @override
  Future<void> _write(String? str) async {
    Logger.error("Write called on $this");
  }
}
