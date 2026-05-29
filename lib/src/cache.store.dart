import 'cache.base.dart';
import 'cache.entry.dart';
import 'cache.options.dart';
import 'disk.msgpack.cache.dart';
import 'memory_lru_cache.dart';

class CacheDevStore implements CacheDev {
  CacheDevStore({required CacheOptions options, DiskMsgpackCache? diskCache})
    : _options = options,
      _memory = MemoryLruCache<CacheEntry>(
        maxEntries: options.memoryMaxEntries,
      ),
      _disk = diskCache ?? DiskMsgpackCache(options: options);

  final CacheOptions _options;
  final MemoryLruCache<CacheEntry> _memory;
  final DiskMsgpackCache _disk;
  final Map<String, Future<void>> _writeQueues = <String, Future<void>>{};

  @override
  Future<T?> get<T>(
    String key, {
    required T Function(Object? json) decoder,
  }) async {
    final json = await getJson(key);
    if (json == null) {
      return null;
    }
    return _decode(json, decoder);
  }

  @override
  Future<Object?> getJson(String key) async {
    final memoryEntry = _memory.get(key);
    if (memoryEntry != null) {
      if (memoryEntry.isExpired) {
        _memory.remove(key);
        await remove(key);
        return null;
      }
      return memoryEntry.data;
    }

    final entry = await _disk.read(key);
    if (entry == null) {
      return null;
    }

    _memory.set(key, entry);
    return entry.data;
  }

  @override
  Future<Map<String, Object?>> getJsonAll(
    List<String> keys, {
    int? concurrency,
  }) async {
    final result = <String, Object?>{};
    await _runBounded<String>(keys, concurrency ?? _options.bulkConcurrency, (
      key,
    ) async {
      final value = await getJson(key);
      if (value != null) {
        result[key] = value;
      }
    });
    return result;
  }

  @override
  Future<void> set<T>(
    String key,
    T value, {
    required Object? Function(T value) encoder,
    Duration? ttl,
    int? version,
  }) async {
    await setJson(key, encoder(value), ttl: ttl, version: version);
  }

  @override
  Future<void> setJson(
    String key,
    Object? json, {
    Duration? ttl,
    int? version,
  }) async {
    final entry = CacheEntry(
      version: version ?? _options.defaultVersion,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      ttl: (ttl ?? _options.defaultTtl).inMilliseconds,
      data: json,
    );

    _memory.set(key, entry);
    await _enqueue(key, () => _disk.write(key, entry));
  }

  @override
  Future<void> setJsonAll(
    Map<String, Object?> values, {
    Duration? ttl,
    int? version,
    int? concurrency,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final ttlMs = (ttl ?? _options.defaultTtl).inMilliseconds;
    final cacheVersion = version ?? _options.defaultVersion;
    final entries = <String, CacheEntry>{};

    for (final item in values.entries) {
      final entry = CacheEntry(
        version: cacheVersion,
        updatedAt: now,
        ttl: ttlMs,
        data: item.value,
      );
      entries[item.key] = entry;
      _memory.set(item.key, entry);
    }

    await _runBounded<MapEntry<String, CacheEntry>>(
      entries.entries,
      concurrency ?? _options.bulkConcurrency,
      (item) => _enqueue(item.key, () => _disk.write(item.key, item.value)),
    );
  }

  @override
  Future<void> remove(String key) async {
    _memory.remove(key);
    await _enqueue(key, () => _disk.remove(key));
  }

  @override
  Future<void> clear() async {
    _memory.clear();
    await Future.wait(_writeQueues.values);
    await _disk.clear();
  }

  @override
  Future<void> clearExpired() async {
    await Future.wait(_writeQueues.values);
    await _disk.clearExpired();
  }

  @override
  Future<void> warmUp(List<String> keys) async {
    for (final key in keys) {
      final entry = await _disk.read(key);
      if (entry != null) {
        _memory.set(key, entry);
      } else {
        _memory.remove(key);
      }
    }
  }

  Future<void> _enqueue(String key, Future<void> Function() action) {
    final previous = _writeQueues[key] ?? Future<void>.value();
    late Future<void> next;
    next = previous.catchError((_) {}).then((_) => action()).whenComplete(() {
      if (identical(_writeQueues[key], next)) {
        _writeQueues.remove(key);
      }
    });
    _writeQueues[key] = next;
    return next;
  }

  Future<void> _runBounded<T>(
    Iterable<T> items,
    int concurrency,
    Future<void> Function(T item) action,
  ) async {
    final iterator = items.iterator;
    final workerCount = concurrency <= 0 ? 1 : concurrency;

    Future<void> worker() async {
      while (true) {
        final T item;
        if (iterator.moveNext()) {
          item = iterator.current;
        } else {
          return;
        }
        await action(item);
      }
    }

    await Future.wait<void>(
      List<Future<void>>.generate(workerCount, (_) => worker()),
    );
  }

  T? _decode<T>(Object? json, T Function(Object? json) decoder) {
    try {
      return decoder(json);
    } on Object {
      return null;
    }
  }
}
