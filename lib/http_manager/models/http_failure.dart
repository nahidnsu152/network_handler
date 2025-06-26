// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'request_options.dart';

class HttpFailure extends Equatable {
  final String error;
  final bool _enableDialogue;
  final int statusCode;
  final String errorMessage;

  const HttpFailure({
    required this.error,
    bool enableDialogue = true,
    this.statusCode = -1,
    this.errorMessage = 'An unknown error occurred',
  }) : _enableDialogue = enableDialogue;

  HttpFailure copyWith({String? error, int? statusCode, String? errorMessage}) {
    return HttpFailure(
      error: error ?? this.error,
      statusCode: statusCode ?? this.statusCode,
      enableDialogue: _enableDialogue,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory HttpFailure.withData({
    required int statusCode,
    required RequestData request,
    bool enableDialogue = true,
    required dynamic error,
  }) {
    final Map<String, dynamic> _errorMap = {
      'url': request.uri.path,
      'method': request.method.name.toUpperCase(),
      if (request.headers != null) 'header': request.headers,
      if (request.body != null) 'body': request.body,
      'error': error,
      if (statusCode > 0) 'status_code': statusCode,
    };
    final encoder = JsonEncoder.withIndent(' ' * 2);
    final String _errorStr = encoder.convert(_errorMap);
    final String _errorMessage = _extractErrorMessage(error);

    return HttpFailure(
      error: _errorStr,
      enableDialogue: enableDialogue,
      statusCode: statusCode,
      errorMessage: _errorMessage,
    );
  }

  factory HttpFailure.none() => const HttpFailure(error: '');

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
      'HttpFailure(error: $error, errorMessage: $errorMessage)';

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
      // Logger.e(this);
    }
  }

  @override
  List<Object?> get props => [error, errorMessage];
}
