part of '../dio_manager.dart';

class DioFailure extends Equatable {
  final String error;
  final bool _enableDialogue;
  final int statusCode;

  const DioFailure(
      {required this.error, bool enableDialogue = true, this.statusCode = -1})
      : _enableDialogue = enableDialogue;

  DioFailure copyWith({String? tag, String? error, int? statusCode}) {
    return DioFailure(
        error: error ?? this.error, statusCode: statusCode ?? this.statusCode);
  }

  factory DioFailure.withData(
      {required int statusCode,
      required RequestData request,
      bool enableDialogue = true,
      required dynamic error}) {
    final Map<String, dynamic> errorMap = {
      'url': request.uri.path,
      'method': request.method.name.toUpperCase(),
      if (request.headers != null) 'header': request.headers,
      if (request.body != null) 'body': request.body,
      'error': error,
      if (statusCode > 0) 'status_code': statusCode
    };
    final encoder = JsonEncoder.withIndent(' ' * 2);
    // return encoder.convert(toJson());
    final String errorStr = encoder.convert(errorMap);
    return DioFailure(
        error: errorStr,
        enableDialogue: enableDialogue,
        statusCode: statusCode);
  }
  factory DioFailure.none() => const DioFailure(error: '');

  @override
  String toString() => 'CleanFailure(error: $error)';

  showDialogue(BuildContext context) {
    if (_enableDialogue) {
    } else {
      PrettyDioLogger(
        error: true,
        requestBody: true,
        responseBody: true,
        logPrint: (object) {},
      );
    }
  }

  @override
  List<Object?> get props => [error];
}
