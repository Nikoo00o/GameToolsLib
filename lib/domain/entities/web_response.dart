import 'dart:convert' as convert;
import 'package:game_tools_lib/domain/game/web_manager.dart';
import 'package:http/http.dart' as http;

/// [StringResponse] or [JsonResponse] are used in [WebManager]'s responses!
sealed class WebResponse<DataType> {
  /// The raw http response reference. Can also be used to access the raw bytes with [http.Response.bodyBytes]
  final http.Response httpResponse;

  WebResponse(this.httpResponse);

  /// Contains Http error codes
  int get statusCode => httpResponse.statusCode;

  /// List of response headers of [httpResponse]
  Map<String, String> get responseHeaders => httpResponse.headers;

  /// List of cookies retrieved from [responseHeaders]
  Map<String, String> get responseCookies {
    final String cookieHeader = responseHeaders["Set-Cookie"] ?? "";
    final List<String> cookieList = cookieHeader.split(";");
    final Map<String, String> outputCookies = <String, String>{};
    for (final String cookie in cookieList) {
      String name = cookie.substring(0, cookie.indexOf("="));
      if (name.startsWith(" ")) {
        name = name.substring(1);
      }
      final String value = cookie.substring(cookie.indexOf("=") + 1);
      outputCookies[name] = value;
    }
    return outputCookies;
  }

  /// Returns the body data from the [httpResponse]
  DataType get responseData;
}

/// The default [WebResponse] that just returns a string
final class StringResponse extends WebResponse<String> {
  /// Already converted data (set in constructor) that will also be returned in [responseData]
  late final String body;

  StringResponse(super.httpResponse) {
    body = httpResponse.body;
  }

  @override
  String get responseData => httpResponse.body;
}

/// A [WebResponse] used for json data with an additional [json] member
final class JsonResponse extends WebResponse<Map<String, dynamic>> {
  /// Already converted data (set in constructor) that will also be returned in [responseData]
  late final Map<String, dynamic> json;

  /// Needs a [StringResponse] that will be converted. The constructor will decode the json inside and may throw an
  /// exception!
  JsonResponse(StringResponse stringResponse) : super(stringResponse.httpResponse) {
    json = convert.json.decode(httpResponse.body) as Map<String, dynamic>;
  }

  @override
  Map<String, dynamic> get responseData => json;
}
