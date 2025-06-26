part of '../dio_manager.dart';

class DioFailure extends Equatable {
  final String error;
  final bool _enableDialogue;
  final int statusCode;
  final String errorMessage;
  final bool isRetryable; // New property

  const DioFailure({
    required this.error,
    bool enableDialogue = true,
    this.statusCode = -1,
    this.errorMessage = 'An unknown error occurred',
    this.isRetryable = true, // Default to true
  }) : _enableDialogue = enableDialogue;

  DioFailure copyWith({
    String? error,
    int? statusCode,
    String? errorMessage,
    bool? isRetryable,
  }) {
    return DioFailure(
      error: error ?? this.error,
      statusCode: statusCode ?? this.statusCode,
      enableDialogue: _enableDialogue,
      errorMessage: errorMessage ?? this.errorMessage,
      isRetryable: isRetryable ?? this.isRetryable,
    );
  }

  factory DioFailure.withData({
    required int statusCode,
    required RequestData request,
    bool enableDialogue = true,
    required dynamic error,
    bool isRetryable = true, // New parameter
  }) {
    final Map<String, dynamic> errorMap = {
      'url': request.uri.path,
      'method': request.method.name.toUpperCase(),
      if (request.headers != null) 'header': request.headers,
      if (request.body != null) 'body': request.body,
      'error': error,
      if (statusCode > 0) 'status_code': statusCode,
    };
    final encoder = JsonEncoder.withIndent(' ' * 2);
    final String errorStr = encoder.convert(errorMap);
    final String errorMessage = _extractErrorMessage(error);

    return DioFailure(
      error: errorStr,
      enableDialogue: enableDialogue,
      statusCode: statusCode,
      errorMessage: errorMessage,
      isRetryable: isRetryable,
    );
  }

  factory DioFailure.none() => const DioFailure(error: '');

  static String _extractErrorMessage(dynamic error) {
    try {
      final Map<String, dynamic> errorMap = error is String
          ? jsonDecode(error)
          : error;
      return errorMap['message'] ?? 'An unknown error occurred';
    } catch (e) {
      return 'An unknown error occurred';
    }
  }

  @override
  String toString() =>
      'DioFailure(error: $error, errorMessage: $errorMessage, isRetryable: $isRetryable)';

  void showDialogue(BuildContext context) {
    if (_enableDialogue) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
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
  List<Object?> get props => [error, statusCode, errorMessage, isRetryable];
}
