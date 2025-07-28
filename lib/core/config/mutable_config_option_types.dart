part of 'package:game_tools_lib/core/config/mutable_config.dart';

/// Wrapper for primitive types as config options. Use the following typedefs instead [BoolConfigOption],
/// [IntConfigOption], [DoubleConfigOption], [StringConfigOption] and don't use this with any other type [T]!
final class TypeConfigOption<T> extends MutableConfigOption<T> {
  TypeConfigOption({
    required super.titleKey,
    super.descriptionKey,
    super.updateCallback,
    super.defaultValue,
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
/// This also provides [buildLabelsForUI] and [buildCurrentUILabel].
///
/// Of course you could also use this with any custom class that has its [toString] method overridden if you supply a
/// list of values that should be compared against!
final class EnumConfigOption<EnumType> extends MutableConfigOption<EnumType> {
  /// The list of enum values [EnumType.values]!
  final List<EnumType> availableOptions;

  EnumConfigOption({
    required super.titleKey,
    super.descriptionKey,
    super.updateCallback,
    super.defaultValue,
    required this.availableOptions,
  });

  /// Used to build the ui elements which are used to configure this config option.
  /// Just returns a list of the names of the enum values, but may be overridden in a subclass!
  List<String> buildLabelsForUI() => availableOptions.map((EnumType element) => element.toString()).toList();

  /// Used to build the ui element for the [cachedValue]. Per default uses [_dataToString], but can be overridden.
  String? buildCurrentUILabel() => _dataToString(cachedValue());

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
}

/// Used to store an entity/object implementing the [Model] interface and supporting to/from json conversion!
///
/// Important: you need to supply a [_createNewModelInstance] function that creates a new instance of your specific
/// model subclass [T] with the given json map by calling its [fromJson] factory constructor
///
/// As An example look at [createNewExampleModelInstance]
final class ModelConfigOption<T extends Model> extends MutableConfigOption<T> {
  /// function that creates a new instance of [T] by calling its fromJson factory constructor
  final T Function(Map<String, dynamic> json) _createNewModelInstance;

  /// [updateCallback] Optional update callback that is called after [setValue] to update data references elsewhere.
  /// [lazyLoaded] For big data this should be [true] to load on demand. Defaults to [false] (all data is kept in memory)
  /// [createNewModelInstance] function that creates a new instance of [T] by calling its fromJson factory constructor
  ModelConfigOption({
    required T Function(Map<String, dynamic> json) createNewModelInstance,
    required super.titleKey,
    super.descriptionKey,
    super.updateCallback,
    super.defaultValue,
    super.lazyLoaded,
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

  /// Example for how [_createNewModelInstance] functions should look
  static ExampleModel createNewExampleModelInstance(Map<String, dynamic> json) => ExampleModel.fromJson(json);
}

/// Custom Config option where you have the freedom of deciding how to convert a string into your data of type [T] by
/// using the [_createNewInstance] callback.
///
/// For the other way around, [toString] will just be called on your object of type [T]
final class CustomConfigOption<T> extends MutableConfigOption<T> {
  /// function that creates a new instance of [T] (or return null)
  final T? Function(String? str) _createNewInstance;

  /// [updateCallback] Optional update callback that is called after [setValue] to update data references elsewhere.
  /// [lazyLoaded] For big data this should be [true] to load on demand. Defaults to [false] (all data is kept in memory)
  /// [createNewInstance] function that creates a new instance of [T] (or return null)
  CustomConfigOption({
    required T? Function(String? str) createNewInstance,
    required super.titleKey,
    super.descriptionKey,
    super.updateCallback,
    super.defaultValue,
    super.lazyLoaded,
  }) : _createNewInstance = createNewInstance;

  @override
  T? _stringToData(String? str) => _createNewInstance.call(str);
}

/// Special case: [LogLevel] as a enum config option.
final class LogLevelConfigOption extends EnumConfigOption<LogLevel> {
  LogLevelConfigOption({
    required super.titleKey,
    super.descriptionKey,
    super.updateCallback,
    super.defaultValue,
  }) : super(availableOptions: LogLevel.values);
}

/// Special case: [Locale] as a config option which provides another getter [activeLocale].
///
/// This is a nullable [EnumConfigOption] and has some methods overridden!
final class LocaleConfigOption extends EnumConfigOption<Locale?> {
  static const String _systemLocale = "System Locale";

  /// Workaround factory constructor added, because cant directly access the fixed config when its not already
  /// initialized. And can also not set the update callback to an instance member method during the constructor!
  factory LocaleConfigOption({required String titleKey, String? descriptionKey, Locale? defaultValue}) {
    final LocaleConfigOption option = LocaleConfigOption._(
      titleKey: titleKey,
      descriptionKey: descriptionKey,
      defaultValue: defaultValue,
    );
    option._updateCallback = (Locale? _) {
      if (option.availableOptions.isEmpty) {
        option.availableOptions.addAll(FixedConfig.fixedConfig.supportedLocales); // only add supported locales once
      }
    };
    return option;
  }

  LocaleConfigOption._({
    required super.titleKey,
    super.descriptionKey,
    super.defaultValue,
  }) : super(availableOptions: <Locale?>[], updateCallback: null);

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

  @override
  List<String> buildLabelsForUI() {
    return availableOptions.map((Locale? element) {
      if (element == null) {
        return _systemLocale;
      } else {
        return element.toString();
      }
    }).toList();
  }

  @override
  String? buildCurrentUILabel() {
    final String? value = super.buildCurrentUILabel();
    return value ?? _systemLocale;
  }
}
