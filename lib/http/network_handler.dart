import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import 'models/failure.dart';
import 'models/request_options.dart';
import 'src/network_log.dart';

export 'package:flutter_easylogger/flutter_logger.dart';
export 'package:fpdart/fpdart.dart' hide State;

export 'clean_failure_dialogue/failure_dialogue.dart';
export 'models/failure.dart';

part 'src/network_handler_logic.dart';
