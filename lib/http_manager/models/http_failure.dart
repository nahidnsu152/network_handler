// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../network_handler.dart';
import 'request_options.dart';

class HttpFailure extends Equatable {
  final String error;
  final bool _enableDialogue;
  final int statusCode;

  const HttpFailure(
      {required this.error, bool enableDialogue = true, this.statusCode = -1})
      : _enableDialogue = enableDialogue;

  HttpFailure copyWith({String? tag, String? error, int? statusCode}) {
    return HttpFailure(
        error: error ?? this.error, statusCode: statusCode ?? this.statusCode);
  }

  factory HttpFailure.withData(
      {required int statusCode,
      required RequestData request,
      bool enableDialogue = true,
      required dynamic error}) {
    final Map<String, dynamic> _errorMap = {
      'url': request.uri.path,
      'method': request.method.name.toUpperCase(),
      if (request.headers != null) 'header': request.headers,
      if (request.body != null) 'body': request.body,
      'error': error,
      if (statusCode > 0) 'status_code': statusCode
    };
    final encoder = JsonEncoder.withIndent(' ' * 2);
    // return encoder.convert(toJson());
    final String _errorStr = encoder.convert(_errorMap);
    return HttpFailure(
        error: _errorStr,
        enableDialogue: enableDialogue,
        statusCode: statusCode);
  }
  factory HttpFailure.none() => const HttpFailure(error: '');

  @override
  String toString() => 'CleanFailure(error: $error)';

  showDialogue(BuildContext context) {
    if (_enableDialogue) {
      HttpFailureDialogue.show(context, failure: this);
    } else {
      Logger.e(this);
    }
  }

  @override
  List<Object?> get props => [error];
}
