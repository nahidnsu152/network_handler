// // import 'package:dio/dio.dart';
// // import 'package:fpdart/fpdart.dart';

// // import '../../common/models/failure.dart';
// // import '../../common/models/request_options.dart';

// // class ApiService {
// //   final Dio _dio;

// //   ApiService(this._dio);

// //   Future<Either<Failure, T>> get<T>({
// //     required T Function(dynamic data) fromData,
// //     required String endPoint,
// //     bool? showLogs,
// //     Either<Failure, T> Function(
// //             int statusCode, Map<String, dynamic> responseBody)?
// //         failureHandler,
// //     Map<String, String>? header,
// //   }) async {
// //     try {
// //       final response =
// //           await _dio.get(endPoint, options: Options(headers: header));
// //       if (response.statusCode == 200) {
// //         return Right(fromData(response.data));
// //       } else {
// //         return Left(Failure.withData(
// //           statusCode: response.statusCode ?? -1,
// //           request:
// //               RequestData(method: RequestMethod.get, uri: Uri.parse(endPoint)),
// //           error: response.data,

// //         ));
// //       }
// //     } catch (error) {
// //       if (error is DioException) {
// //         return Left(Failure.withData(
// //           statusCode: error.response?.statusCode ?? -1,
// //           request:
// //               RequestData(method: RequestMethod.get, uri: Uri.parse(endPoint)),
// //           error: error.message,
// //         ));
// //       } else {
// //         return Left(Failure.withData(
// //           statusCode: -1,
// //           request:
// //               RequestData(method: RequestMethod.get, uri: Uri.parse(endPoint)),
// //           error: error.toString(),
// //         ));
// //       }
// //     }
// //   }

// //   Future<Either<Failure, T>> post<T>({
// //     required T Function(dynamic data) fromData,
// //     required String endPoint,
// //     dynamic data,
// //     bool? showLogs,
// //     Either<Failure, T> Function(
// //             int statusCode, Map<String, dynamic> responseBody)?
// //         failureHandler,
// //     Map<String, String>? header,
// //   }) async {
// //     try {
// //       final response = await _dio.post(
// //         endPoint,
// //         data: data,
// //         options: Options(headers: header),
// //       );
// //       if (response.statusCode == 200) {
// //         return Right(fromData(response.data));
// //       } else {
// //         return Left(Failure.withData(
// //           statusCode: response.statusCode ?? -1,
// //           request:
// //               RequestData(method: RequestMethod.post, uri: Uri.parse(endPoint)),
// //           error: response.data,
// //         ));
// //       }
// //     } catch (error) {
// //       if (error is DioException) {
// //         return Left(Failure.withData(
// //           statusCode: error.response?.statusCode ?? -1,
// //           request:
// //               RequestData(method: RequestMethod.post, uri: Uri.parse(endPoint)),
// //           error: error.message,
// //         ));
// //       } else {
// //         return Left(Failure.withData(
// //           statusCode: -1,
// //           request: RequestData(
// //               method: RequestMethod.post,
// //               uri: Uri.parse(endPoint),
// //               fromData: (data) {}),
// //           error: error.toString(),
// //         ));
// //       }
// //     }
// //   }
// // }

// import 'dart:io';

// import 'package:dio/dio.dart';
// import 'package:fpdart/fpdart.dart';
// import 'package:pretty_dio_logger/pretty_dio_logger.dart';

// import '../../common/models/failure.dart';
// import '../../common/models/request_options.dart';

// class ApiService {
//   final Dio _dio;

//   ApiService(this._dio);

//   Future<Either<Failure, T>> fetch<T>({
//     required RequestData<T> request,
//     Map<String, dynamic>? queryParameters,
//   }) async {
//     try {
//       late Response response;

//       final options = Options(headers: request.headers);

//       switch (request.method) {
//         case RequestMethod.get:
//           response = await _dio.get(
//             request.uri.toString(),
//             queryParameters: queryParameters,
//             options: options,
//           );
//           break;
//         case RequestMethod.post:
//           response = await _dio.post(
//             request.uri.toString(),
//             data: request.jsonEncodedBody,
//             queryParameters: queryParameters,
//             options: options,
//           );
//           break;
//         case RequestMethod.put:
//           response = await _dio.put(
//             request.uri.toString(),
//             data: request.jsonEncodedBody,
//             queryParameters: queryParameters,
//             options: options,
//           );
//           break;
//         case RequestMethod.patch:
//           response = await _dio.patch(
//             request.uri.toString(),
//             data: request.jsonEncodedBody,
//             queryParameters: queryParameters,
//             options: options,
//           );
//           break;
//         case RequestMethod.delete:
//           response = await _dio.delete(
//             request.uri.toString(),
//             data: request.jsonEncodedBody,
//             queryParameters: queryParameters,
//             options: options,
//           );
//           break;
//       }

