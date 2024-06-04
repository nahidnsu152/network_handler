// import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:pretty_dio_logger/pretty_dio_logger.dart';

// class DioFactory {
//   late String _token = '';
//   late String _baseUrl;

//   void setToken(String token) {
//     _token = token;
//   }

//   void setBaseUrl(String baseUrl) {
//     _baseUrl = baseUrl;
//   }

//   Future<Dio> getDio() async {
//     Dio dio = Dio();

//     Map<String, String> headers = {
//       "content-type": "application/json",
//       "accept": "application/json",
//       if (_token.isNotEmpty) "authorization": "Bearer $_token",
//       "language": "en"
//     };

//     dio.options = BaseOptions(
//       baseUrl: _baseUrl,
//       headers: headers,
//       receiveTimeout: const Duration(milliseconds: 30000),
//       sendTimeout: const Duration(milliseconds: 30000),
//     );

//     if (!kReleaseMode) {
//       dio.interceptors.add(PrettyDioLogger(
//         requestHeader: true,
//         requestBody: true,
//         responseHeader: true,
//       ));
//     }

//     return dio;
//   }
// }

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class DioFactory {
  late String _token = '';
  late String _baseUrl;
  Map<String, String>? _additionalHeaders;

  void setToken(String token) {
    _token = token;
  }

  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
  }

  void setAdditionalHeaders(Map<String, String>? headers) {
    _additionalHeaders = headers;
  }

  Future<Dio> getDio() async {
    Dio dio = Dio();

    Map<String, String> headers = {
      "content-type": "application/json",
      "accept": "application/json",
      if (_token.isNotEmpty) "authorization": "Bearer $_token",
      "language": "en",
      if (_additionalHeaders != null) ..._additionalHeaders!,
    };

    dio.options = BaseOptions(
      baseUrl: _baseUrl,
      headers: headers,
      receiveTimeout: const Duration(milliseconds: 30000),
      sendTimeout: const Duration(milliseconds: 30000),
    );

    if (!kReleaseMode) {
      dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
      ));
    }

    return dio;
  }
}
