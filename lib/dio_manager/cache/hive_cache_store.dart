import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// A store saving responses using hive.
///
class HiveCacheStore extends CacheStore {
  // Cache box name
  final String hiveBoxName;
  // Optional cipher to use directly with Hive
  final HiveCipher? encryptionCipher;

  /// The Hive instance to use.
  final HiveInterface hive;

  LazyBox<CacheResponse>? _box;

  /// Initialize cache store by giving Hive a home directory.
  /// [directory] is the subdirectory under the app's documents dir (if null, uses default).
  /// For temp storage, pass a temp path explicitly.
  /// This constructor is now async to handle initialization properly.
  HiveCacheStore._({
    required this.hiveBoxName,
    this.encryptionCipher,
    HiveInterface? hiveInterface,
  }) : hive = hiveInterface ?? Hive;

  static Future<HiveCacheStore> create({
    String hiveBoxName = 'dio_cache',
    HiveCipher? encryptionCipher,
    HiveInterface? hiveInterface,
    bool useTempDir = false, // Option to use temp dir instead of documents
  }) async {
    final instance = HiveCacheStore._(
      hiveBoxName: hiveBoxName,
      encryptionCipher: encryptionCipher,
      hiveInterface: hiveInterface,
    );

    // Get writable path
    String path;
    if (useTempDir) {
      final tempDir = await getTemporaryDirectory();
      path = tempDir.path;
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      path = docsDir.path;
    }

    // Init Hive with the path (use initFlutter for documents, init for custom/temp)
    if (!useTempDir) {
      await Hive.initFlutter(path); // For documents dir
    } else {
      Hive.init(path); // For temp dir (sync, as it's not Flutter-specific)
    }

    if (!Hive.isAdapterRegistered(_CacheResponseAdapter._typeId)) {
      Hive.registerAdapter(_CacheResponseAdapter());
    }
    if (!Hive.isAdapterRegistered(_CacheControlAdapter._typeId)) {
      Hive.registerAdapter(_CacheControlAdapter());
    }
    if (!Hive.isAdapterRegistered(_CachePriorityAdapter._typeId)) {
      Hive.registerAdapter(_CachePriorityAdapter());
    }

    await instance.clean(staleOnly: true);
    return instance;
  }

  @override
  Future<void> clean({
    CachePriority priorityOrBelow = CachePriority.high,
    bool staleOnly = false,
  }) async {
    final box = await _openBox();

    final keys = <String>[];

    for (var i = 0; i < box.keys.length; i++) {
      final resp = await box.getAt(i);

      if (resp != null) {
        var shouldRemove = resp.priority.index <= priorityOrBelow.index;
        shouldRemove &= (staleOnly && resp.isStaled()) || !staleOnly;

        if (shouldRemove) {
          keys.add(resp.key);
        }
      }
    }

    return box.deleteAll(keys);
  }

  @override
  Future<void> close() async {
    final checkedBox = _box;
    if (checkedBox != null && checkedBox.isOpen) {
      _box = null;
      return checkedBox.close();
    }
  }

  @override
  Future<void> delete(String key, {bool staleOnly = false}) async {
    final box = await _openBox();
    final resp = await box.get(key);
    if (resp == null) return Future.value();

    if (staleOnly && !resp.isStaled()) {
      return Future.value();
    }

    await box.delete(key);
  }

  @override
  Future<void> deleteFromPath(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) async {
    final responses = await getFromPath(pathPattern, queryParams: queryParams);

    final box = await _openBox();

    for (final response in responses) {
      await box.delete(response.key);
    }
  }

  @override
  Future<bool> exists(String key) async {
    final box = await _openBox();
    return box.containsKey(key);
  }

  @override
  Future<CacheResponse?> get(String key) async {
    final box = await _openBox();
    return box.get(key);
  }

