part of 'package:game_tools_lib/core/config/mutable_config.dart';

/// Wrapper for primitive types as config options. Use the following typedefs instead [BoolConfigOption],
/// [IntConfigOption], [DoubleConfigOption], [StringConfigOption] and don't use this with any other type [T]!
final class TypeConfigOption<T> extends MutableConfigOption<T> {
  TypeConfigOption({
    required super.title,
    super.description,
    super.updateCallback,
    super.defaultValue,
    super.onInit,
  });

  @override
  ConfigOptionBuilder<T> get builder => ConfigOptionBuilderTypes<T>(configOption: this);
}

/// Used for bool config options
typedef BoolConfigOption = TypeConfigOption<bool>;

/// Used for int config options
typedef IntConfigOption = TypeConfigOption<int>;

/// Used for double config options
typedef DoubleConfigOption = TypeConfigOption<double>;

/// Used for string config options
typedef StringConfigOption = TypeConfigOption<String>;

/// This can be used with [EnumType] being any [enum] by just converting them to string and then to convert them back
/// to an object [availableOptions] needs to be supplied with the enum values which will be compared as string!
///
/// Of course you could also use this with any custom class that has its [toString] method overridden if you supply a
/// list of values that should be compared against! Or you can extend from this and override [stringToData] and
/// [dataToString] for custom conversion of the enum type! For example look at [LocaleConfigOption]!
///
/// For building the ui, you can also use [convertToTranslationKeys] in the constructor to convert the
/// values of the enums to some translation keys (instead of using raw strings).
base class EnumConfigOption<EnumType> extends MutableConfigOption<EnumType> {
  /// The list of enum values [EnumType.values]!
  final List<EnumType> availableOptions;

  /// Should return a translation key for a given [EnumType]'s [value]. Can also be null to just use [toString] on them.
  final TranslationString Function(EnumType value)? convertToTranslationKeys;

  EnumConfigOption({
    required super.title,
    super.description,
    super.updateCallback,
    super.defaultValue,
    required this.availableOptions,
    this.convertToTranslationKeys,
    super.onInit,
  });

  @override
  EnumType? _stringToData(String? str) => stringToData(str);

  @override
  String? _dataToString(EnumType? data) => dataToString(data);

  EnumType? stringToData(String? str) {
    for (final EnumType value in availableOptions) {
      if (value.toString() == str) {
        return value;
      }
    }
    return null;
  }

  String? dataToString(EnumType? data) => data?.toString();

  @override
  ConfigOptionBuilder<EnumType> get builder => ConfigOptionBuilderEnum<EnumType>(configOption: this);
}

/// Used to store an entity/object implementing the [Model] interface and supporting to/from json conversion!
///
/// Important: you need to supply a [_createNewModelInstance] function that creates a new instance of your specific
/// model subclass [T] with the given json map by calling its [fromJson] factory constructor
///
/// As An example look at [createNewExampleModelInstance].
///
/// Important: you also have to use [createModelBuilder] if this is included in [MutableConfig.getConfigurableOptions]
/// or otherwise leave it at null. For an example of that look at [createExampleModelBuilder].
///
/// Normally you would directly create instances of this with callbacks, but of course you could also create a
/// subclass which passes static callbacks!
///
/// You could also save the option on storage externally so that the user can edit it with [storeInExternalJsonFile]!
base class ModelConfigOption<T extends Model?> extends MutableConfigOption<T> {
  /// function that creates a new instance of [T] by calling its fromJson factory constructor
  final T Function(Map<String, dynamic> json) _createNewModelInstance;

  /// This has to create a subclass of [ConfigOptionBuilderModel] to build the UI config option content for the model of
  /// type [T]!
  ///
  /// This may also be null if this model option is not contained in [MutableConfig.getConfigurableOptions]
  final ConfigOptionBuilderModel<T> Function(ModelConfigOption<T> option)? createModelBuilder;

  /// If true, then this config option is stored in an external json file which the user can modify while the program
  /// is closed. Per default it's false! It will be stored in
  /// "[GameToolsConfig.dynamicData] / [jsonFolderName] / [title.identifier]"
  ///
  /// But important difference: here the [defaultValue] is only used for the first start if no json file is stored yet
  /// and otherwise always the content of the json file is used! So the file should always exist for the user, but
  /// user modifications have to be done while the program is closed and will be loaded/applied at the next start!
  ///
  /// Also if the user writes invalid json data in the file, then the default values will be used and the file data
  /// may be overridden at any time when it is saved!
  final bool storeInExternalJsonFile;

  /// Name for the folder inside of [GameToolsConfig.dynamicData] that contains the files for [saveToExternalJsonFiles].
  /// Can be overridden in sub classes!
  String get jsonFolderName => "config";

  /// [createNewModelInstance] function that creates a new instance of [T] by calling its fromJson factory constructor
  /// [updateCallback] Optional update callback that is called after [setValue] to update data references elsewhere.
  /// [lazyLoaded] For big data this should be [true] to load on demand. Defaults to [false] (all data is kept in memory)
  /// [onInit] and [defaultValue] are also optional for initialisation
  ModelConfigOption({
    required T Function(Map<String, dynamic> json) createNewModelInstance,
    required super.title,
    required this.createModelBuilder,
    super.description,
    super.updateCallback,
    super.defaultValue,
    super.lazyLoaded,
    super.onInit,
    this.storeInExternalJsonFile = false,
  }) : _createNewModelInstance = createNewModelInstance;

  /// pretty json encoder
  static const JsonEncoder _encoder = JsonEncoder.withIndent("    ");

  @override
  String? _dataToString(T? data) {
    if (data == null) {
      return null;
    }
    return _encoder.convert(data.toJson());
  }

  @override
  T? _stringToData(String? str) {
    if (str == null) {
      return null;
    }
    final Map<String, dynamic>? json = jsonDecode(str) as Map<String, dynamic>?;
    if (json == null) {
      return null;
    }
    try {
      return _createNewModelInstance.call(json);
    } catch (e, s) {
      Logger.error("Could not load ModelConfigOption $title from json, OVERRIDING IT", e, s);
      return null;
    }
  }

  /// Example for how [_createNewModelInstance] functions should look with [ExampleModel]
  static ExampleModel createNewExampleModelInstance(Map<String, dynamic> json) => ExampleModel.fromJson(json);

  /// Example for how [createModelBuilder] functions should look with [ConfigOptionBuilderModelExample] and [ExampleModel]
  static ConfigOptionBuilderModelExample createExampleModelBuilder(ModelConfigOption<ExampleModel?> option) =>
      ConfigOptionBuilderModelExample(configOption: option);

  @override
  ConfigOptionBuilder<T>? get builder => createModelBuilder?.call(this);

  @override
  Future<bool> _existsInStorage() async {
    if (storeInExternalJsonFile) {
      if (GameToolsLib.database.simpleJsonExists(subPath: <String>[jsonFolderName, title.identifier])) {
        return true;
      } else {
        // special case, store default value if it does not exist on storage yet
        await _write(_encoder.convert(defaultValue?.toJson() ?? <String, dynamic>{}));
        return false;
      }
    } else {
      return super._existsInStorage();
    }
  }

  @override
  Future<String?> _read() async {
    if (storeInExternalJsonFile) {
      final String path = FileUtils.combinePath(<String>[
        GameToolsConfig.config().dynamicDataFolder,
        jsonFolderName,
        "${title.identifier}.json",
      ]);
      return FileUtils.readFile(path);
    } else {
      return super._read();
    }
  }

  @override
  Future<void> _write(String? str) async {
    if (storeInExternalJsonFile) {
      if (str != null) {
        final String path = FileUtils.combinePath(<String>[
          GameToolsConfig.config().dynamicDataFolder,
          jsonFolderName,
          "${title.identifier}.json",
        ]);
        await FileUtils.writeFile(path, str);
      }
    } else {
      return super._write(str);
    }
  }
}