//       if (response.statusCode == 200) {
//         return Right(request.fromData(response.data));
//       } else {
//         return _handleFailure(
//           response.statusCode ?? -1,
//           request,
//           response.data,
//         );
//       }
//     } catch (error) {
//       return _handleError(request, error);
//     }
//   }

//   Future<Either<Failure, T>> get<T>({
//     required T Function(dynamic data) fromData,
//     required String endPoint,
//     bool? showLogs,
//     Either<Failure, T> Function(
//             int statusCode, Map<String, dynamic> responseBody)?
//         failureHandler,
//     Map<String, String>? header,
//     Map<String, dynamic>? queryParameters,
//   }) async {
//     final request = RequestData<T>(
//       method: RequestMethod.get,
//       uri: Uri.parse(endPoint),
//       showLogs: showLogs ?? false,
//       fromData: fromData,
//       headers: header,
//       failureHandler: failureHandler,
//     );
//     return fetch(request: request, queryParameters: queryParameters);
//   }

//   Future<Either<Failure, T>> post<T>({
//     required T Function(dynamic data) fromData,
//     required String endPoint,
//     dynamic data,
//     bool? showLogs,
//     Either<Failure, T> Function(
//             int statusCode, Map<String, dynamic> responseBody)?
//         failureHandler,
//     Map<String, String>? header,
//     Map<String, dynamic>? queryParameters,
//   }) async {
//     final request = RequestData<T>(
//       method: RequestMethod.post,
//       uri: Uri.parse(endPoint),
//       body: data,
//       showLogs: showLogs ?? false,
//       fromData: fromData,
//       headers: header,
//       failureHandler: failureHandler,
//     );
//     return fetch(request: request, queryParameters: queryParameters);
//   }

//   Future<Either<Failure, T>> download<T>({
//     required String urlPath,
//     required String savePath,
//     ProgressCallback? onReceiveProgress,
//     Map<String, String>? headers,
//     Map<String, dynamic>? queryParameters,
//   }) async {
//     try {
//       final response = await _dio.download(
//         urlPath,
//         savePath,
//         onReceiveProgress: onReceiveProgress,
//         options: Options(headers: headers),
//         queryParameters: queryParameters,
//       );

//       if (response.statusCode == 200) {
//         return Right(response.data);
//       } else {
//         return Left(Failure.withData(
//           statusCode: response.statusCode ?? -1,
//           request: RequestData(
//             method: RequestMethod.get,
//             uri: Uri.parse(urlPath),
//             fromData: (data) {},
//           ),
//           error: response.data,
//         ));
//       }
//     } catch (error) {
//       return _handleError(
//         RequestData(
//           method: RequestMethod.get,
//           uri: Uri.parse(urlPath),
//           fromData: (data) {
//             return data;
//           },
//         ),
//         error,
//       );
//     }
//   }

//   Future<Either<Failure, T>> uploadFiles<T>({
//     required T Function(dynamic data) fromData,
//     required String endPoint,
//     required List<File> files,
//     bool? showLogs,
//     Either<Failure, T> Function(
//             int statusCode, Map<String, dynamic> responseBody)?
//         failureHandler,
//     Map<String, String>? header,
//     Map<String, dynamic>? queryParameters,
//     Map<String, dynamic>? additionalData,
//   }) async {
//     try {
//       FormData formData = FormData();

//       for (var file in files) {
//         formData.files.add(MapEntry(
//           "files",
//           await MultipartFile.fromFile(file.path,
//               filename: file.uri.pathSegments.last),
//         ));
//       }

//       if (additionalData != null) {
//         formData.fields.addAll(additionalData.entries
//             .map((e) => MapEntry(e.key, e.value.toString())));
//       }

//       final response = await _dio.post(
//         endPoint,
//         data: formData,
//         options: Options(headers: header),
//         queryParameters: queryParameters,
//       );

//       if (response.statusCode == 200) {
//         return Right(fromData(response.data));
//       } else {
//         return Left(
//           Failure.withData(
//             statusCode: response.statusCode ?? -1,
//             request: RequestData(
//                 method: RequestMethod.post,
//                 uri: Uri.parse(endPoint),
//                 fromData: (data) {}),
//             error: response.data,
//           ),
//         );
//       }
//     } catch (error) {
//       PrettyDioLogger(
//         error: true,
//         request: true,
//         requestHeader: true,
//         responseBody: true,
//       );
//       return Left(
//         Failure.withData(
//           statusCode: -1,
//           request: RequestData(
//               method: RequestMethod.post,
//               uri: Uri.parse(endPoint),
//               fromData: (data) {}),
//           error: error,
//         ),
//       );
//     }
//   }

