import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';

export 'cache/cache.dart';

part 'enums/enums.dart';
part 'models/dio_failure.dart';
part 'models/request_data.dart';
part 'src/dio_service.dart';
