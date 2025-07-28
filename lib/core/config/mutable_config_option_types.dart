part of 'package:game_tools_lib/core/config/mutable_config.dart';

/// Wrapper for primitive types as config options. Use the following typedefs instead [BoolConfigOption],
/// [IntConfigOption], [DoubleConfigOption], [StringConfigOption] and don't use this with any other type [T]!
final class TypeConfigOption<T> extends MutableConfigOption<T> {
  TypeConfigOption({
    required super.titleKey,
    super.descriptionKey,
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
/// list of values that should be compared against!
///
/// For building the ui, you can also use [convertToTranslationKeys] in the constructor to convert the
/// values of the enums to some translation keys (instead of using raw strings).
final class EnumConfigOption<EnumType> extends MutableConfigOption<EnumType> {
  /// The list of enum values [EnumType.values]!
  final List<EnumType> availableOptions;

  /// Should return a translation key for a given [EnumType]'s [value]. Can also be null to just use [toString] on them.
  final String Function(EnumType value)? convertToTranslationKeys;

  EnumConfigOption({
    required super.titleKey,
    super.descriptionKey,
    super.updateCallback,
    super.defaultValue,
    required this.availableOptions,
    this.convertToTranslationKeys,
    super.onInit,
  });

  @override
  EnumType? _stringToData(String? str) {
    for (final EnumType value in availableOptions) {
      if (value.toString() == str) {
        return value;
      }
    }
    return null;
  }

  @override
  String? _dataToString(EnumType? data) => data?.toString();

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
/// or otherwise leave it at null. For an example of that look at [createExampleModelBuilder]
final class ModelConfigOption<T extends Model> extends MutableConfigOption<T> {
  /// function that creates a new instance of [T] by calling its fromJson factory constructor
  final T Function(Map<String, dynamic> json) _createNewModelInstance;

  /// This has to create a subclass of [ConfigOptionBuilderModel] to build the UI config option content for the model of
  /// type [T]!
  ///
  /// This may also be null if this model option is not contained in [MutableConfig.getConfigurableOptions]
  final ConfigOptionBuilderModel<T> Function(ModelConfigOption<T> option)? createModelBuilder;

  /// [updateCallback] Optional update callback that is called after [setValue] to update data references elsewhere.
  /// [lazyLoaded] For big data this should be [true] to load on demand. Defaults to [false] (all data is kept in memory)
  /// [createNewModelInstance] function that creates a new instance of [T] by calling its fromJson factory constructor
  ModelConfigOption({
    required T Function(Map<String, dynamic> json) createNewModelInstance,
    required super.titleKey,
    required this.createModelBuilder,
    super.descriptionKey,
    super.updateCallback,
    super.defaultValue,
    super.lazyLoaded,
    super.onInit,
  }) : _createNewModelInstance = createNewModelInstance;

  @override
  String? _dataToString(T? data) {
    if (data == null) {
      return null;
    }
    return jsonEncode(data.toJson());
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
    return _createNewModelInstance.call(json);
  }

  /// Example for how [_createNewModelInstance] functions should look with [ExampleModel]
  static ExampleModel createNewExampleModelInstance(Map<String, dynamic> json) => ExampleModel.fromJson(json);

  /// Example for how [createModelBuilder] functions should look with [ConfigOptionBuilderModelExample] and [ExampleModel]
  static ConfigOptionBuilderModelExample createExampleModelBuilder(ModelConfigOption<ExampleModel> option) =>
      ConfigOptionBuilderModelExample(configOption: option);

  @override
  ConfigOptionBuilder<T>? get builder => createModelBuilder?.call(this);
}

/// Custom Config option where you have the freedom of deciding how to convert a string into your data of type [T] by
/// using the [_createNewInstance] callback.
///
/// For the other way around, [toString] will just be called on your object of type [T].
///
/// Important: you also have to pass the [buildCustomContentWidget] if this is included in
/// [MutableConfig.getConfigurableOptions] or otherwise null.
final class CustomConfigOption<T> extends MutableConfigOption<T> {
  /// function that creates a new instance of [T] (or return null)
  final T? Function(String? str) _createNewInstance;

  /// If this is not null (and this is included in [MutableConfig.getConfigurableOptions]), then it is used to build
  /// the ui for this config option! It will be notified when this config option changes and has the current internal
  /// data in [customData].
  final Widget Function(BuildContext context, T customData)? buildCustomContentWidget;

  /// [updateCallback] Optional update callback that is called after [setValue] to update data references elsewhere.
  /// [lazyLoaded] For big data this should be [true] to load on demand. Defaults to [false] (all data is kept in memory)
  /// [createNewInstance] function that creates a new instance of [T] (or return null)
  CustomConfigOption({
    required T? Function(String? str) createNewInstance,
    required this.buildCustomContentWidget,
    required super.titleKey,
    super.descriptionKey,
    super.updateCallback,
    super.defaultValue,
    super.lazyLoaded,
    super.onInit,
  }) : _createNewInstance = createNewInstance;

  @override
  T? _stringToData(String? str) => _createNewInstance.call(str);

  @override
  ConfigOptionBuilder<T>? get builder => buildCustomContentWidget == null
      ? null
      : ConfigOptionBuilderCustom<T>(configOption: this, buildContentCallback: buildCustomContentWidget!);
}

/// Special case: [LogLevel] as a enum config option.
final class LogLevelConfigOption extends EnumConfigOption<LogLevel> {
  LogLevelConfigOption({
    required super.titleKey,
    super.descriptionKey,
    super.updateCallback,
    super.defaultValue,
    super.onInit,
  }) : super(availableOptions: LogLevel.values);
}

/// Special case: [Locale] as a config option which provides another getter [activeLocale].
///
/// This is a nullable [EnumConfigOption] and has some methods overridden!
final class LocaleConfigOption extends EnumConfigOption<Locale?> {
  LocaleConfigOption({
    required super.titleKey,
    super.descriptionKey,
    super.defaultValue,
  }) : super(
         availableOptions: <Locale?>[],
         updateCallback: null,
         convertToTranslationKeys: _localeToKey,
         onInit: _addSupportedLocales,
       );

  /// callback used in added to add support locales during init, because a constructor could not directly access
  /// the fixed config when its not already initialized. and can also not access instance members during constructor.
  static Future<void> _addSupportedLocales(MutableConfigOption<dynamic> configOption) async {
    final LocaleConfigOption localeConfigOption = configOption as LocaleConfigOption;
    localeConfigOption.availableOptions.addAll(FixedConfig.fixedConfig.supportedLocales);
  }

  /// callback used for translation keys in ui builder
  static String _localeToKey(Locale? locale) => locale?.translationKey ?? "locale.system";

  /// Returns the currently active locale which can be the current [_value], but also the default system locale, but
  /// also the first locale of the locale list!
  Locale get activeLocale {
    final Locale? locale = cachedValue() ?? LocaleExtension.getSupportedSystemLocale();
    return locale ?? availableOptions.first!;
  }

  @override
  Locale? _stringToData(String? str) => LocaleExtension.getLocaleByName(str);

  @override
  String? _dataToString(Locale? data) => data?.toLanguageTag();
}