  @override
  Future<List<CacheResponse>> getFromPath(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) async {
    final responses = <CacheResponse>[];

    final box = await _openBox();

    for (var i = 0; i < box.keys.length; i++) {
      final resp = await box.getAt(i);

      if (resp != null) {
        if (pathExists(resp.url, pathPattern, queryParams: queryParams)) {
          responses.add(resp);
        }
      }
    }

    return responses;
  }

  @override
  Future<void> set(CacheResponse response) async {
    final box = await _openBox();
    return box.put(response.key, response);
  }

  Future<LazyBox<CacheResponse>> _openBox() async {
    _box ??= await hive.openLazyBox<CacheResponse>(
      hiveBoxName,
      encryptionCipher: encryptionCipher,
    );

    return Future.value(_box);
  }
}

class _CacheResponseAdapter extends TypeAdapter<CacheResponse> {
  static const int _typeId = 93;

  @override
  final int typeId = _typeId;

  @override
  CacheResponse read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CacheResponse(
      cacheControl: fields[0] as CacheControl? ?? CacheControl(),
      content: (fields[1] as List?)?.cast<int>(),
      date: fields[2] as DateTime?,
      eTag: fields[3] as String?,
      expires: fields[4] as DateTime?,
      headers: (fields[5] as List?)?.cast<int>(),
      key: fields[6] as String,
      lastModified: fields[7] as String?,
      maxStale: fields[8] as DateTime?,
      priority: fields[9] as CachePriority,
      responseDate: fields[10] as DateTime,
      url: fields[11] as String,
      requestDate: fields[12] as DateTime,
      statusCode: fields[13] as int? ?? 304,
    );
  }

  @override
  void write(BinaryWriter writer, CacheResponse obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.cacheControl)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.eTag)
      ..writeByte(4)
      ..write(obj.expires)
      ..writeByte(5)
      ..write(obj.headers)
      ..writeByte(6)
      ..write(obj.key)
      ..writeByte(7)
      ..write(obj.lastModified)
      ..writeByte(8)
      ..write(obj.maxStale)
      ..writeByte(9)
      ..write(obj.priority)
      ..writeByte(10)
      ..write(obj.responseDate)
      ..writeByte(11)
      ..write(obj.url)
      ..writeByte(12)
      ..write(obj.requestDate)
      ..writeByte(13)
      ..write(obj.statusCode);
  }
}

class _CacheControlAdapter extends TypeAdapter<CacheControl> {
  static const int _typeId = 94;

  @override
  final int typeId = _typeId;

  @override
  CacheControl read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CacheControl(
      maxAge: fields[0] as int? ?? -1,
      privacy: fields[1] as String?,
      noCache: fields[2] as bool? ?? false,
      noStore: fields[3] as bool? ?? false,
      other: (fields[4] as List).cast<String>(),
      maxStale: fields[5] as int? ?? -1,
      minFresh: fields[6] as int? ?? -1,
      mustRevalidate: fields[7] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, CacheControl obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.maxAge)
      ..writeByte(1)
      ..write(obj.privacy)
      ..writeByte(2)
      ..write(obj.noCache)
      ..writeByte(3)
      ..write(obj.noStore)
      ..writeByte(4)
      ..write(obj.other)
      ..writeByte(5)
      ..write(obj.maxStale)
      ..writeByte(6)
      ..write(obj.minFresh)
      ..writeByte(7)
      ..write(obj.mustRevalidate);
  }
}

class _CachePriorityAdapter extends TypeAdapter<CachePriority> {
  static const int _typeId = 95;

  @override
  final int typeId = _typeId;

  @override
  CachePriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CachePriority.low;
      case 2:
        return CachePriority.high;
      case 1:
      default:
        return CachePriority.normal;
    }
  }

  @override
  void write(BinaryWriter writer, CachePriority obj) {
    switch (obj) {
      case CachePriority.low:
        writer.writeByte(0);
      case CachePriority.normal:
        writer.writeByte(1);
      case CachePriority.high:
        writer.writeByte(2);
    }
  }
}