/// Custom Config option where you have the freedom of deciding how to convert a string into your data of type [T] by
/// using the [createNewInstance] callback. The other way around is optional with [convertInstanceToString] or
/// otherwise [toString] will just be called on the object of type [T].
///
/// Important: you also have to pass the [buildCustomContentWidget] if this is included in
/// [MutableConfig.getConfigurableOptions] or otherwise null.
///
/// Normally you would directly create instances of this with callbacks, but of course you could also create a
/// subclass which passes static callbacks!
base class CustomConfigOption<T> extends MutableConfigOption<T> {
  /// Callback Function that creates a new instance of [T] (or return null) from a stored string (or null if it was
  /// explicitly stored that way)
  final T? Function(String? str) createNewInstance;

  /// Callback Function that converts an instance of [T] to a string that should be stored (or null if it should
  /// explicitly be stored that way). If this callback itself is null, then [data?.toString] will be called instead!
  final String? Function(T? data)? convertInstanceToString;

  /// If this is not null (and this is included in [MutableConfig.getConfigurableOptions]), then it is used to build
  /// the ui for this config option! It will be notified when this config option changes and has the current internal
  /// data in [customData].
  ///
  /// The [builder] can be used to build helper functions like [ConfigOptionHelperMixin.buildIntOption] or to access
  /// [CustomConfigOption.title], or translate, etc
  final Widget Function(
    BuildContext context,
    T customData,
    ConfigOptionBuilderCustom<T> builder, {
    required bool calledFromInnerGroup,
  })?
  buildCustomContentWidget;

  /// This should return true if your custom option should be shown for the [upperCaseSearchString] in the search bar
  /// for the ui. If this is null it will compare against the title of this config option.
  ///
  /// Only use this if [buildCustomContentWidget] is also not null!
  final bool Function(BuildContext context, ConfigOptionBuilderCustom<T> builder, String upperCaseSearchString)?
  containsSearchCallback;

  /// [createNewInstance] function that creates a new instance of [T] (or return null)
  /// [updateCallback] Optional update callback that is called after [setValue] to update data references elsewhere.
  /// [lazyLoaded] For big data this should be [true] to load on demand. Defaults to [false] (all data is kept in memory)
  /// [onInit] and [defaultValue] are also optional for initialisation
  CustomConfigOption({
    required this.createNewInstance,
    this.convertInstanceToString,
    required this.buildCustomContentWidget,
    this.containsSearchCallback,
    required super.title,
    super.description,
    super.updateCallback,
    super.defaultValue,
    super.lazyLoaded,
    super.onInit,
  }) {
    if (buildCustomContentWidget == null && containsSearchCallback != null) {
      throw ConfigException(message: "$this had a containsSearchCallback, but no buildCustomContentWidget callback");
    }
  }

  @override
  T? _stringToData(String? str) => createNewInstance.call(str);

  @override
  String? _dataToString(T? data) =>
      convertInstanceToString == null ? data?.toString() : convertInstanceToString!.call(data);

  @override
  ConfigOptionBuilder<T>? get builder => buildCustomContentWidget == null
      ? null
      : ConfigOptionBuilderCustom<T>(
          configOption: this,
          buildContentCallback: buildCustomContentWidget!,
          containsSearchCallback: containsSearchCallback,
        );
}

/// Special case: [LogLevel] as a enum config option.
final class LogLevelConfigOption extends EnumConfigOption<LogLevel> {
  LogLevelConfigOption({
    required super.title,
    super.description,
    super.updateCallback,
    super.defaultValue,
    super.onInit,
  }) : super(availableOptions: LogLevel.values);
}
