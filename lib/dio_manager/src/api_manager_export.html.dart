import 'package:dio/dio.dart';

export 'package:dio/src/adapter.dart' show ResponseBody;
export 'package:dio/src/cancel_token.dart';
export 'package:dio/src/dio_mixin.dart';
export 'package:dio/src/form_data.dart';
export 'package:dio/src/multipart_file.dart';
export 'package:dio/src/options.dart';
export 'package:dio/src/response.dart';

export 'api_manager.dart';
export 'api_manager_export.io.dart';
export 'connectivity_manager.dart';

final Dio dio = Dio(
  BaseOptions()
);
