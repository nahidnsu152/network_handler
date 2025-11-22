import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

import '../dio_manager.dart';

class CacheManager {
  static CacheManager? _instance;
  late final DioCacheInterceptor _cacheInterceptor;
  late final CacheOptions _defaultOptions;

  CacheManager._internal({
    required DioCacheInterceptor cacheInterceptor,
    required CacheOptions defaultOptions,
  }) : _cacheInterceptor = cacheInterceptor,
       _defaultOptions = defaultOptions;

  static Future<CacheManager> getInstance() async {
    if (_instance == null) {
      final store = await HiveCacheStore.create(
        useTempDir: true,
      ); // Or false for documents dir
      final defaultOptions = CacheOptions(
        store: store,
        policy: CachePolicy.request,
        maxStale: const Duration(days: 7),
        priority: CachePriority.normal,
        hitCacheOnErrorCodes: [401, 403, 500, -1],
        hitCacheOnNetworkFailure: true,
      );
      final cacheInterceptor = DioCacheInterceptor(options: defaultOptions);
      _instance = CacheManager._internal(
        cacheInterceptor: cacheInterceptor,
        defaultOptions: defaultOptions,
      );
    }
    return _instance!;
  }

  /// Attach the cache interceptor to Dio
  void attachToDio(DioService dio) {
    dio.addInterceptor(_cacheInterceptor);
  }

  /// Returns CacheOptions based on duration, expiry, or seconds
  CacheOptions createCacheOptions({
    Duration? fixedDuration,
    DateTime? expireAt,
    int? secondsFromNow,
    CachePolicy policy = CachePolicy.request,
  }) {
    Duration duration;

    if (fixedDuration != null) {
      duration = fixedDuration;
    } else if (secondsFromNow != null) {
      duration = Duration(seconds: secondsFromNow);
    } else if (expireAt != null) {
      final now = DateTime.now();
      duration = expireAt.isAfter(now)
          ? expireAt.difference(now)
          : Duration.zero;
    } else {
      duration = Duration(hours: 1); // default fallback
    }

    return CacheOptions(
      store: _defaultOptions.store, // Reuse the initialized store
      policy: policy,
      maxStale: duration,
      priority: CachePriority.normal,
      hitCacheOnErrorCodes: _defaultOptions.hitCacheOnErrorCodes,
      hitCacheOnNetworkFailure: _defaultOptions.hitCacheOnNetworkFailure,
      allowPostMethod: _defaultOptions.allowPostMethod,
      cipher: _defaultOptions.cipher,
      keyBuilder: _defaultOptions.keyBuilder,
    );
  }

  /// Shortcut: Cache until midnight
  CacheOptions cacheUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return createCacheOptions(expireAt: midnight);
  }

  /// Shortcut: Cache for a specific number of seconds
  CacheOptions cacheForSeconds(int seconds) {
    return createCacheOptions(secondsFromNow: seconds);
  }

  /// Shortcut: Default options (1 hour)
  CacheOptions get defaultOptions => _defaultOptions;
}

//! Working
// import 'package:dio/dio.dart';
// import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

// import 'hive_cache_store.dart';

// class CacheManager extends Interceptor {
//   static CacheManager? _instance;
//   late final DioCacheInterceptor _cacheInterceptor;
//   late final CacheOptions _defaultOptions;

//   CacheManager._({
//     required DioCacheInterceptor cacheInterceptor,
//     required CacheOptions defaultOptions,
//   }) : _cacheInterceptor = cacheInterceptor,
//        _defaultOptions = defaultOptions;

//   /// ✅ Singleton initialization (lazy, async-safe)
//   static Future<CacheManager> getInstance() async {
//     if (_instance != null) return _instance!;

//     final store = await HiveCacheStore.create(useTempDir: true);

//     final defaultOptions = CacheOptions(
//       store: store,
//       policy: CachePolicy.request,
//       maxStale: const Duration(hours: 1),
//       priority: CachePriority.normal,
//       allowPostMethod: true,
//     );

//     final cacheInterceptor = DioCacheInterceptor(options: defaultOptions);

//     _instance = CacheManager._(
//       cacheInterceptor: cacheInterceptor,
//       defaultOptions: defaultOptions,
//     );

//     return _instance!;
//   }

//   /// ✅ Allow adding CacheManager directly as an interceptor
//   @override
//   void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
//     _cacheInterceptor.onRequest(options, handler);
//   }

//   @override
//   void onResponse(Response response, ResponseInterceptorHandler handler) {
//     _cacheInterceptor.onResponse(response, handler);
//   }

//   @override
//   void onError(DioException err, ErrorInterceptorHandler handler) {
//     _cacheInterceptor.onError(err, handler);
//   }

//   /// Create custom cache options
//   CacheOptions createCacheOptions({
//     Duration? fixedDuration,
//     DateTime? expireAt,
//     int? secondsFromNow,
//     CachePolicy policy = CachePolicy.request,
//   }) {
//     Duration duration;

//     if (fixedDuration != null) {
//       duration = fixedDuration;
//     } else if (secondsFromNow != null) {
//       duration = Duration(seconds: secondsFromNow);
//     } else if (expireAt != null) {
//       final now = DateTime.now();
//       duration = expireAt.isAfter(now)
//           ? expireAt.difference(now)
//           : Duration.zero;
//     } else {
//       duration = const Duration(hours: 1);
//     }

//     return CacheOptions(
//       store: _defaultOptions.store,
//       policy: policy,
//       maxStale: duration,
//       priority: CachePriority.normal,
//     );
//   }

//   /// Cache until midnight
//   CacheOptions cacheUntilMidnight() {
//     final now = DateTime.now();
//     final midnight = DateTime(now.year, now.month, now.day + 1);
//     return createCacheOptions(expireAt: midnight);
//   }

//   /// Cache for seconds
//   CacheOptions cacheForSeconds(int seconds) {
//     return createCacheOptions(secondsFromNow: seconds);
//   }

//   /// Default cache options (1 hour)
//   CacheOptions get defaultOptions => _defaultOptions;
// }
