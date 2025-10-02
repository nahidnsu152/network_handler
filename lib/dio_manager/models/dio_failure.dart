
part of '../dio_manager.dart';

class DioFailure extends Equatable {
  final String error;
  final bool _enableDialogue;
  final int statusCode;
  final String errorMessage;
  final bool isRetryable;

  const DioFailure({
    required this.error,
    bool enableDialogue = true,
    this.statusCode = -1,
    this.errorMessage = 'An unknown error occurred',
    this.isRetryable = true,
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
    bool isRetryable = true,
  }) {
    final Map<String, dynamic> errorMap = {
      'url': request.uri.path,
      'method': request.method.name.toUpperCase(),
      if (request.headers != null) 'header': request.headers,
      if (request.body != null) 'body': request.body,
      'error': error,
      if (statusCode > 0) 'status_code': statusCode,
    };
    final encoder = JsonEncoder.withIndent('  ');
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
      if (error is DioException) {
        final data = error.response?.data;
        if (data is Map<String, dynamic>) {
          if (data['message'] != null) return data['message'];
          if (data['data'] is Map && data['data']['message'] != null) {
            return data['data']['message'];
          }
        }
      } else if (error is Map<String, dynamic>) {
        if (error['message'] != null) return error['message'];
        if (error['data'] is Map && error['data']['message'] != null) {
          return error['data']['message'];
        }
        if (error['error'] is Map && error['error']['message'] != null) {
          return error['error']['message'];
        }
      } else if (error is String) {
        final Map<String, dynamic> parsed = jsonDecode(error);
        if (parsed['message'] != null) return parsed['message'];
      }
    } catch (_) {}

    return 'An unknown error occurred';
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
    }
  }

  @override
  List<Object?> get props => [error, statusCode, errorMessage, isRetryable];
}