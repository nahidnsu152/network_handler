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
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Right(fromData(response.data));
      } else {
        return Left(
          DioFailure.withData(
            statusCode: response.statusCode ?? -1,
            request: RequestData(
              method: method,
              uri: Uri.parse(url ?? "$_baseUrl$endPoint"),
            ),
            error: response.data,
          ),
        );
      }
    } catch (error) {
      if (error is DioException) {
        return Left(
          DioFailure.withData(
            statusCode: error.response?.statusCode ?? -1,
            request: RequestData(
              method: method,
              uri: Uri.parse(url ?? "$_baseUrl$endPoint"),
            ),
            error: error.message,
          ),
        );
      } else {
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
    }
  }

  Future<Either<DioFailure, T>> get<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    Map<String, String>? header,
    bool? showLogs,
    Either<DioFailure, T> Function(
            int statusCode, Map<String, dynamic> responseBody)?
        failureHandler,
  }) {
    return _handleRequest(
      request: () => _dio.get(
        endPoint,
        options: Options(headers: header),
      ),
      fromData: fromData,
      method: RequestMethod.get,
      endPoint: endPoint,
      failureHandler: failureHandler,
    );
  }

  Future<Either<DioFailure, T>> post<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    dynamic data,
    Map<String, String>? header,
    bool? showLogs,
    Either<DioFailure, T> Function(
            int statusCode, Map<String, dynamic> responseBody)?
        failureHandler,
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
      failureHandler: failureHandler,
    );
  }

  Future<Either<DioFailure, T>> patch<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    dynamic data,
    Map<String, String>? header,
    bool? showLogs,
    Either<DioFailure, T> Function(
            int statusCode, Map<String, dynamic> responseBody)?
        failureHandler,
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
      failureHandler: failureHandler,
    );
  }

  Future<Either<DioFailure, T>> put<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    dynamic data,
    Map<String, String>? header,
    bool? showLogs,
    Either<DioFailure, T> Function(
            int statusCode, Map<String, dynamic> responseBody)?
        failureHandler,
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
      failureHandler: failureHandler,
    );
  }

  Future<Either<DioFailure, T>> upload<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    required FormData data,
    Map<String, String>? header,
    bool? showLogs,
    Either<DioFailure, T> Function(
            int statusCode, Map<String, dynamic> responseBody)?
        failureHandler,
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
      failureHandler: failureHandler,
    );
  }

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




// class ApiService {
//   late String _token = '';
//   late String _baseUrl;
//   final Map<String, String> _additionalHeaders = {};

//   void setToken(String token) {
//     _token = token;
//   }

//   void setBaseUrl(String baseUrl) {
//     _baseUrl = baseUrl;
//   }

//   void addHeader(String key, String value) {
//     _additionalHeaders[key] = value;
//   }

//   void removeHeader(String key) {
//     _additionalHeaders.remove(key);
//   }

//   Future<Dio> getDio() async {
//     Dio dio = Dio();
//     Map<String, String> headers = {
//       "content-type": "application/json",
//       "accept": "application/json",
//       if (_token.isNotEmpty) "authorization": "Bearer $_token",
//       "language": "en",
//       ..._additionalHeaders
//     };

//     dio.options = BaseOptions(
//       baseUrl: _baseUrl,
//       headers: headers,
//       receiveTimeout: const Duration(milliseconds: 30000),
//       sendTimeout: const Duration(milliseconds: 30000),
//       connectTimeout: const Duration(milliseconds: 300000),
//     );

//     dio.interceptors.add(
//       PrettyDioLogger(
//         requestBody: true,
//         maxWidth: 150,
//       ),
//     );

//     return dio;
//   }

//   ApiService._();

//   static final ApiService instance = ApiService._();

