part of '../dio_manager.dart';

class DioService {
  late String _token = '';
  late String _baseUrl;
  final Map<String, String> _additionalHeaders = {};
  final Dio _dio = Dio();
  final int _maxRetries = 3;
  final List<int> _nonRetryableStatusCodes = [400, 401, 403, 404];

  DioService._() {
    _initializeDio();
  }
  static final DioService instance = DioService._();
  

  void _initializeDio() {
    _setDefaultHeaders();
    _setTimeouts();
    _dio.options.validateStatus = (int? status) =>
        status != null && (status >= 200 && status < 300 || status == 304);
  }

  // Adds a custom interceptor to the Dio instance without replacing existing ones
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  // Creates a MultipartFile from a file path
  Future<MultipartFile> getMultipartFromFile(String filePath) async {
    String fileName = filePath.split('/').last;
    return await MultipartFile.fromFile(filePath, filename: fileName);
  }

  // Creates a MultipartFile from bytes
  Future<MultipartFile> getMultipartFromBytes(
    Uint8List bytes, [
    String? fileName,
  ]) async {
    return MultipartFile.fromBytes(bytes, filename: fileName);
  }

  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
    _dio.options.baseUrl = baseUrl;
  }

  void setToken(String token) {
    _token = token;
    _setDefaultHeaders();
  }

  void addHeader(String key, String value) {
    _additionalHeaders[key] = value;
    _setDefaultHeaders();
  }

  void removeHeader(String key) {
    _additionalHeaders.remove(key);
    _setDefaultHeaders();
  }

  void _setDefaultHeaders() {
    _dio.options.headers = {
      "content-type": "application/json",
      "accept": "application/json",
      if (_token.isNotEmpty) "authorization": _token,
      "language": "en",
      ..._additionalHeaders,
    };
  }

  void _setTimeouts() {
    _dio.options.receiveTimeout = const Duration(milliseconds: 30000);
    _dio.options.sendTimeout = const Duration(milliseconds: 30000);
    _dio.options.connectTimeout = const Duration(milliseconds: 30000);
  }

  Future<Either<DioFailure, T>> handleRequest<T>({
    required RequestData requestData,
    required T Function(dynamic data) fromData,
    Options? extraOptions,
    CancelToken? cancelToken,
    bool allowRetry = true,
    bool useIsolate = true,
  }) async {
    int attempts = 0;

    // Merge options
    Options mergedOptions = Options(
      method: requestData.method.name,
      headers: {..._dio.options.headers, ...?requestData.headers},
      responseType: useIsolate ? ResponseType.plain : ResponseType.json,
    );

    if (extraOptions != null) {
      mergedOptions = mergedOptions.copyWith(
        method: extraOptions.method ?? mergedOptions.method,
        headers: {...mergedOptions.headers ?? {}, ...?extraOptions.headers},
        extra: {...mergedOptions.extra ?? {}, ...?extraOptions.extra},
        contentType: extraOptions.contentType ?? mergedOptions.contentType,
        responseType: extraOptions.responseType ?? mergedOptions.responseType,
      );
    }

    while (true) {
      try {
        final response = await _dio.request(
          requestData.uri.toString(),
          data: requestData.body,
          queryParameters: requestData.queryParameters,
          options: mergedOptions,
          cancelToken: cancelToken,
          onSendProgress: requestData.onSendProgress,
          onReceiveProgress: requestData.onReceiveProgress,
        );

        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          final data = response.data;

          // 👇 Isolate-based parsing
          if (useIsolate) {
            return Right(await _parseInIsolate(data, fromData));
          } else {
            return Right(fromData(data));
          }
        } else {
          final failure = DioFailure.withData(
            statusCode: response.statusCode ?? -1,
            request: requestData,
            error: response.data,
            isRetryable: !_nonRetryableStatusCodes.contains(
              response.statusCode,
            ),
          );

          if (requestData.failureHandler != null) {
            return requestData.failureHandler!(
                  response.statusCode ?? -1,
                  response.data is Map<String, dynamic> ? response.data : {},
                )
                as Either<DioFailure, T>;
          }

          if (!allowRetry || attempts >= _maxRetries || !failure.isRetryable) {
            return Left(failure);
          }
          attempts++;
        }
      } on DioException catch (error) {
        final failure = DioFailure.withData(
          statusCode: error.response?.statusCode ?? -1,
          request: requestData,
          error: error.response?.data ?? error.message,
        );

        if (requestData.failureHandler != null && error.response != null) {
          return requestData.failureHandler!(
                error.response!.statusCode ?? -1,
                error.response!.data is Map<String, dynamic>
                    ? error.response!.data
                    : {},
              )
              as Either<DioFailure, T>;
        }

        if (!allowRetry || attempts >= _maxRetries || !_shouldRetry(error)) {
          return Left(failure);
        }
        attempts++;
      } catch (e) {
        return Left(
          DioFailure.withData(
            statusCode: -1,
            request: requestData,
            error: e.toString(),
          ),
        );
      }
    }
  }

  Future<T> _parseInIsolate<T>(
    dynamic data,
    T Function(dynamic) fromData,
  ) async {
    try {
      if (data is String) {
        return await Isolate.run(() {
          final decoded = json.decode(data);
          return fromData(decoded);
        });
      } else if (data is List || data is Map) {
        return fromData(data);
      } else {
        throw Exception("Unsupported response type for isolate parsing");
      }
    } catch (e, stackTrace) {
      // ParsingErrorInterceptor.logParseError(e, stackTrace);
      Talker().error("[EXCEPTION]: $e");
      Talker().error("[STACKTRACE]: $stackTrace");

      rethrow;
    }
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.badCertificate;
  }

  //' GET Method
  Future<Either<DioFailure, T>> get<T>({
    required String endPoint,
    required T Function(dynamic) fromData,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Options? extraOptions,
    CancelToken? cancelToken,
    Either<DioFailure, T> Function(int, Map<String, dynamic>)? failureHandler,
    ProgressCallback? onReceiveProgress,
    bool allowRetry = true,
    bool useIsolate = true,
  }) {
    return handleRequest(
      requestData: RequestData(
        uri: Uri.parse("$_baseUrl$endPoint"),
        method: RequestMethod.get,
        headers: headers,
        queryParameters: queryParameters,
        failureHandler: failureHandler,
        onReceiveProgress: onReceiveProgress,
      ),
      fromData: fromData,
      extraOptions: extraOptions,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
      useIsolate: useIsolate,
    );
  }

  //' GET Raw Response Method
  Future<Response<dynamic>> getRaw({
    required String endPoint,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Options? extraOptions,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      // Start with default headers and merge any provided headers
      final mergedHeaders = {
        ..._dio.options.headers,
        if (headers != null) ...headers,
      };

      // Build base options (method + headers)
      Options options = Options(method: 'GET', headers: mergedHeaders);

      // Merge with extraOptions if provided using copyWith
      if (extraOptions != null) {
        options = options.copyWith(
          method: extraOptions.method ?? options.method,
          headers: {...?options.headers, ...?extraOptions.headers},
          extra: {...?options.extra, ...?extraOptions.extra},
          contentType: extraOptions.contentType ?? options.contentType,
          responseType: extraOptions.responseType ?? options.responseType,
          validateStatus: extraOptions.validateStatus ?? options.validateStatus,
          receiveDataWhenStatusError:
              extraOptions.receiveDataWhenStatusError ??
              options.receiveDataWhenStatusError,
          followRedirects:
              extraOptions.followRedirects ?? options.followRedirects,
          maxRedirects: extraOptions.maxRedirects ?? options.maxRedirects,
          requestEncoder: extraOptions.requestEncoder ?? options.requestEncoder,
          responseDecoder:
              extraOptions.responseDecoder ?? options.responseDecoder,
          listFormat: extraOptions.listFormat ?? options.listFormat,
        );
      }

      final response = await _dio.get(
        '$_baseUrl$endPoint',
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );

      return response;
    } on DioException catch (e) {
      throw DioFailure.withData(
        statusCode: e.response?.statusCode ?? -1,
        request: RequestData(
          uri: Uri.parse('$_baseUrl$endPoint'),
          method: RequestMethod.get,
        ),
        error: e.response?.data ?? e.message,
      );
    } catch (e) {
      throw DioFailure.withData(
        statusCode: -1,
        request: RequestData(
          uri: Uri.parse('$_baseUrl$endPoint'),
          method: RequestMethod.get,
        ),
        error: e.toString(),
      );
    }
  }

  //' POST Method
  Future<Either<DioFailure, T>> post<T>({
    required String endPoint,
    required T Function(dynamic) fromData,
    required dynamic body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Options? extraOptions,
    CancelToken? cancelToken,
    Either<DioFailure, T> Function(int, Map<String, dynamic>)? failureHandler,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool allowRetry = true,
    bool useIsolate = true,
  }) {
    return handleRequest(
      requestData: RequestData(
        uri: Uri.parse("$_baseUrl$endPoint"),
        method: RequestMethod.post,
        body: body,
        headers: headers,
        queryParameters: queryParameters,
        failureHandler: failureHandler,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
      fromData: fromData,
      extraOptions: extraOptions,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
    );
  }

  //' POST Raw Response Method
  Future<Response<dynamic>> postRaw({
    required String endPoint,
    required dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Options? extraOptions,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final mergedHeaders = {
        ..._dio.options.headers,
        if (headers != null) ...headers,
      };

      Options options = Options(method: 'POST', headers: mergedHeaders);

      if (extraOptions != null) {
        options = options.copyWith(
          method: extraOptions.method ?? options.method,
          headers: {...?options.headers, ...?extraOptions.headers},
          extra: {...?options.extra, ...?extraOptions.extra},
          contentType: extraOptions.contentType ?? options.contentType,
          responseType: extraOptions.responseType ?? options.responseType,
          validateStatus: extraOptions.validateStatus ?? options.validateStatus,
          receiveDataWhenStatusError:
              extraOptions.receiveDataWhenStatusError ??
              options.receiveDataWhenStatusError,
          followRedirects:
              extraOptions.followRedirects ?? options.followRedirects,
          maxRedirects: extraOptions.maxRedirects ?? options.maxRedirects,
          requestEncoder: extraOptions.requestEncoder ?? options.requestEncoder,
          responseDecoder:
              extraOptions.responseDecoder ?? options.responseDecoder,
          listFormat: extraOptions.listFormat ?? options.listFormat,
        );
      }

      final response = await _dio.post(
        '$_baseUrl$endPoint',
        data: body,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return response;
    } on DioException catch (e) {
      throw DioFailure.withData(
        statusCode: e.response?.statusCode ?? -1,
        request: RequestData(
          uri: Uri.parse('$_baseUrl$endPoint'),
          method: RequestMethod.post,
        ),
        error: e.response?.data ?? e.message,
      );
    } catch (e) {
      throw DioFailure.withData(
        statusCode: -1,
        request: RequestData(
          uri: Uri.parse('$_baseUrl$endPoint'),
          method: RequestMethod.post,
        ),
        error: e.toString(),
      );
    }
  }

  //' PUT Method
  Future<Either<DioFailure, T>> put<T>({
    required String endPoint,
    required T Function(dynamic) fromData,
    required dynamic body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Options? extraOptions,
    CancelToken? cancelToken,
    Either<DioFailure, T> Function(int, Map<String, dynamic>)? failureHandler,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool allowRetry = true,
    bool useIsolate = true,
  }) {
    return handleRequest(
      requestData: RequestData(
        uri: Uri.parse("$_baseUrl$endPoint"),
        method: RequestMethod.put,
        body: body,
        headers: headers,
        queryParameters: queryParameters,
        failureHandler: failureHandler,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
      fromData: fromData,
      extraOptions: extraOptions,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
      useIsolate: useIsolate,
    );
  }

  //' PATCH Method
  Future<Either<DioFailure, T>> patch<T>({
    required String endPoint,
    required T Function(dynamic) fromData,
    required dynamic body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Options? extraOptions,
    CancelToken? cancelToken,
    Either<DioFailure, T> Function(int, Map<String, dynamic>)? failureHandler,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool allowRetry = true,
    bool useIsolate = true,
  }) {
    return handleRequest(
      requestData: RequestData(
        uri: Uri.parse("$_baseUrl$endPoint"),
        method: RequestMethod.patch,
        body: body,
        headers: headers,
        queryParameters: queryParameters,
        failureHandler: failureHandler,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
      fromData: fromData,
      extraOptions: extraOptions,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
      useIsolate: useIsolate,
    );
  }

  //' DELETE Method
  Future<Either<DioFailure, T>> delete<T>({
    required String endPoint,
    required T Function(dynamic) fromData,
    required dynamic body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Options? extraOptions,
    CancelToken? cancelToken,
    Either<DioFailure, T> Function(int, Map<String, dynamic>)? failureHandler,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool allowRetry = true,
    bool useIsolate = true,
  }) {
    return handleRequest(
      requestData: RequestData(
        uri: Uri.parse("$_baseUrl$endPoint"),
        method: RequestMethod.delete,
        body: body,
        headers: headers,
        queryParameters: queryParameters,
        failureHandler: failureHandler,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
      fromData: fromData,
      extraOptions: extraOptions,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
      useIsolate: useIsolate,
    );
  }

  //' Uplaod Method
  Future<Either<DioFailure, T>> upload<T>({
    required String endPoint,
    required T Function(dynamic) fromData,
    required FormData formData,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Options? extraOptions,
    CancelToken? cancelToken,
    Either<DioFailure, T> Function(int, Map<String, dynamic>)? failureHandler,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool allowRetry = true,
    bool useIsolate = true,
  }) {
    return handleRequest(
      requestData: RequestData(
        uri: Uri.parse("$_baseUrl$endPoint"),
        method: RequestMethod.post,
        body: formData,
        headers: headers,
        queryParameters: queryParameters,
        failureHandler: failureHandler,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
      fromData: fromData,
      extraOptions: extraOptions,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
      useIsolate: useIsolate,
    );
  }

  //' Download Method
  Future<Either<DioFailure, T>> download<T>({
    required String url,
    required String savePath,
    required T Function(dynamic) fromData,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    Map<String, String>? headers,
    Options? extraOptions,
    bool allowRetry = true,
  }) async {
    // Merge headers for download
    Options mergedOptions = Options(headers: headers);
    if (extraOptions != null) {
      mergedOptions = mergedOptions.copyWith(
        headers: {...mergedOptions.headers ?? {}, ...?extraOptions.headers},
        // Merge other fields as needed
      );
    }

    try {
      final response = await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
        options: mergedOptions,
      );
      return Right(fromData(response));
    } catch (e) {
      return Left(
        DioFailure.withData(
          statusCode: -1,
          request: RequestData(uri: Uri.parse(url), method: RequestMethod.get),
          error: e.toString(),
        ),
      );
    }
  }
}
