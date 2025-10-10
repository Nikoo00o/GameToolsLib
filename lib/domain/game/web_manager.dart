import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart' show protected, mustCallSuper;
import 'package:game_tools_lib/core/enums/http_method.dart';
import 'package:game_tools_lib/core/exceptions/exceptions.dart';
import 'package:game_tools_lib/core/logger/custom_logger.dart';
import 'package:game_tools_lib/domain/entities/web_response.dart';
import 'package:game_tools_lib/game_tools_lib.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' show dirname;

/// This (or a subclass of this) can be used for http web requests by using [request], or [requestJson].
///
/// There are also shorter helper methods that use those request methods from above (also with "Json" suffix):
/// [get], [post], [put], [patch], [delete]. But also optionally to download files as bytes [downloadFile]!
///
/// You can always modify general headers and cookies with [baseHeaders] and [baseCookies] in the [webManager]!
///
/// Subclasses may also override [defaultRetryDelay]!
///
/// Important: if your requests contain sensitive data, remember to add them in [GameToolsLib.initGameToolsLib] to your
/// [CustomLogger.sensitiveDataToRemove]!
///
///
base class WebManager {
  /// The http client that is only used internally for the communication (don't use this directly!)
  @protected
  late final http.Client client;

  /// Headers that can be modified and will always be send for every request like [request], etc
  final Map<String, String> baseHeaders = <String, String>{};

  /// Cookies that can be modified and will always be send for every request like [request], etc
  final Map<String, String> baseCookies = <String, String>{};

  /// Used internally in [_retryRequest] to control delayed retries mapped to the hostname of the request query url!
  final Map<String, _Retry> _pendingRetries = <String, _Retry>{};

  /// This is used internally for http error code 429 too many requests if the server does not provide a delay to use
  /// as a default delay when to send the next request. Per default this is 30 seconds.
  @protected
  Duration get defaultRetryDelay => const Duration(seconds: 30);

  /// Is called at the start of [GameToolsLib.initGameToolsLib] to init the [client]. Override it for your specific
  /// custom initialisation. Sub classes must call this super method first!
  @mustCallSuper
  Future<void> init() async {
    client = http.Client();
  }

  /// Is called at the end of [GameToolsLib.close] when closing your program. Override it for your specific custom
  /// cleanup. Sub classes must call this super method last!
  @mustCallSuper
  Future<void> dispose() async {
    client.close();
  }

  /// Used in [request]: "Cookie: name1=value1; name2=value2;..."
  Map<String, String> _cookieHeader(Map<String, String> additionalCookies) {
    if (additionalCookies.isEmpty) {
      return additionalCookies;
    }
    final StringBuffer buff = StringBuffer();
    for (int i = 0; i < additionalCookies.keys.length; ++i) {
      final String key = additionalCookies.keys.elementAt(i);
      buff.write(key);
      buff.write("=");
      buff.write(additionalCookies[key]);
      if (i < additionalCookies.keys.length - 1) {
        buff.write(";");
      }
    }
    return <String, String>{"Cookie": buff.toString()};
  }

  /// Used in [request] (url encoded): "URL?name1=value1&name2=value2..."
  Uri _buildQuery(Uri url, Map<String, String> queryParameter) {
    if (queryParameter.isEmpty) {
      return url;
    }
    final StringBuffer buff = StringBuffer("$url?");
    for (int i = 0; i < queryParameter.keys.length; ++i) {
      final String key = queryParameter.keys.elementAt(i);
      buff.write(key);
      buff.write("=");
      buff.write(queryParameter[key]);
      if (i < queryParameter.keys.length - 1) {
        buff.write("&");
      }
    }
    return Uri.parse(Uri.encodeFull(buff.toString()));
  }

  /// Used to send a request to the [url] with the specific [httpMethod].
  ///
  /// The [additionalHeaders] can be used for this specific request in addition to the [baseHeaders]!
  ///
  /// Same for the [additionalCookies] in addition to the [baseCookies] which will be set in the "Cookie"
  /// header with "name1=value1; ..."!
  ///
  /// But the [queryParameter] will only be used for this request and appended to the ur with
  /// "?name1=value1&name2=value2...". Important: this will be url encoded to replace special characters!
  ///
  /// The [data] may be set for [HttpMethod.POST], [HttpMethod.PUT], [HttpMethod.PATCH], or [HttpMethod.DELETE] to
  /// optionally send data with the request. If the data is [String], then it will be [utf8] encoded with an
  /// automatically added content type header "text/plain". Otherwise if the data is a [Map] with [String] keys and
  /// values, then it will be encoded as utf8 form fields with content type header "application/x-www-form-urlencoded".
  /// Only [List] of [int]s will be send directly as bytes with no encoding and no extra content type header.
  ///
  /// This may throw a [WebException.timeout] if the request can not be send! And additionally it throws a
  /// [WebException] if the http status code is either 4xx or 5xx!
  ///
  /// Only the http error code 429 is handled internally (too many requests) and the request will automatically be
  /// send again after some time!
  Future<StringResponse> request({
    required Uri url,
    required HttpMethod httpMethod,
    Object? data,
    Map<String, String> additionalHeaders = const <String, String>{},
    Map<String, String> additionalCookies = const <String, String>{},
    Map<String, String> queryParameter = const <String, String>{},
  }) async {
    if (data != null) {
      if (httpMethod == HttpMethod.GET || httpMethod == HttpMethod.HEAD) {
        throw const ConfigException(message: "Don't use data with HTTP GET, or HTTP HEAD!");
      }
    }
    final Map<String, String> headers = <String, String>{
      ...baseHeaders,
      ..._cookieHeader(additionalCookies),
      ...additionalHeaders,
    };
    final Uri query = _buildQuery(url, queryParameter);
    StringResponse response = await _send(query: query, httpMethod: httpMethod, headers: headers, data: data);
    int status = response.statusCode;

    if (status == 429) {
      final Duration retryDelay = _retryDelay(response.responseHeaders["Retry-After"]);
      await _retryRequest(retryDelay, query, () async {
        response = await _send(query: query, httpMethod: httpMethod, headers: headers, data: data);
      });
      status = response.statusCode;
    }
    if (status >= 400 && status < 600) {
      throw WebException(message: "HTTP.$status for $query", statusCode: status);
    }
    return response;
  }

  /// Might throw [WebException.timeout] and just sends a request and returns response
  Future<StringResponse> _send({
    required Uri query,
    required HttpMethod httpMethod,
    required Map<String, String> headers,
    required Object? data,
  }) async {
    final StringBuffer logBuffer = StringBuffer(httpMethod.toString());
    logBuffer.write(" to ");
    logBuffer.write(query.toString());
    logBuffer.write(" with ");
    logBuffer.write(headers);
    Logger.verbose("Sending http request $logBuffer...");
    Logger.spam("And body data ", data);
    try {
      final http.Response response = switch (httpMethod) {
        HttpMethod.GET => await client.get(query, headers: headers),
        HttpMethod.POST => await client.post(query, headers: headers, body: data),
        HttpMethod.PUT => await client.put(query, headers: headers, body: data),
        HttpMethod.PATCH => await client.patch(query, headers: headers, body: data),
        HttpMethod.DELETE => await client.delete(query, headers: headers, body: data),
        HttpMethod.HEAD => await client.head(query, headers: headers),
      };
      final StringResponse stringResponse = StringResponse(response);
      Logger.spam("Got response for ", query, " : HTTP.", response.statusCode, " with body:\n", response.body);
      return stringResponse;
    } catch (e) {
      throw WebException.timeout(message: "Error sending http request $logBuffer", messageParams: <Object>[e]);
    }
  }

  /// parses header and returns when to retry request after this amount of time
  Duration _retryDelay(String? delayHeader) {
    if (delayHeader != null) {
      final int? seconds = int.tryParse(delayHeader);
      if (seconds != null) {
        return Duration(seconds: seconds);
      } else {
        final DateTime? next = DateTime.tryParse(delayHeader);
        if (next != null) {
          return next.difference(DateTime.now());
        } else {
          return defaultRetryDelay;
        }
      }
    } else {
      return defaultRetryDelay;
    }
  }

  /// waits for other retry requests and queues up this request to retry after an amount of time
  Future<void> _retryRequest(Duration retryDelay, Uri query, Future<void> Function() retryCallback) async {
    final String hostName = query.host;
    if (_pendingRetries.containsKey(hostName) == false) {
      _pendingRetries[hostName] = _Retry();
    }
    final _Retry retry = _pendingRetries[hostName]!;
    final int myId = retry.addRequest(retryDelay);
    Logger.spam("Retrying request ", myId, " to ", query, " after ", retryDelay, "...");
    while (true) {
      if (retry.canRetry(myId)) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    try {
      Logger.spam("Sending request ", myId, " again to ", query);
      await retryCallback.call();
    } finally {
      retry.moveToNext();
    }
  }

  /// For the parameter info look at [request] because this is almost the same (only difference is the return type as
  /// [JsonResponse] and an optional json parameter [jsonData] for the body data (this will be encoded in [jsonEncode]).
  ///
  /// Additionally this may throw a [WebException.json] exception if json parsing fails!
  Future<JsonResponse> requestJson({
    required Uri url,
    required HttpMethod httpMethod,
    Object? jsonData,
    Map<String, String> additionalHeaders = const <String, String>{},
    Map<String, String> additionalCookies = const <String, String>{},
    Map<String, String> queryParameter = const <String, String>{},
  }) async {
    final Map<String, String> jsonHeaders = <String, String>{
      "Content-Type": "application/json; charset=utf-8",
      "Accept": "application/json",
      ...additionalHeaders,
    };
    Object? body;
    try {
      body = jsonData == null ? null : utf8.encode(jsonEncode(jsonData));
    } catch (_) {
      throw WebException.json(
        message: "Could not parse json request data to $url:",
        messageParams: <Object>[jsonData!],
      );
    }
    final StringResponse response = await request(
      url: url,
      httpMethod: httpMethod,
      additionalHeaders: jsonHeaders,
      additionalCookies: additionalCookies,
      queryParameter: queryParameter,
      data: body,
    );
    try {
      final JsonResponse jsonResponse = JsonResponse(response);
      return jsonResponse;
    } catch (e) {
      throw WebException.json(
        message: "Could not parse json response data of request to $url",
        messageParams: <Object>[e],
      );
    }
  }

  /// Tries to download the bytes of [url] into a file at [destination] and return true if the file would not be empty.
  ///
  /// Optionally [extractArchive] can be true to directly unpack a downloaded archive.
  ///
  /// Important, this is not using the retry mechanic which is used in every other request!
  Future<bool> downloadFile(Uri url, String destination, {bool extractArchive = false}) async {
    try {
      Logger.verbose("Downloading file from $url to $destination...");
      final Uint8List bytes = await client.readBytes(url);
      if (bytes.isEmpty) {
        Logger.warn("Downloaded empty file from $url to $destination");
        return false;
      }
      final File file = File(destination);
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      if (extractArchive) {
        final String directory = dirname(destination);
        Logger.verbose("Deleting archive $destination after extracting...");
        await extractFileToDisk(destination, directory);
        await File(destination).delete();
      }
      return true;
    } catch (e, s) {
      Logger.warn("Error downloading file from $url to $destination", e, s);
      return false;
    }
  }

  /// Sends a http [HttpMethod.GET] request. For more info look at [request] docs!
  Future<StringResponse> get({
    required Uri url,
    Map<String, String> additionalHeaders = const <String, String>{},
    Map<String, String> additionalCookies = const <String, String>{},
    Map<String, String> queryParameter = const <String, String>{},
  }) => request(
    url: url,
    httpMethod: HttpMethod.GET,
    additionalHeaders: additionalHeaders,
    additionalCookies: additionalCookies,
    queryParameter: queryParameter,
  );

  /// Sends a http [HttpMethod.POST] request. For more info look at [request] docs!
  Future<StringResponse> post({
    required Uri url,
    Map<String, String> additionalHeaders = const <String, String>{},
    Map<String, String> additionalCookies = const <String, String>{},
    Map<String, String> queryParameter = const <String, String>{},
    Object? data,
  }) => request(
    url: url,
    httpMethod: HttpMethod.POST,
    additionalHeaders: additionalHeaders,
    additionalCookies: additionalCookies,
    queryParameter: queryParameter,
    data: data,
  );

  /// Sends a http [HttpMethod.PUT] request. For more info look at [request] docs!
  Future<StringResponse> put({
    required Uri url,
    Map<String, String> additionalHeaders = const <String, String>{},
    Map<String, String> additionalCookies = const <String, String>{},
    Map<String, String> queryParameter = const <String, String>{},
    Object? data,
  }) => request(
    url: url,
    httpMethod: HttpMethod.PUT,
    additionalHeaders: additionalHeaders,
    additionalCookies: additionalCookies,
    queryParameter: queryParameter,
    data: data,
  );

  /// Sends a http [HttpMethod.PATCH] request. For more info look at [request] docs!
  Future<StringResponse> patch({
    required Uri url,
    Map<String, String> additionalHeaders = const <String, String>{},
    Map<String, String> additionalCookies = const <String, String>{},
    Map<String, String> queryParameter = const <String, String>{},
    Object? data,
  }) => request(
    url: url,
    httpMethod: HttpMethod.PATCH,
    additionalHeaders: additionalHeaders,
    additionalCookies: additionalCookies,
    queryParameter: queryParameter,
    data: data,
  );

  /// Sends a http [HttpMethod.DELETE] request. For more info look at [request] docs!
  Future<StringResponse> delete({
    required Uri url,
    Map<String, String> additionalHeaders = const <String, String>{},
    Map<String, String> additionalCookies = const <String, String>{},
    Map<String, String> queryParameter = const <String, String>{},
    Object? data,
  }) => request(
    url: url,
    httpMethod: HttpMethod.DELETE,
    additionalHeaders: additionalHeaders,
    additionalCookies: additionalCookies,
    queryParameter: queryParameter,
    data: data,
  );

  /// Sends a http [HttpMethod.GET] json request. For more info look at [request] docs!
  Future<JsonResponse> getJson({
    required Uri url,
    Map<String, String> additionalHeaders = const <String, String>{},
    Map<String, String> additionalCookies = const <String, String>{},
    Map<String, String> queryParameter = const <String, String>{},
  }) => requestJson(
    url: url,
    httpMethod: HttpMethod.GET,
    additionalHeaders: additionalHeaders,
    additionalCookies: additionalCookies,
    queryParameter: queryParameter,
  );

  /// Sends a http [HttpMethod.POST] json request. For more info look at [request] docs!
  Future<JsonResponse> postJson({
    required Uri url,
    Map<String, String> additionalHeaders = const <String, String>{},
    Map<String, String> additionalCookies = const <String, String>{},
    Map<String, String> queryParameter = const <String, String>{},
    Object? jsonData,
  }) => requestJson(
    url: url,
    httpMethod: HttpMethod.POST,
    additionalHeaders: additionalHeaders,
    additionalCookies: additionalCookies,
    queryParameter: queryParameter,
    jsonData: jsonData,
  );

  /// Sends a http [HttpMethod.PUT] json request. For more info look at [request] docs!
  Future<JsonResponse> putJson({
    required Uri url,
    Map<String, String> additionalHeaders = const <String, String>{},
    Map<String, String> additionalCookies = const <String, String>{},
    Map<String, String> queryParameter = const <String, String>{},
    Object? jsonData,
  }) => requestJson(
    url: url,
    httpMethod: HttpMethod.PUT,
    additionalHeaders: additionalHeaders,
    additionalCookies: additionalCookies,
    queryParameter: queryParameter,
    jsonData: jsonData,
  );

  /// Sends a http [HttpMethod.PATCH] json request. For more info look at [request] docs!
  Future<JsonResponse> patchJson({
    required Uri url,
    Map<String, String> additionalHeaders = const <String, String>{},
    Map<String, String> additionalCookies = const <String, String>{},
    Map<String, String> queryParameter = const <String, String>{},
    Object? jsonData,
  }) => requestJson(
    url: url,
    httpMethod: HttpMethod.PATCH,
    additionalHeaders: additionalHeaders,
    additionalCookies: additionalCookies,
    queryParameter: queryParameter,
    jsonData: jsonData,
  );

  /// Sends a http [HttpMethod.DELETE] json request. For more info look at [request] docs!
  Future<JsonResponse> deleteJson({
    required Uri url,
    Map<String, String> additionalHeaders = const <String, String>{},
    Map<String, String> additionalCookies = const <String, String>{},
    Map<String, String> queryParameter = const <String, String>{},
    Object? jsonData,
  }) => requestJson(
    url: url,
    httpMethod: HttpMethod.DELETE,
    additionalHeaders: additionalHeaders,
    additionalCookies: additionalCookies,
    queryParameter: queryParameter,
    jsonData: jsonData,
  );

  /// Returns the the [WebManager.instance] if already set, otherwise throws a [ConfigException]
  static T webManager<T extends WebManager>() {
    if (instance == null) {
      throw const ConfigException(message: "WebManager was not initialized yet ");
    } else if (instance is T) {
      return instance as T;
    } else {
      throw ConfigException(message: "Wrong type $T for $instance");
    }
  }

  /// Concrete instance of this controlled by [GameToolsLib].
  /// Don't access this directly and use [webManager] instead!
  static WebManager? instance;
}

/// Used internally to control retry requests in [WebManager._pendingRetries]. Contains list of request ids from
/// [WebManager.request]'s that
final class _Retry {
  /// used to identify different ids from [_requestIds]
  static int _idCounter = 0;

  /// Manages list of ids from [addRequest]
  final List<int> _requestIds = <int>[];

  /// Current delay until [_nextTime]
  Duration _delay = Duration.zero;

  /// When the next request should be send
  DateTime _nextTime = DateTime.now();

  /// Called internally to update [_nextTime] with [_delay]
  void _updateNextTime() {
    _nextTime = DateTime.now().add(_delay);
  }

  /// Called in [WebManager._retryRequest] from [WebManager.request] if it should be retried
  int addRequest(Duration retryDelay) {
    _delay = retryDelay;
    _updateNextTime();
    final int id = _idCounter++;
    _requestIds.add(id);
    return id;
  }

  /// Returns if the request with [requestId] is first
  bool _isMyTurn(int requestId) {
    return _requestIds.first == requestId;
  }

  /// Returns if [_isMyTurn] and if the current time is after [_nextTime]
  bool canRetry(int requestId) {
    return _isMyTurn(requestId) && _nextTime.isBefore(DateTime.now());
  }

  /// Removes first request
  void moveToNext() {
    if (_requestIds.isEmpty) {
      Logger.warn("Retry requests were empty, this should not happen!");
      return;
    }
    _requestIds.removeAt(0);
    _updateNextTime();
  }
}
