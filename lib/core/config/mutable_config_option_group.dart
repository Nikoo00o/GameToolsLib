part of 'package:game_tools_lib/core/config/mutable_config.dart';

/// This is used to build the group menu entries for the [configOptions] grouped with this.
///
/// This is not a normal config option that can be used!!!
final class MutableConfigOptionGroup extends MutableConfigOption<List<MutableConfigOption<dynamic>>> {
  MutableConfigOptionGroup({
    required super.titleKey,
    required List<MutableConfigOption<dynamic>> configOptions,
  }) {
    _value = configOptions;
  }

  @override
  ConfigOptionBuilder<List<MutableConfigOption<dynamic>>> get builder => ConfigOptionBuilderGroup(configOption: this);

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
