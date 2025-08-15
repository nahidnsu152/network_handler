part of '../dio_manager.dart';

class DioService {
  late String _token = '';
  late String _baseUrl;
  final Map<String, String> _additionalHeaders = {};
  final Dio _dio = Dio();
  LoggerType _loggerType = LoggerType.talker;

  bool _showResponseHeader = false;
  bool _requestBody = false;
  int _maxWidth = 150;
  final int _maxRetries = 3;
  final List<int> _nonRetryableStatusCodes = [400, 401, 403, 404];

  final _talker = Talker();

  DioService._() {
    _initializeDio();
  }
  static final DioService instance = DioService._();

  void _initializeDio() {
    _setLogger();
    _setDefaultHeaders();
    _setTimeouts();
  }

  /// Adds a custom interceptor to the Dio instance
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  /// Creates a MultipartFile from a file path
  Future<MultipartFile> getMultipartFromFile(String filePath) async {
    String fileName = filePath.split('/').last;
    return await MultipartFile.fromFile(filePath, filename: fileName);
  }

  /// Creates a MultipartFile from bytes
  Future<MultipartFile> getMultipartFromBytes(
    Uint8List bytes, [
    String? fileName,
  ]) async {
    return MultipartFile.fromBytes(bytes, filename: fileName);
  }

  void setLogger(LoggerType loggerType) {
    _loggerType = loggerType;
    _setLogger();
  }

  void _setLogger() {
    _dio.interceptors.removeWhere(
      (interceptor) =>
          interceptor is TalkerDioLogger || interceptor is PrettyDioLogger,
    );

    if (_loggerType == LoggerType.talker) {
      _dio.interceptors.add(
        TalkerDioLogger(
          settings: const TalkerDioLoggerSettings(
            printRequestHeaders: true,
            printResponseMessage: true,
          ),
        ),
      );
    } else {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  void logSetup({
    bool? responseBody,
    int? width,
    bool? responseHeader,
    bool? request,
  }) {
    _showResponseHeader = responseHeader ?? _showResponseHeader;
    _requestBody = request ?? _requestBody;
    _maxWidth = width ?? _maxWidth;

    _dio.interceptors.removeWhere(
      (interceptor) => interceptor is PrettyDioLogger,
    );
    _dio.interceptors.add(
      PrettyDioLogger(
        responseBody: _requestBody,
        responseHeader: _showResponseHeader,
        maxWidth: _maxWidth,
        error: true,
      ),
    );
  }
  // void _setLogger() {
  //   _dio.interceptors.clear();

  //   if (_loggerType == LoggerType.talker) {
  //     _dio.interceptors.add(
  //       TalkerDioLogger(
  //         settings: const TalkerDioLoggerSettings(
  //           printRequestHeaders: true,
  //           printResponseMessage: true,
  //         ),
  //       ),
  //     );
  //   } else {
  //     _dio.interceptors.add(
  //       PrettyDioLogger(
  //         requestHeader: true,
  //         requestBody: true,
  //         responseBody: true,
  //         error: true,
  //       ),
  //     );
  //   }
  // }

  // void logSetup({
  //   bool? responseBody,
  //   int? width,
  //   bool? responseHeader,
  //   bool? request,
  // }) {
  //   _showResponseHeader = responseHeader ?? _showResponseHeader;
  //   _requestBody = request ?? _requestBody;
  //   _maxWidth = width ?? _maxWidth;

  //   _dio.interceptors.clear();
  //   _dio.interceptors.add(
  //     PrettyDioLogger(
  //       responseBody: _requestBody,
  //       responseHeader: _showResponseHeader,
  //       maxWidth: _maxWidth,
  //       error: true,
  //     ),
  //   );
  // }

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
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) async {
    int attempts = 0;
    final options = Options(
      method: requestData.method.name,
      headers: requestData.headers,
    );

    while (true) {
      try {
        final response = await _dio.request(
          requestData.uri.toString(),
          data: requestData.body,
          options: options,
          cancelToken: cancelToken,
        );

        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          return Right(fromData(response.data));
        } else {
          final failure = DioFailure.withData(
            statusCode: response.statusCode ?? -1,
            request: requestData,
            error: response.data,
            isRetryable: !_nonRetryableStatusCodes.contains(
              response.statusCode,
            ),
          );
          if (!allowRetry || attempts >= _maxRetries || !failure.isRetryable) {
            return Left(failure);
          }
          attempts++;
          _talker.warning('[Retrying Response] Attempt: $attempts');
        }
      } on DioException catch (error) {
        final failure = DioFailure.withData(
          statusCode: error.response?.statusCode ?? -1,
          request: requestData,
          error: error.response?.data ?? error.message,
        );
        if (!allowRetry || attempts >= _maxRetries || !_shouldRetry(error)) {
          return Left(failure);
        }
        attempts++;
        _talker.warning('[Retrying DioError] Attempt: $attempts');
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

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.badCertificate;
  }

  // Convenience methods

  Future<Either<DioFailure, T>> get<T>({
    required String endPoint,
    required T Function(dynamic) fromData,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) {
    return handleRequest(
      requestData: RequestData(
        uri: Uri.parse("$_baseUrl$endPoint"),
        method: RequestMethod.get,
        headers: headers,
      ),
      fromData: fromData,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
    );
  }

  Future<Either<DioFailure, T>> post<T>({
    required String endPoint,
    required T Function(dynamic) fromData,
    dynamic body,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) {
    return handleRequest(
      requestData: RequestData(
        uri: Uri.parse("$_baseUrl$endPoint"),
        method: RequestMethod.post,
        body: body,
        headers: headers,
      ),
      fromData: fromData,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
    );
  }

  Future<Either<DioFailure, T>> put<T>({
    required String endPoint,
    required T Function(dynamic) fromData,
    dynamic body,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) {
    return handleRequest(
      requestData: RequestData(
        uri: Uri.parse("$_baseUrl$endPoint"),
        method: RequestMethod.put,
        body: body,
        headers: headers,
      ),
      fromData: fromData,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
    );
  }

  Future<Either<DioFailure, T>> patch<T>({
    required String endPoint,
    required T Function(dynamic) fromData,
    dynamic body,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) {
    return handleRequest(
      requestData: RequestData(
        uri: Uri.parse("$_baseUrl$endPoint"),
        method: RequestMethod.patch,
        body: body,
        headers: headers,
      ),
      fromData: fromData,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
    );
  }

  Future<Either<DioFailure, T>> delete<T>({
    required String endPoint,
    required T Function(dynamic) fromData,
    Map<String, String>? headers,
    dynamic body,
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) {
    return handleRequest(
      requestData: RequestData(
        uri: Uri.parse("$_baseUrl$endPoint"),
        method: RequestMethod.delete,
        body: body,
        headers: headers,
      ),
      fromData: fromData,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
    );
  }

  Future<Either<DioFailure, T>> upload<T>({
    required String endPoint,
    required T Function(dynamic) fromData,
    required FormData formData,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) {
    return handleRequest(
      requestData: RequestData(
        uri: Uri.parse("$_baseUrl$endPoint"),
        method: RequestMethod.post,
        body: formData,
        headers: headers,
      ),
      fromData: fromData,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
    );
  }

  Future<Either<DioFailure, T>> download<T>({
    required String url,
    required String savePath,
    required T Function(dynamic) fromData,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    Map<String, String>? headers,
    bool allowRetry = true,
  }) async {
    try {
      final response = await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
        options: Options(headers: headers),
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
