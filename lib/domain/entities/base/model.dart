import 'entity.dart';

/// The Model base class that other models implement to override the toJson method.
///
/// This can, but does not have to be used with [Entity]!
///
/// The fromJson factory constructor must be provided as well in sub classes, but it can not be provided with an interface!
///
/// When converting from json, this also offers the helper functions [getModelListFromJson] and [getModelMapFromJson]!
abstract interface class Model {
  /// Create JSON Map from model
  Map<String, dynamic> toJson();

  /// Helper to get a dynamic list of [json] with the [key] and then convert it into a list of [EntryType] with the
  /// [convertEntry] callback!
  ///
  /// Remember that for lists of primitive data types you can just call `List<int>.from(json[key] as List<dynamic>)`!
  static List<EntryType> getModelListFromJson<EntryType>(
    Map<String, dynamic> json,
    String key,
    EntryType Function(Map<String, dynamic> innerJson) convertEntry,
  ) {
    final List<dynamic> dynList = json[key] as List<dynamic>;
    return dynList.map<EntryType>((dynamic map) => convertEntry.call(map as Map<String, dynamic>)).toList();
  }

  /// Helper to get a dynamic map of [json] with the [key] and then convert it into a map of [ValueType] with the
  /// [convertEntry] callback!
  ///
  /// Remember that for maps of primitive data types you can just call
  /// `Map<String, int>.from(json[key] as Map<String, dynamic>)`!
  static Map<String, ValueType> getModelMapFromJson<ValueType>(
    Map<String, dynamic> json,
    String key,
    ValueType Function(Map<String, dynamic> innerJson) convertEntry,
  ) {
    final Map<String, dynamic> dynMap = json[key] as Map<String, dynamic>;
    return dynMap.map(
      (String key, dynamic value) => MapEntry<String, ValueType>(key, convertEntry.call(value as Map<String, dynamic>)),
    );
  }
}

/// Example Model class that extends from [ExampleEntity] and implements [Model]
final class ExampleModel extends ExampleEntity implements Model {
  static const String JSON_SOME_DATA = "Some Data";
  static const String JSON_MODIFIABLE_DATA = "Modifiable Data";

  /// Default constructor with same params as entity
  ExampleModel({super.someData, required super.modifiableData});

  /// Important: a factory constructor to always convert an [ExampleEntity] into a [ExampleModel], because there
  /// could be entities used at places in the code which are not models (and because the model extends the entity, no
  /// cast can be done and there needs to be a conversion so that the added json conversion can be useed)
  factory ExampleModel.fromEntity(ExampleEntity entity) {
    if (entity is ExampleModel) {
      return entity;
    }
    return ExampleModel(someData: entity.someData, modifiableData: entity.modifiableData);
  }

  @override
  /// Now the [someData] can just directly be used, because its an integer that can directly fit into a json map as a
  /// valid type. But the [modifiableData] is a list of a custom type that needs to be converted first!
  Map<String, dynamic> toJson() {
    final List<Map<String, dynamic>> modifiableDataJson = List<Map<String, dynamic>>.empty(growable: true);
    for (final ExampleEntity entity in modifiableData) {
      // important: here again the modifiable data list could be a list of entities, so its safer to use [fromEntity]
      // to convert them into a model and then calling toJson on the model
      modifiableDataJson.add(ExampleModel.fromEntity(entity).toJson());
    }
    // only basic types and Map<String, dynamic> should be directly returned here, so custom class objects must be
    // converted!
    return <String, dynamic>{
      JSON_SOME_DATA: someData,
      JSON_MODIFIABLE_DATA: modifiableDataJson,
    };
  }

  /// And the from json factory constructor must parse the elements in the json map. basic types can be used
  /// directly, but custom class types must be converted. and also lists have to be treated as dynamic first and then
  /// converted!
  factory ExampleModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> modifiableDataDynList = json[JSON_MODIFIABLE_DATA] as List<dynamic>;
    final List<ExampleModel> modifiableDataList = modifiableDataDynList
        .map<ExampleModel>((dynamic map) => ExampleModel.fromJson(map as Map<String, dynamic>))
        .toList();
    return ExampleModel(
      someData: json[JSON_SOME_DATA] as int?,
      modifiableData: modifiableDataList,
      /// Below would be an example with the helper method from [Model]!
      // modifiableData: Model.getModelListFromJson(
      //   json,
      //   JSON_MODIFIABLE_DATA,
      //   (Map<String, dynamic> json) => ExampleModel.fromJson(json),
      // ),
    );
  }
}
