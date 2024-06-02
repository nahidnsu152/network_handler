// ignore_for_file: constant_identifier_names

import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'entry.dart'
    if (dart.library.io) 'impl/entry.dart'
    if (dart.library.html) 'impl/entry.html.dart';

/// Created by Taohid on 01, March, 2020
/// Email: taohid32@gmail.com
abstract class ApiManager {
  factory ApiManager({BaseOptions? options}) => createApiManager(options);

  /// http success code list to check
  /// if request response success or not
  static const HTTP_SUCCESS_CODE = [
    200,
    201,
    202,
    203,
    204,
    205,
    206,
    207,
    208,
    226,
  ];

  BaseOptions get options;

  void addInterceptor(Interceptor interceptor);

  void enableAuthTokenCheck(AuthTokenListener authTokenListener);

  void disableSSLCheck();

  void enableLogging({
    bool request = false,
    bool requestHeader = false,
    bool requestBody = false,
    bool responseHeader = false,
    bool responseBody = false,
    bool error = false,
    Function(Object object) logPrint,
  });

  Future<MultipartFile> getMultipartFromFile(String filePath);

  Future<MultipartFile> getMultipartFromBytes(Uint8List bytes, String fileName);

  Future<Response<dynamic>?> download(
    String urlPath,
    savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    data,
    Options? options,
  });

  Future<ApiResponse<T>> request<T>({
    required String route,
    required RequestType requestType,
    Map<String, dynamic>? requestParams,
    dynamic requestBody,
    CancelToken? cancelToken,
    bool isAuthRequired = false,
    ResponseBodySerializer? responseBodySerializer,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });
}

/// every request will wrap its response with this
/// contains api status, body data, and error message
class ApiResponse<T> {
  ApiStatus status;
  T? data;
  dynamic jsonMap;
  String? message;
  int? statusCode;

  ApiResponse.loading() : status = ApiStatus.LOADING;

  ApiResponse.completed({
    this.data,
    this.jsonMap,
    this.statusCode,
    this.message,
  }) : status = ApiStatus.SUCCESS;

  ApiResponse.error({
    this.message,
    this.statusCode,
    this.data,
  }) : status = ApiStatus.ERROR;

  @override
  String toString() {
    return "Status : $status \n Message : $message \n Data : $data";
  }
}

/// error body of http response
class ErrorBody {
  String? message;

  ErrorBody({this.message});

  factory ErrorBody.fromJson(Map<String, dynamic> jsonMap) {
    return ErrorBody(message: jsonMap['message']);
  }
}

/// enable parsing http response using this [request]
typedef ResponseBodySerializer<M> = M Function(dynamic jsonMap);

/// enable auth token checker by pass this to [enableAuthTokenCheck]
typedef AuthTokenListener = Future<String> Function();

/// Http request type
enum RequestType { GET, POST, PUT, DELETE }

/// Api status state
enum ApiStatus { LOADING, SUCCESS, ERROR }
