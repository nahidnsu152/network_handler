part of '../network_handler.dart';

class NetworkHandler {
  final NetworkLog log = NetworkLog();
  late String _baseUrl;
  bool _showLogs = false;
  late bool _enableDialogue;
  void setup(
      {required String baseUrl,
      bool showLogs = false,
      bool enableDialogue = true}) {
    // log.init();
    _baseUrl = baseUrl;
    _showLogs = showLogs;
    _enableDialogue = enableDialogue;
  }

  Map<String, String> _header = const {
    'Content-Type': 'application/json',
    'Content': 'application/json',
    'Accept': 'application/json',
  };
  Map<String, String> get header => _header;

  void setHeader(Map<String, String> header) =>
      _header = {..._header, ...header};

  String getBaseUrl() => _baseUrl;
  NetworkHandler._();

  static final NetworkHandler instance = NetworkHandler._();

  Future<Either<Failure, T>> get<T>(
      {required T Function(dynamic data) fromData,
      required String endPoint,
      bool? showLogs,
      Either<Failure, T> Function(
              int statusCode, Map<String, dynamic> responseBody)?
          failureHandler,
      Map<String, String>? header}) async {
    final bool canPrint = showLogs ?? _showLogs;

    final Map<String, String> header0 = header ?? this.header;
    final request = RequestData<T>(
      method: RequestMethod.get,
      uri: Uri.parse("$_baseUrl$endPoint"),
      showLogs: canPrint,
      fromData: fromData,
      headers: header0,
      failureHandler: failureHandler,
    );

    return fetch<T>(request: request);
  }

  Future<Either<Failure, T>> post<T>(
      {required T Function(dynamic data) fromData,
      required Map<String, dynamic>? body,
      bool? showLogs,
      required String endPoint,
      Either<Failure, T> Function(
              int statusCode, Map<String, dynamic> responseBody)?
          failureHandler,
      Map<String, String>? header}) async {
    final bool canPrint = showLogs ?? _showLogs;

    if (body != null) {
      log.printInfo(info: "body: $body", canPrint: canPrint);
    }

    final Map<String, String> header0 = header ?? this.header;
    final request = RequestData<T>(
        method: RequestMethod.post,
        uri: Uri.parse("$_baseUrl$endPoint"),
        showLogs: canPrint,
        fromData: fromData,
        headers: header0,
        failureHandler: failureHandler,
        body: body);

    return fetch<T>(request: request);
  }

  Future<Either<Failure, T>> put<T>(
      {required T Function(dynamic data) fromData,
      required Map<String, dynamic>? body,
      required String endPoint,
      bool? showLogs,
      Either<Failure, T> Function(
              int statusCode, Map<String, dynamic> responseBody)?
          failureHandler,
      Map<String, String>? header}) async {
    final bool canPrint = showLogs ?? _showLogs;

    if (body != null) {
      log.printInfo(info: "body: $body", canPrint: canPrint);
    }

    final Map<String, String> header0 = header ?? this.header;
    final request = RequestData<T>(
        method: RequestMethod.put,
        uri: Uri.parse("$_baseUrl$endPoint"),
        showLogs: canPrint,
        fromData: fromData,
        headers: header0,
        failureHandler: failureHandler,
        body: body);

    return fetch<T>(request: request);
  }

  Future<Either<Failure, T>> patch<T>(
      {required T Function(dynamic data) fromData,
      required Map<String, dynamic> body,
      required String endPoint,
      bool? showLogs,
      Either<Failure, T> Function(
              int statusCode, Map<String, dynamic> responseBody)?
          failureHandler,
      Map<String, String>? header}) async {
    final bool canPrint = showLogs ?? _showLogs;

    log.printInfo(info: "body: $body", canPrint: canPrint);

    final Map<String, String> header0 = header ?? this.header;
    final request = RequestData<T>(
        method: RequestMethod.patch,
        uri: Uri.parse("$_baseUrl$endPoint"),
        showLogs: canPrint,
        fromData: fromData,
        headers: header0,
        failureHandler: failureHandler,
        body: body);

    return fetch<T>(request: request);
  }

