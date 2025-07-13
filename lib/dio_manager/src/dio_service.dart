part of '../dio_manager.dart';

class DioService {
  late String _token = '';
  late String _baseUrl;
  final Map<String, String> _additionalHeaders = {};
  final Dio _dio = Dio();
  LoggerType _loggerType = LoggerType.talker;

  // Logging and retry options
  bool _showResponseHeader = false;
  bool _requestBody = false;
  int _maxWidth = 150;
  final int _maxRetries = 3; // Max retry attempts
  final List<int> _nonRetryableStatusCodes = [
    400,
    401,
    403,
    404,
  ]; // Skip retries for these

  final _talker = Talker();

  DioService._() {
    _initializeDio();
  }
  static final DioService instance = DioService._();

  void _initializeDio() {
    _setLogger(); // Set the default logger
    _setDefaultHeaders();
    _setTimeouts();
  }

  /// Set logger type dynamically
  void setLogger(LoggerType loggerType) {
    _loggerType = loggerType;
    _setLogger();
  }

  void _setLogger() {
    _dio.interceptors.clear(); // Clear existing loggers

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

    _dio.interceptors.clear();
    _dio.interceptors.add(
      PrettyDioLogger(
        responseBody: _requestBody,
        responseHeader: _showResponseHeader,
        maxWidth: _maxWidth,
        error: true,
      ),
    );
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

  Either<DioFailure, T> _handleResponse<T>({
    required Response response,
    required String endPoint,
    required T Function(dynamic data) fromData,
  }) {
    try {
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        try {
          final T parsedData = fromData(response.data);
          return Right(parsedData);
        } catch (e, stackTrace) {
          _talker.error("[Error]: $e");
          _talker.error("[STACKTRACE]: $stackTrace");
          return Left(
            DioFailure.withData(
              statusCode: response.statusCode!,
              request: RequestData(
                method: RequestMethod.get,
                uri: response.requestOptions.uri,
              ),
              error: "Type Mismatch Error: ${e.toString()}",
            ),
          );
        }
      } else {
        _talker.error(
          "[ERROR]: Request failed with status: ${response.statusCode}",
        );
        return Left(
          DioFailure.withData(
            statusCode: response.statusCode!,
            request: RequestData(
              method: RequestMethod.get,
              uri: response.requestOptions.uri,
            ),
            error: response.data,
            isRetryable: !_nonRetryableStatusCodes.contains(
              response.statusCode,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      _talker.error("[EXCEPTION]: $e");
      _talker.error("[STACKTRACE]: $stackTrace");
      return Left(
        DioFailure.withData(
          statusCode: -1,
          request: RequestData(
            method: RequestMethod.get,
            uri: response.requestOptions.uri,
          ),
          error: e.toString(),
        ),
      );
    }
  }

  Future<Either<DioFailure, T>> _handleRequest<T>({
    required Future<Response> Function() request,
    required T Function(dynamic data) fromData,
    required RequestMethod method,
    String? endPoint,
    String? url,
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) async {
    int retryCount = 0;
    while (retryCount < _maxRetries && allowRetry) {
      try {
        final response = await request();
        final result = _handleResponse(
          response: response,
          endPoint: endPoint ?? "",
          fromData: fromData,
        );
        // Check if the result is a failure and non-retryable
        return result.fold((failure) {
          if (!failure.isRetryable) {
            _talker.info(
              "[NON-RETRYABLE]: Status code ${failure.statusCode} is not retryable.",
            );
            return Left(failure);
          }
          // If retryable, continue to the next iteration
          retryCount++;
          if (retryCount >= _maxRetries) {
            _talker.error("[RETRY FAILED]: All attempts exhausted. Giving up.");
            return Left(failure);
          }
          _talker.info("[RETRYING] Attempt: $retryCount");
          return result;
        }, (success) => Right(success));
      } catch (error) {
        if (error is DioException && error.type == DioExceptionType.cancel) {
          _talker.info("[CANCELLED]: Request was cancelled.");
          return Left(
            DioFailure.withData(
              statusCode: -1,
              request: RequestData(
                method: method,
                uri: Uri.parse(url ?? "$_baseUrl$endPoint"),
              ),
              error: "Request Cancelled",
              isRetryable: false,
            ),
          );
        }
        retryCount++;
        if (retryCount >= _maxRetries) {
          _talker.error("[RETRY FAILED]: All attempts exhausted. Giving up.");
          return Left(
            DioFailure.withData(
              statusCode: -1,
              request: RequestData(
                method: method,
                uri: Uri.parse(url ?? "$_baseUrl$endPoint"),
              ),
              error: error.toString(),
            ),
          );
        }
        _talker.info("[RETRYING] Attempt: $retryCount");
        await Future.delayed(Duration(milliseconds: 1000 * retryCount));
      }
    }
    return Left(
      DioFailure.withData(
        statusCode: -1,
        request: RequestData(
          method: RequestMethod.get,
          uri: Uri.parse(url ?? "$_baseUrl$endPoint"),
        ),
        error: "Unexpected Error",
      ),
    );
  }

  Future<Either<DioFailure, T>> get<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    Map<String, String>? header,
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) {
    return _handleRequest(
      request: () => _dio.get(
        endPoint,
        options: Options(headers: header),
        cancelToken: cancelToken,
      ),
      fromData: fromData,
      method: RequestMethod.get,
      endPoint: endPoint,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
    );
  }

  Future<Either<DioFailure, T>> post<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    dynamic body,
    Map<String, String>? header,
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) {
    return _handleRequest(
      request: () => _dio.post(
        endPoint,
        data: body,
        options: Options(headers: header),
        cancelToken: cancelToken,
      ),
      fromData: fromData,
      method: RequestMethod.post,
      endPoint: endPoint,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
    );
  }

  Future<Either<DioFailure, T>> patch<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    dynamic body,
    Map<String, String>? header,
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) {
    return _handleRequest(
      request: () => _dio.patch(
        endPoint,
        data: body,
        options: Options(headers: header),
        cancelToken: cancelToken,
      ),
      fromData: fromData,
      method: RequestMethod.patch,
      endPoint: endPoint,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
    );
  }

  Future<Either<DioFailure, T>> put<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    dynamic body,
    Map<String, String>? header,
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) {
    return _handleRequest(
      request: () => _dio.put(
        endPoint,
        data: body,
        options: Options(headers: header),
        cancelToken: cancelToken,
      ),
      fromData: fromData,
      method: RequestMethod.put,
      endPoint: endPoint,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
    );
  }

  Future<Either<DioFailure, T>> upload<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    required FormData body,
    Map<String, String>? header,
    CancelToken? cancelToken,
    bool allowRetry = true,
  }) {
    return _handleRequest(
      request: () => _dio.post(
        endPoint,
        data: body,
        options: Options(headers: header),
        cancelToken: cancelToken,
      ),
      fromData: fromData,
      method: RequestMethod.post,
      endPoint: endPoint,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
    );
  }

  Future<Either<DioFailure, T>> download<T>({
    required String url,
    required String savePath,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    Map<String, String>? headers,
    String? range,
    bool allowRetry = true,
  }) {
    return _handleRequest(
      request: () => _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
        options: Options(
          headers: {if (range != null) 'Range': range, ...?headers},
        ),
      ),
      fromData: (data) => data as T,
      method: RequestMethod.get,
      url: url,
      cancelToken: cancelToken,
      allowRetry: allowRetry,
    );
  }
}