//   Future<Either<Failure, Stream<List<int>>>> getResponseStream({
//     required String endPoint,
//     Map<String, String>? headers,
//     Map<String, dynamic>? queryParameters,
//   }) async {
//     try {
//       final response = await _dio.get(
//         endPoint,
//         options: Options(
//           responseType: ResponseType.stream,
//           headers: headers,
//         ),
//         queryParameters: queryParameters,
//       );

//       if (response.statusCode == 200) {
//         return Right(response.data.stream);
//       } else {
//         return Left(Failure.withData(
//           statusCode: response.statusCode ?? -1,
//           request: RequestData(
//               method: RequestMethod.get,
//               uri: Uri.parse(endPoint),
//               fromData: (data) {}),
//           error: response.data,
//         ));
//       }
//     } catch (error) {
//       PrettyDioLogger(
//         error: true,
//         request: true,
//         requestHeader: true,
//         responseBody: true,
//       );
//       return Left(
//         Failure.withData(
//           statusCode: -1,
//           request: RequestData(
//             method: RequestMethod.get,
//             uri: Uri.parse(endPoint),
//             fromData: (data) {},
//           ),
//           error: error,
//         ),
//       );
//     }
//   }

//   Either<Failure, T> _handleFailure<T>(
//       int statusCode, RequestData<T> request, dynamic error) {
//     final failure = Failure.withData(
//       statusCode: statusCode,
//       request: request,
//       error: error,
//     );
//     return Left(failure);
//   }

//   Either<Failure, T> _handleError<T>(RequestData<T> request, dynamic error) {
//     if (error is DioException) {
//       return _handleFailure(
//         error.response?.statusCode ?? -1,
//         request,
//         error.message,
//       );
//     } else {
//       return _handleFailure(
//         -1,
//         request,
//         error.toString(),
//       );
//     }
//   }
// }

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../common/models/failure.dart';
import '../../common/models/request_options.dart';

class ApiService {
  final Dio _dio;

  static final ApiService _instance = ApiService._internal(Dio());

  factory ApiService() {
    return _instance;
  }

