part of '../dio_manager.dart';

class DioService {
  late String _token = '';
  late String _baseUrl;
  final Map<String, String> _additionalHeaders = {};
  final Dio _dio = Dio();
  late bool? showResponseHeader;
  late bool? requestBody;
  late int? maxWidth;

  DioService._() {
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
      ),
    );
  }

  static final DioService instance = DioService._();

  void logSetup({
    bool? responseBody,
    int? width,
    bool? responseHeader,
    bool? request,
  }) {
    showResponseHeader = responseHeader;
    requestBody = request;
    maxWidth = width;
    _dio.interceptors.add(
      PrettyDioLogger(
        responseBody: requestBody ?? false,
        responseHeader: showResponseHeader ?? false,
        maxWidth: maxWidth ?? 150,
      ),
    );
  }

  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
    _dio.options.baseUrl = baseUrl;
  }

  void setToken(String token) {
    _token = token;
    _setHeaders();
  }

  void removeToken() {
    _token = '';
    _setHeaders();
  }

  void addHeader(String key, String value) {
    _additionalHeaders[key] = value;
    _setHeaders();
  }

  void removeHeader(String key) {
    _additionalHeaders.remove(key);
    _setHeaders();
  }

  void _setHeaders() {
    _dio.options.headers = {
      "content-type": "application/json",
      "accept": "application/json",
      if (_token.isNotEmpty) "authorization": _token,
      "language": "en",
      ..._additionalHeaders
    };
    _dio.options.receiveTimeout = const Duration(milliseconds: 30000);
    _dio.options.sendTimeout = const Duration(milliseconds: 30000);
  }

  Future<Either<DioFailure, T>> _handleRequest<T>({
    required Future<Response> Function() request,
    required T Function(dynamic data) fromData,
    RequestMethod method = RequestMethod.get,
    String? endPoint,
    String? url,
    Either<DioFailure, T> Function(
            int statusCode, Map<String, dynamic> responseBody)?
        failureHandler,
  }) async {
    try {
      final response = await request();
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        final responseData = fromData(response.data);
        return Right(responseData);
      } else {
        if (failureHandler != null) {
          return failureHandler(response.statusCode!, response.data);
        } else {
          return Left(DioFailure.withData(
            statusCode: response.statusCode!,
            request: RequestData(
                method: method, uri: Uri.parse("$_baseUrl$endPoint")),
            error: response.data,
          ));
        }
      }
    } catch (error) {
      if (error is DioException) {
        return Left(DioFailure.withData(
          statusCode: error.response?.statusCode ?? -1,
          request:
              RequestData(method: method, uri: Uri.parse("$_baseUrl$endPoint")),
          error: error.message,
        ));
      } else {
        return Left(DioFailure.withData(
          statusCode: -1,
          request:
              RequestData(method: method, uri: Uri.parse("$_baseUrl$endPoint")),
          error: error.toString(),
        ));
      }
    }
  }

  // File download method
  Future<Either<DioFailure, T>> download<T>({
    required String url,
    required String savePath,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.download(url, savePath,
          onReceiveProgress: onReceiveProgress);
      if (response.statusCode == 200) {
        return Right(response.data as T);
      } else {
        return Left(DioFailure.withData(
          statusCode: response.statusCode ?? -1,
          request: RequestData(method: RequestMethod.get, uri: Uri.parse(url)),
          error: response.data,
        ));
      }
    } catch (error) {
      if (error is DioException) {
        return Left(DioFailure.withData(
          statusCode: error.response?.statusCode ?? -1,
          request: RequestData(method: RequestMethod.get, uri: Uri.parse(url)),
          error: error.message,
        ));
      } else {
        return Left(DioFailure.withData(
          statusCode: -1,
          request: RequestData(method: RequestMethod.get, uri: Uri.parse(url)),
          error: error.toString(),
        ));
      }
    }
  }
}