//   Future<Either<Failure, T>> get<T>({
//     required T Function(dynamic data) fromData,
//     required String endPoint,
//     bool? showLogs,
//     Either<Failure, T> Function(
//       int statusCode,
//       Map<String, dynamic> responseBody,
//     )? failureHandler,
//     Map<String, String>? header,
//   }) async {
//     Dio dio = await getDio();
//     try {
//       final response = await dio.get(
//         "$_baseUrl$endPoint",
//         options: Options(
//           headers: header,
//         ),
//       );
//       if (response.statusCode == 200) {
//         return Right(fromData(response.data));
//       } else {
//         return Left(
//           Failure.withData(
//             statusCode: response.statusCode ?? -1,
//             request: RequestData(
//               method: RequestMethod.get,
//               uri: Uri.parse("$_baseUrl$endPoint"),
//               fromData: (data) {},
//             ),
//             error: response.data,
//           ),
//         );
//       }
//     } catch (error) {
//       if (error is DioException) {
//         return Left(
//           Failure.withData(
//             statusCode: error.response?.statusCode ?? -1,
//             request: RequestData(
//               method: RequestMethod.get,
//               uri: Uri.parse("$_baseUrl$endPoint"),
//             ),
//             error: error.message,
//           ),
//         );
//       } else {
//         return Left(
//           Failure.withData(
//             statusCode: -1,
//             request: RequestData(
//               method: RequestMethod.get,
//               uri: Uri.parse("$_baseUrl$endPoint"),
//             ),
//             error: error.toString(),
//           ),
//         );
//       }
//     }
//   }

//   Future<Either<Failure, T>> post<T>({
//     required T Function(dynamic data) fromData,
//     required String endPoint,
//     dynamic data,
//     bool? showLogs,
//     Either<Failure, T> Function(
//       int statusCode,
//       Map<String, dynamic> responseBody,
//     )? failureHandler,
//     Map<String, String>? header,
//   }) async {
//     Dio dio = await getDio();
//     try {
//       final response = await dio.post(
//         "$_baseUrl$endPoint",
//         data: data,
//         options: Options(headers: header),
//       );
//       if (response.statusCode == 200) {
//         return Right(
//           fromData(response.data),
//         );
//       } else {
//         return Left(
//           Failure.withData(
//             statusCode: response.statusCode ?? -1,
//             request: RequestData(
//               method: RequestMethod.post,
//               uri: Uri.parse("$_baseUrl$endPoint"),
//             ),
//             error: response.data,
//           ),
//         );
//       }
//     } catch (error) {
//       if (error is DioException) {
//         return Left(
//           Failure.withData(
//             statusCode: error.response?.statusCode ?? -1,
//             request: RequestData(
//               method: RequestMethod.post,
//               uri: Uri.parse("$_baseUrl$endPoint"),
//             ),
//             error: error.message,
//           ),
//         );
//       } else {
//         return Left(
//           Failure.withData(
//             statusCode: -1,
//             request: RequestData(
//               method: RequestMethod.post,
//               uri: Uri.parse("$_baseUrl$endPoint"),
//             ),
//             error: error.toString(),
//           ),
//         );
//       }
//     }
//   }

//   // PATCH method
//   Future<Either<Failure, T>> patch<T>({
//     required T Function(dynamic data) fromData,
//     required String endPoint,
//     dynamic data,
//     bool? showLogs,
//     Either<Failure, T> Function(
//             int statusCode, Map<String, dynamic> responseBody)?
//         failureHandler,
//     Map<String, String>? header,
//   }) async {
//     Dio dio = await getDio();
//     try {
//       final response = await dio.patch("$_baseUrl$endPoint",
//           data: data, options: Options(headers: header));
//       if (response.statusCode == 200) {
//         return Right(
//           fromData(response.data),
//         );
//       } else {
//         return Left(
//           Failure.withData(
//             statusCode: response.statusCode ?? -1,
//             request: RequestData(
//               method: RequestMethod.patch,
//               uri: Uri.parse("$_baseUrl$endPoint"),
//             ),
//             error: response.data,
//           ),
//         );
//       }
//     } catch (error) {
//       if (error is DioException) {
//         return Left(
//           Failure.withData(
//             statusCode: error.response?.statusCode ?? -1,
//             request: RequestData(
//               method: RequestMethod.patch,
//               uri: Uri.parse("$_baseUrl$endPoint"),
//             ),
//             error: error.message,
//           ),
//         );
//       } else {
//         return Left(
//           Failure.withData(
//             statusCode: -1,
//             request: RequestData(
//               method: RequestMethod.patch,
//               uri: Uri.parse("$_baseUrl$endPoint"),
//             ),
//             error: error.toString(),
//           ),
//         );
//       }
//     }
//   }

