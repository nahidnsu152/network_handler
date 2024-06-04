import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../common/models/failure.dart';
import '../../common/models/request_options.dart';

export 'package:fpdart/fpdart.dart' hide State;

part 'src/api_service.dart';

final Dio dio = Dio();
