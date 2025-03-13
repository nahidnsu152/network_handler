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
          Logger.e("[TYPE ERROR] Failed to parse response.");
          Logger.e("[STACKTRACE] $stackTrace");
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
        Logger.e("[ERROR] Request failed with status: ${response.statusCode}");
        return Left(
          DioFailure.withData(
            statusCode: response.statusCode!,
            request: RequestData(
              method: RequestMethod.get,
              uri: response.requestOptions.uri,
            ),
            error: response.data,
          ),
        );
      }
    } catch (e, stackTrace) {
      Logger.e("[EXCEPTION]: $e");
      Logger.e("[STACKTRACE]: $stackTrace");
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
  }) async {
    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        final response = await request();
        return _handleResponse(
          response: response,
          endPoint: endPoint ?? "",
          fromData: fromData,
        );
      } catch (error) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          Logger.e("[RETRY FAILED] All attempts exhausted. Giving up.");
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
        Logger.i("[RETRYING] Attempt: $retryCount");
      }
    }
    return Left(
      DioFailure.withData(
        statusCode: -1,
        request: RequestData(
          method: method,
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
  }) {
    return _handleRequest(
      request: () => _dio.get(endPoint, options: Options(headers: header)),
      fromData: fromData,
      method: RequestMethod.get,
      endPoint: endPoint,
    );
  }

  Future<Either<DioFailure, T>> post<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    dynamic data,
    Map<String, String>? header,
  }) {
    return _handleRequest(
      request:
          () => _dio.post(
            endPoint,
            data: data,
            options: Options(headers: header),
          ),
      fromData: fromData,
      method: RequestMethod.post,
      endPoint: endPoint,
    );
  }

  Future<Either<DioFailure, T>> patch<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    dynamic data,
    Map<String, String>? header,
  }) {
    return _handleRequest(
      request:
          () => _dio.patch(
            endPoint,
            data: data,
            options: Options(headers: header),
          ),
      fromData: fromData,
      method: RequestMethod.patch,
      endPoint: endPoint,
    );
  }

  Future<Either<DioFailure, T>> put<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    dynamic data,
    Map<String, String>? header,
  }) {
    return _handleRequest(
      request:
          () =>
              _dio.put(endPoint, data: data, options: Options(headers: header)),
      fromData: fromData,
      method: RequestMethod.put,
      endPoint: endPoint,
    );
  }

  Future<Either<DioFailure, T>> upload<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    required FormData data,
    Map<String, String>? header,
  }) {
    return _handleRequest(
      request:
          () => _dio.post(
            endPoint,
            data: data,
            options: Options(headers: header),
          ),
      fromData: fromData,
      method: RequestMethod.post,
      endPoint: endPoint,
    );
  }

  Future<Either<DioFailure, T>> download<T>({
    required String url,
    required String savePath,
    ProgressCallback? onReceiveProgress,
  }) {
    return _handleRequest(
      request:
          () => _dio.download(
            url,
            savePath,
            onReceiveProgress: onReceiveProgress,
          ),
      fromData: (data) => data as T,
      method: RequestMethod.get,
      url: url,
    );
  }
}

enum LoggerType { talker, pretty }