//   // PUT method
//   Future<Either<Failure, T>> put<T>({
//     required T Function(dynamic data) fromData,
//     required String endPoint,
//     dynamic data,
//     bool? showLogs,
//     Either<Failure, T> Function(
//       int statusCode,
//       Map<String, dynamic> responseBody,
//     )? failureHandler,
//     Map<String, String>? header,
//   }) async {
//     Dio dio = await getDio();
//     try {
//       final response = await dio.put(
//         "$_baseUrl$endPoint",
//         data: data,
//         options: Options(headers: header),
//       );
//       if (response.statusCode == 200) {
//         return Right(
//           fromData(response.data),
//         );
//       } else {
//         return Left(Failure.withData(
//           statusCode: response.statusCode ?? -1,
//           request: RequestData(
//             method: RequestMethod.put,
//             uri: Uri.parse("$_baseUrl$endPoint"),
//           ),
//           error: response.data,
//         ));
//       }
//     } catch (error) {
//       if (error is DioException) {
//         return Left(
//           Failure.withData(
//             statusCode: error.response?.statusCode ?? -1,
//             request: RequestData(
//               method: RequestMethod.put,
//               uri: Uri.parse("$_baseUrl$endPoint"),
//             ),
//             error: error.message,
//           ),
//         );
//       } else {
//         return Left(Failure.withData(
//           statusCode: -1,
//           request: RequestData(
//             method: RequestMethod.put,
//             uri: Uri.parse("$_baseUrl$endPoint"),
//           ),
//           error: error.toString(),
//         ));
//       }
//     }
//   }

//   // File upload method
//   Future<Either<Failure, T>> upload<T>({
//     required T Function(dynamic data) fromData,
//     required String endPoint,
//     required FormData data,
//     bool? showLogs,
//     Either<Failure, T> Function(
//       int statusCode,
//       Map<String, dynamic> responseBody,
//     )? failureHandler,
//     Map<String, String>? header,
//   }) async {
//     Dio dio = await getDio();
//     try {
//       final response = await dio.post(
//         "$_baseUrl$endPoint",
//         data: data,
//         options: Options(headers: header),
//       );
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return Right(fromData(response.data));
//       } else {
//         return Left(
//           Failure.withData(
//             statusCode: response.statusCode ?? -1,
//             request: RequestData(
//               method: RequestMethod.post,
//               uri: Uri.parse("$_baseUrl$endPoint"),
//             ),
//             error: response.data,
//           ),
//         );
//       }
//     } catch (error) {
//       if (error is DioException) {
//         return Left(
//           Failure.withData(
//             statusCode: error.response?.statusCode ?? -1,
//             request: RequestData(
//               method: RequestMethod.post,
//               uri: Uri.parse("$_baseUrl$endPoint"),
//             ),
//             error: error.message,
//           ),
//         );
//       } else {
//         return Left(
//           Failure.withData(
//             statusCode: -1,
//             request: RequestData(
//               method: RequestMethod.post,
//               uri: Uri.parse("$_baseUrl$endPoint"),
//             ),
//             error: error.toString(),
//           ),
//         );
//       }
//     }
//   }

//   // File download method
//   Future<Either<Failure, T>> download<T>({
//     required String url,
//     required String savePath,
//     ProgressCallback? onReceiveProgress,
//   }) async {
//     Dio dio = await getDio();
//     try {
//       final response = await dio.download(url, savePath,
//           onReceiveProgress: onReceiveProgress);
//       if (response.statusCode == 200) {
//         return Right(response.data as T);
//       } else {
//         return Left(
//           Failure.withData(
//             statusCode: response.statusCode ?? -1,
//             request: RequestData(
//               method: RequestMethod.get,
//               uri: Uri.parse(url),
//             ),
//             error: response.data,
//           ),
//         );
//       }
//     } catch (error) {
//       if (error is DioException) {
//         return Left(
//           Failure.withData(
//             statusCode: error.response?.statusCode ?? -1,
//             request: RequestData(
//               method: RequestMethod.get,
//               uri: Uri.parse(url),
//             ),
//             error: error.message,
//           ),
//         );
//       } else {
//         return Left(
//           Failure.withData(
//             statusCode: -1,
//             request: RequestData(
//               method: RequestMethod.get,
//               uri: Uri.parse(url),
//             ),
//             error: error.toString(),
//           ),
//         );
//       }
//     }
//   }
// }
