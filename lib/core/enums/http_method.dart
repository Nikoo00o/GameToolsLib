import 'package:game_tools_lib/domain/game/web_manager.dart';

/// List of the different http request methods for [WebManager]
enum HttpMethod {
  /// Used to retrieve data / read resources
  GET,

  /// Used to send data / create resources
  POST,

  /// Used to replace data / modify resources
  PUT,

  /// Used to delete data / remove resources
  DELETE,

  /// Used to partially modify a resource
  PATCH,

  /// Just like [GET], but without response body
  HEAD;

  @override
  String toString() {
    return name;
  }
}
