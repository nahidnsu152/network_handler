import 'package:dio/dio.dart';
import 'package:talker/talker.dart';

class AuthInterceptor extends Interceptor {
  final String? token;
  final List<int> logoutStatusCodes;
  final Talker _talker;
  final void Function()? errorToast;
  final void Function()? onLogout;

  DateTime? _lastToastTime;
  bool _isLoggingOut = false;

  static const _debounceDuration = Duration(seconds: 5);

  AuthInterceptor({
    this.token,
    this.onLogout,
    this.logoutStatusCodes = const [401],
    Talker? talker,
    this.errorToast,
  }) : _talker = talker ?? Talker();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (token != null && token!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    } else if (options.headers['requiresAuth'] == true) {
      _talker.error(
        'Auth required but no token available. Cancelling request.',
      );
      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'No auth token available',
          type: DioExceptionType.cancel,
        ),
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (logoutStatusCodes.contains(response.statusCode)) {
      _handleUnauthorized(statusCode: response.statusCode, handler: handler);
    } else {
      handler.next(response);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (logoutStatusCodes.contains(err.response?.statusCode)) {
      _handleUnauthorized(
        statusCode: err.response?.statusCode,
        handler: handler,
      );
    } else {
      handler.next(err);
    }
  }

  void _handleUnauthorized({int? statusCode, required dynamic handler}) {
    if (_isLoggingOut) return;

    final now = DateTime.now();
    if (_lastToastTime == null ||
        now.difference(_lastToastTime!) > _debounceDuration) {
      _talker.warning('[AuthInterceptor] Logout triggered (code: $statusCode)');
      // showErrorToast(AppStrings.sessionExpired);
      errorToast;

      _lastToastTime = now;
      _isLoggingOut = true;

      Future.delayed(const Duration(milliseconds: 500), () {
        onLogout?.call(); // Trigger your logout callback
        _isLoggingOut = false;
      });
    }

    handler.next(
      DioException(
        requestOptions: RequestOptions(path: ''),
        error: 'Unauthorized',
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: statusCode,
        ),
      ),
    );
  }
}