  Future<Either<Failure, T>> delete<T>(
      {required T Function(dynamic data) fromData,
      required String endPoint,
      Map<String, dynamic>? body,
      bool? showLogs,
      Either<Failure, T> Function(
              int statusCode, Map<String, dynamic> responseBody)?
          failureHandler,
      Map<String, String>? header}) async {
    final bool canPrint = showLogs ?? _showLogs;

    if (body != null) {
      log.printInfo(info: "body: $body", canPrint: canPrint);
    }

    final Map<String, String> header0 = header ?? this.header;
    final request = RequestData<T>(
        method: RequestMethod.delete,
        uri: Uri.parse("$_baseUrl$endPoint"),
        showLogs: canPrint,
        fromData: fromData,
        headers: header0,
        failureHandler: failureHandler,
        body: body);

    return fetch<T>(request: request);
  }

  Either<Failure, T> _handleResponse<T>({
    required Response response,
    required RequestData<T> request,
  }) {
    log.printInfo(
        info: "request: ${response.request}", canPrint: request.showLogs);
    log.printResponse(json: response.body, canPrint: request.showLogs);

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      final regResponse = cleanJsonDecode(response.body);

      try {
        final T typedResponse = request.fromData(regResponse);
        log.printSuccess(
            msg: "parsed data: $typedResponse", canPrint: request.showLogs);
        return right(typedResponse);
      } catch (e) {
        if (request.failureHandler != null) {
          return request.failureHandler!(
            response.statusCode,
            cleanJsonDecode(response.body),
          );
        } else {
          log.printWarning(
              warn: "header: ${response.request?.headers}",
              canPrint: request.showLogs);
          log.printWarning(
              warn: "request: ${response.request}", canPrint: request.showLogs);

          log.printWarning(
              warn: "body: ${response.body}", canPrint: request.showLogs);
          log.printWarning(
              warn: "status code: ${response.statusCode}",
              canPrint: request.showLogs);
          return left(Failure.withData(
              statusCode: response.statusCode,
              request: request,
              enableDialogue: _enableDialogue,
              error: cleanJsonDecode(response.body)));
        }
      }
    } else {
      if (request.failureHandler != null) {
        return request.failureHandler!(
          response.statusCode,
          cleanJsonDecode(response.body),
        );
      } else {
        log.printWarning(
            warn: "header: ${response.request?.headers}",
            canPrint: request.showLogs);
        log.printWarning(
            warn: "request: ${response.request}", canPrint: request.showLogs);

        log.printWarning(
            warn: "body: ${response.body}", canPrint: request.showLogs);
        log.printWarning(
            warn: "status code: ${response.statusCode}",
            canPrint: request.showLogs);
        return left(Failure.withData(
            statusCode: response.statusCode,
            enableDialogue: _enableDialogue,
            request: request,
            error: cleanJsonDecode(response.body)));
      }
    }
  }

  cleanJsonDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      throw body;
    }
  }

  Future<http.Response> call({required RequestData request}) async {
    switch (request.method) {
      case RequestMethod.get:
        return http.get(
          request.uri,
          headers: request.headers,
        );
      case RequestMethod.post:
        return http.post(
          request.uri,
          body: request.jsonEncodedBody,
          headers: request.headers,
        );
      case RequestMethod.put:
        return http.put(
          request.uri,
          body: request.jsonEncodedBody,
          headers: request.headers,
        );
      case RequestMethod.patch:
        return http.patch(
          request.uri,
          body: request.jsonEncodedBody,
          headers: request.headers,
        );
      case RequestMethod.delete:
        return http.delete(
          request.uri,
          body: request.jsonEncodedBody,
          headers: request.headers,
        );
    }
  }

  Future<Either<Failure, T>> fetch<T>({required RequestData<T> request}) async {
    log.printInfo(info: "body: ${request.body}", canPrint: request.showLogs);
    try {
      final http.Response response = await call(request: request);

      return _handleResponse<T>(
        response: response,
        request: request,
      );
    } catch (e) {
      log.printError(error: "header: $_header", canPrint: request.showLogs);
      log.printError(
          error: "error: ${e.toString()}", canPrint: request.showLogs);

      return left(
        Failure.withData(
          statusCode: -1,
          enableDialogue: _enableDialogue,
          request: request,
          error: e.toString(),
        ),
      );
    }
  }
}
