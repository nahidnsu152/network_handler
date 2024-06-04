import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../failure_dialogue/failure_dialogue.dart';
import 'request_options.dart';

class Failure extends Equatable {
  final String error;
  final bool _enableDialogue;
  final int statusCode;

  const Failure(
      {required this.error, bool enableDialogue = true, this.statusCode = -1})
      : _enableDialogue = enableDialogue;

  Failure copyWith({String? tag, String? error, int? statusCode}) {
    return Failure(
        error: error ?? this.error, statusCode: statusCode ?? this.statusCode);
  }

  factory Failure.withData(
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
    return Failure(
        error: errorStr,
        enableDialogue: enableDialogue,
        statusCode: statusCode);
  }
  factory Failure.none() => const Failure(error: '');

  @override
  String toString() => 'CleanFailure(error: $error)';

  showDialogue(BuildContext context) {
    if (_enableDialogue) {
      FailureDialogue.show(context, failure: this);
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