  ApiService._internal(this._dio) {
    // Initial configuration of Dio
    _dio.options = BaseOptions(
      connectTimeout: const Duration(milliseconds: 30000),
      receiveTimeout: const Duration(milliseconds: 30000),
    );
    _dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  // Method to update Dio options and interceptors if needed
  void updateDioOptions(BaseOptions options,
      [List<Interceptor>? interceptors]) {
    _dio.options = options;
    if (interceptors != null) {
      _dio.interceptors.clear();
      _dio.interceptors.addAll(interceptors);
    }
  }

  Future<Either<Failure, T>> fetch<T>({
    required RequestData<T> request,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      late Response response;

      final options = Options(headers: request.headers);

      switch (request.method) {
        case RequestMethod.get:
          response = await _dio.get(
            request.uri.toString(),
            queryParameters: queryParameters,
            options: options,
          );
          break;
        case RequestMethod.post:
          response = await _dio.post(
            request.uri.toString(),
            data: request.jsonEncodedBody,
            queryParameters: queryParameters,
            options: options,
          );
          break;
        case RequestMethod.put:
          response = await _dio.put(
            request.uri.toString(),
            data: request.jsonEncodedBody,
            queryParameters: queryParameters,
            options: options,
          );
          break;
        case RequestMethod.patch:
          response = await _dio.patch(
            request.uri.toString(),
            data: request.jsonEncodedBody,
            queryParameters: queryParameters,
            options: options,
          );
          break;
        case RequestMethod.delete:
          response = await _dio.delete(
            request.uri.toString(),
            data: request.jsonEncodedBody,
            queryParameters: queryParameters,
            options: options,
          );
          break;
      }

      if (response.statusCode == 200) {
        return Right(request.fromData(response.data));
      } else {
        return _handleFailure(
          response.statusCode ?? -1,
          request,
          response.data,
        );
      }
    } catch (error) {
      return _handleError(request, error);
    }
  }

  Future<Either<Failure, T>> get<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    bool? showLogs,
    Either<Failure, T> Function(
            int statusCode, Map<String, dynamic> responseBody)?
        failureHandler,
    Map<String, String>? header,
    Map<String, dynamic>? queryParameters,
  }) async {
    final request = RequestData<T>(
      method: RequestMethod.get,
      uri: Uri.parse(endPoint),
      showLogs: showLogs ?? false,
      fromData: fromData,
      headers: header,
      failureHandler: failureHandler,
    );
    return fetch(request: request, queryParameters: queryParameters);
  }

  Future<Either<Failure, T>> post<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    dynamic data,
    bool? showLogs,
    Either<Failure, T> Function(
            int statusCode, Map<String, dynamic> responseBody)?
        failureHandler,
    Map<String, String>? header,
    Map<String, dynamic>? queryParameters,
  }) async {
    final request = RequestData<T>(
      method: RequestMethod.post,
      uri: Uri.parse(endPoint),
      body: data,
      showLogs: showLogs ?? false,
      fromData: fromData,
      headers: header,
      failureHandler: failureHandler,
    );
    return fetch(request: request, queryParameters: queryParameters);
  }

  Future<Either<Failure, T>> download<T>({
    required String urlPath,
    required String savePath,
    ProgressCallback? onReceiveProgress,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        options: Options(headers: headers),
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        return Right(response.data);
      } else {
        return Left(Failure.withData(
          statusCode: response.statusCode ?? -1,
          request: RequestData(
            method: RequestMethod.get,
            uri: Uri.parse(urlPath),
            fromData: (data) {},
          ),
          error: response.data,
        ));
      }
    } catch (error) {
      return _handleError(
        RequestData(
          method: RequestMethod.get,
          uri: Uri.parse(urlPath),
          fromData: (data) {
            return data;
          },
        ),
        error,
      );
    }
  }

  Future<Either<Failure, T>> uploadFiles<T>({
    required T Function(dynamic data) fromData,
    required String endPoint,
    required List<File> files,
    bool? showLogs,
    Either<Failure, T> Function(
            int statusCode, Map<String, dynamic> responseBody)?
        failureHandler,
    Map<String, String>? header,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      FormData formData = FormData();

      for (var file in files) {
        formData.files.add(MapEntry(
          "files",
          await MultipartFile.fromFile(file.path,
              filename: file.uri.pathSegments.last),
        ));
      }

      if (additionalData != null) {
        formData.fields.addAll(additionalData.entries
            .map((e) => MapEntry(e.key, e.value.toString())));
      }

      final response = await _dio.post(
        endPoint,
        data: formData,
        options: Options(headers: header),
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        return Right(fromData(response.data));
      } else {
        return Left(
          Failure.withData(
            statusCode: response.statusCode ?? -1,
            request: RequestData(
                method: RequestMethod.post,
                uri: Uri.parse(endPoint),
                fromData: (data) {}),
            error: response.data,
          ),
        );
      }
    } catch (error) {
      PrettyDioLogger(
        error: true,
        request: true,
        requestHeader: true,
        responseBody: true,
      );
      return Left(
        Failure.withData(
          statusCode: -1,
          request: RequestData(
              method: RequestMethod.post,
              uri: Uri.parse(endPoint),
              fromData: (data) {}),
          error: error,
        ),
      );
    }
  }

  Future<Either<Failure, Stream<List<int>>>> getResponseStream({
    required String endPoint,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        endPoint,
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
        ),
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        return Right(response.data.stream);
      } else {
        return Left(Failure.withData(
          statusCode: response.statusCode ?? -1,
          request: RequestData(
              method: RequestMethod.get,
              uri: Uri.parse(endPoint),
              fromData: (data) {}),
          error: response.data,
        ));
      }
    } catch (error) {
      PrettyDioLogger(
        error: true,
        request: true,
        requestHeader: true,
        responseBody: true,
      );
      return Left(
        Failure.withData(
          statusCode: -1,
          request: RequestData(
            method: RequestMethod.get,
            uri: Uri.parse(endPoint),
            fromData: (data) {},
          ),
          error: error,
        ),
      );
    }
  }

  Either<Failure, T> _handleFailure<T>(
      int statusCode, RequestData<T> request, dynamic error) {
    final failure = Failure.withData(
      statusCode: statusCode,
      request: request,
      error: error,
    );
    return Left(failure);
  }

  Either<Failure, T> _handleError<T>(RequestData<T> request, dynamic error) {
    if (error is DioException) {
      return _handleFailure(
        error.response?.statusCode ?? -1,
        request,
        error.message,
      );
    } else {
      return _handleFailure(
        -1,
        request,
        error.toString(),
      );
    }
  }
}
