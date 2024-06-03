// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../network_handler.dart';
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
    return Failure(
        error: _errorStr,
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
      Logger.e(this);
    }
  }

  @override
  List<Object?> get props => [error];
}

