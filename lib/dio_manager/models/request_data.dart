part of '../dio_manager.dart';

class RequestData<T> {
  final RequestMethod method;
  final Uri uri;
  final bool showLogs;
  final T Function(dynamic data)? fromData;
  final Map<String, String>? headers;
  final dynamic body;
  final Either<DioFailure, T> Function(
    int statusCode,
    Map<String, dynamic> responseBody,
  )?
  failureHandler;

  RequestData({
    required this.method,
    required this.uri,
    this.showLogs = false,
    this.fromData,
    this.headers,
    this.body,
    this.failureHandler,
  });
}


