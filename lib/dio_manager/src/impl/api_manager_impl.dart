import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:network_handler/dio_manager/api_manager.dart';
import 'package:network_handler/dio_manager/src/connectivity_manager.dart';
import 'package:network_handler/dio_manager/src/impl/auth_interceptor.dart';

import '../../../http_manager/network_handler.dart';

class ApiManagerImpl implements ApiManager {
  /// http client
  late Dio _dio;

  /// constructor of this class
  ApiManagerImpl({BaseOptions? baseOptions}) {
    _dio = Dio(baseOptions ?? BaseOptions());
    _dio.options.connectTimeout = const Duration(milliseconds: 10000);
    _dio.options.receiveTimeout = const Duration(milliseconds: 30000);
  }

  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  @override
  void disableSSLCheck() {
    if (_dio.httpClientAdapter is IOHttpClientAdapter) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        return HttpClient()
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
      };
    }
  }

  @override
  BaseOptions get options {
    return _dio.options;
  }

  @override
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  @override
  void enableAuthTokenCheck(authTokenListener) {
    _dio.interceptors.add(
      AuthInterceptor(authTokenListener),
    );
  }

  @override
  void enableLogging({
    bool request = false,
    bool requestHeader = false,
    bool requestBody = false,
    bool responseHeader = false,
    bool responseBody = false,
    bool error = false,
    Function(Object object) logPrint = print,
  }) {
    _dio.interceptors.add(
      LogInterceptor(
        request: request,
        requestHeader: requestHeader,
        requestBody: requestBody,
        responseHeader: responseHeader,
        responseBody: responseBody,
        error: error,
        logPrint: logPrint,
      ),
    );
  }

  @override
  Future<MultipartFile> getMultipartFromFile(String filePath) async {
    String fileName = filePath.split('/').last;
    return await MultipartFile.fromFile(filePath, filename: fileName);
  }

  @override
  Future<MultipartFile> getMultipartFromBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    return MultipartFile.fromBytes(bytes, filename: fileName);
  }

  @override
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
  }) async {
    try {
      return await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
        data: data,
        options: options,
      );
    } on DioException catch (error) {
      return error.response;
    }
  }

  @override
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
  }) async {
    /// check internet connectivity & return an internet error message
    if (!await ConnectivityManager.isConnected()) {
      return _internetError<T>();
    }

    options ??= Options();

    if (options.headers != null) {
      options.headers!['isauthrequired'] = isAuthRequired;
    } else {
      options.headers = {'isauthrequired': isAuthRequired};
    }

    try {
      switch (requestType) {
        /// http get request method
        case RequestType.GET:
          final response = await _dio.get(
            route,
            queryParameters: requestParams,
            cancelToken: cancelToken,
            options: options,
            onReceiveProgress: onReceiveProgress,
          );
          return _returnResponse<T>(
            response,
            responseBodySerializer,
          );

        /// http post request method
        case RequestType.POST:
          final response = await _dio.post(
            route,
            data: requestBody,
            queryParameters: requestParams,
            cancelToken: cancelToken,
            options: options,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          return _returnResponse<T>(
            response,
            responseBodySerializer,
          );

        /// http put request method
        case RequestType.PUT:
          final response = await _dio.put(
            route,
            data: requestBody,
            queryParameters: requestParams,
            cancelToken: cancelToken,
            options: options,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          return _returnResponse<T>(
            response,
            responseBodySerializer,
          );

        /// http delete request method
        case RequestType.DELETE:
          final response = await _dio.delete(
            route,
            data: requestBody,
            queryParameters: requestParams,
            cancelToken: cancelToken,
            options: options,
          );
          return _returnResponse<T>(
            response,
            responseBodySerializer,
          );

        /// throw an exception when no http request method is passed
        default:
          throw Exception('No request type passed');
      }
    } on DioException catch (error) {
      Logger.e(error.toString());
      return ApiResponse.error(
        message: error.response == null
            ? error.message
            : _getErrorResponseMessage(error),
        statusCode: error.response?.statusCode ?? 400,
      );
    }
  }

  String _getErrorResponseMessage(DioException dioError) {
    try {
      Map<String, dynamic> errorResponse = jsonDecode(
        dioError.response.toString(),
      );
      if (errorResponse.containsKey('message')) {
        return errorResponse['message'].toString();
      } else if (errorResponse.containsKey('error')) {
        return errorResponse['error'].toString();
      } else {
        return errorResponse.toString();
      }
    } catch (error) {
      return dioError.response.toString();
    }
  }

  /// check the response success status
  /// then wrap the response with api call
  /// return {ApiResponse}
  ApiResponse<T> _returnResponse<T>(
    Response response,
    ResponseBodySerializer? responseBodySerializer,
  ) {
    if (ApiManager.HTTP_SUCCESS_CODE.contains(response.statusCode)) {
      if (responseBodySerializer == null) {
        return ApiResponse.completed(
          jsonMap: response.data,
          statusCode: response.statusCode,
        );
      } else {
        try {
          /// if responseBodySerializer return an object type of ApiResponse
          /// then simply return the same as request response
          /// because sometimes request success status check may be handle by user
          var serializerResponse = responseBodySerializer(response.data);
          if (serializerResponse is ApiResponse) {
            return serializerResponse as ApiResponse<T>;
          } else {
            return ApiResponse.completed(
              data: serializerResponse,
              statusCode: response.statusCode,
            );
          }
        } catch (e) {
          Logger.e(e);
          return ApiResponse.error(
            message: "Data Serialization Error: $e",
            statusCode: response.statusCode,
          );
        }
      }
    } else {
      Logger.e('Dio Error: States Code ${response.statusCode}');
      return ApiResponse.error(
        message: response.statusMessage,
        statusCode: response.statusCode,
      );
    }
  }

  ApiResponse<T> _internetError<T>() {
    return ApiResponse.error(
      message: "Internet not connected",
      statusCode: 400,
    );
  }
}
