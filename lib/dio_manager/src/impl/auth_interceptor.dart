import 'package:dio/dio.dart';

import '../api_manager.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._authTokenListener);

  final AuthTokenListener _authTokenListener;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.headers.containsKey("isauthrequired") == true &&
        options.headers["isauthrequired"] == true) {
      options.headers.remove("isauthrequired");
      String token = await _authTokenListener();
      options.headers.addAll({
        "Authorization": token,
      });
      handler.next(options);
    } else {
      handler.next(options);
    }
  }
}
