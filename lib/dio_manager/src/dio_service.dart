part of '../dio_manager.dart';

class DioService {
  late String _token = '';
  late String _baseUrl;
  final Map<String, String> _additionalHeaders = {};
  final Dio _dio = Dio();

  // Consolidated Logger Options
  bool _showResponseHeader = false;
  bool _requestBody = false;
  int _maxWidth = 150;

  DioService._() {
    _initializeDio();
  }

  static final DioService instance = DioService._();

  // Initializes Dio with common options and a single logger instance
  void _initializeDio() {
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
      ),
    );
    _setDefaultHeaders();
    _setTimeouts();
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

    // Avoid adding multiple instances of PrettyDioLogger
    _dio.interceptors.clear();
    _dio.interceptors.add(
      PrettyDioLogger(
        responseBody: _requestBody,
        responseHeader: _showResponseHeader,
        maxWidth: _maxWidth,
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

  // Consolidated function to set headers
  void _setDefaultHeaders() {
    _dio.options.headers = {
      "content-type": "application/json",
      "accept": "application/json",
      if (_token.isNotEmpty) "authorization": _token,
      "language": "en",
      ..._additionalHeaders
    };
  }

  // Consolidated timeout settings
  void _setTimeouts() {
    _dio.options.receiveTimeout = const Duration(milliseconds: 30000);
    _dio.options.sendTimeout = const Duration(milliseconds: 30000);
  }

  // Consolidated request handler for all HTTP methods
  Future<Either<DioFailure, T>> _handleRequest<T>({
    required Future<Response> Function() request,
    required T Function(dynamic data) fromData,
    required RequestMethod method,
    String? endPoint,
    String? url,
  }) async {
    try {
      final response = await request();
      final statusCode = response.statusCode ?? -1;

      if (statusCode >= 200 && statusCode < 300) {
        return Right(fromData(response.data));
      } else {
        return Left(
          DioFailure.withData(
            statusCode: statusCode,
            request: RequestData(
              method: method,
              uri: Uri.parse(url ?? "$_baseUrl$endPoint"),
            ),
            error: response.data,
          ),
        );
      }
    } catch (error) {
      final statusCode = (error is DioException) ? error.response?.statusCode ?? -1 : -1;
      final errorMessage = (error is DioException) ? error.message : error.toString();

      return Left(
        DioFailure.withData(
          statusCode: statusCode,
          request: RequestData(
            method: method,
            uri: Uri.parse(url ?? "$_baseUrl$endPoint"),
          ),
          error: errorMessage,
        ),
      );
    }
  }

  // GET request handler
  Future<Either<DioFailure, T>> get<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    Map<String, String>? header,
  }) {
    return _handleRequest(
      request: () => _dio.get(
        endPoint,
        options: Options(headers: header),
      ),
      fromData: fromData,
      method: RequestMethod.get,
      endPoint: endPoint,
    );
  }

  // POST request handler
  Future<Either<DioFailure, T>> post<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    dynamic data,
    Map<String, String>? header,
  }) {
    return _handleRequest(
      request: () => _dio.post(
        endPoint,
        data: data,
        options: Options(headers: header),
      ),
      fromData: fromData,
      method: RequestMethod.post,
      endPoint: endPoint,
    );
  }

  // PATCH request handler
  Future<Either<DioFailure, T>> patch<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    dynamic data,
    Map<String, String>? header,
  }) {
    return _handleRequest(
      request: () => _dio.patch(
        endPoint,
        data: data,
        options: Options(headers: header),
      ),
      fromData: fromData,
      method: RequestMethod.patch,
      endPoint: endPoint,
    );
  }

  // PUT request handler
  Future<Either<DioFailure, T>> put<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    dynamic data,
    Map<String, String>? header,
  }) {
    return _handleRequest(
      request: () => _dio.put(
        endPoint,
        data: data,
        options: Options(headers: header),
      ),
      fromData: fromData,
      method: RequestMethod.put,
      endPoint: endPoint,
    );
  }

  // File upload handler
  Future<Either<DioFailure, T>> upload<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    required FormData data,
    Map<String, String>? header,
  }) {
    return _handleRequest(
      request: () => _dio.post(
        endPoint,
        data: data,
        options: Options(headers: header),
      ),
      fromData: fromData,
      method: RequestMethod.post,
      endPoint: endPoint,
    );
  }

  // File download handler
  Future<Either<DioFailure, T>> download<T>({
    required String url,
    required String savePath,
    ProgressCallback? onReceiveProgress,
  }) {
    return _handleRequest(
      request: () => _dio.download(
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
