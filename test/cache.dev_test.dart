import 'dart:convert';
import 'dart:io';

import 'package:cache_dev/cache_dev.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late CacheDevStore cache;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('cache_dev_test_');
    cache = CacheDevStore(options: CacheOptions(directory: directory));
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('memory LRU evicts oldest entry', () {
    final memory = MemoryLruCache<int>(maxEntries: 2);
    memory.set('a', 1);
    memory.set('b', 2);
    expect(memory.get('a'), 1);
    memory.set('c', 3);

    expect(memory.get('b'), isNull);
    expect(memory.get('a'), 1);
    expect(memory.get('c'), 3);
  });

  test('set and get cache value', () async {
    await cache.set<Map<String, Object?>>('home', <String, Object?>{
      'title': 'Home',
    }, encoder: (value) => value);

    final value = await cache.get<Map<String, Object?>>(
      'home',
      decoder: (json) => Map<String, Object?>.from(json! as Map),
    );

    expect(value, <String, Object?>{'title': 'Home'});
  });

  test('expired TTL returns null', () async {
    await cache.set<String>(
      'short',
      'value',
      encoder: (value) => value,
      ttl: const Duration(milliseconds: 1),
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));

    final value = await cache.get<String>(
      'short',
      decoder: (json) => json! as String,
    );

    expect(value, isNull);
  });

  test('expired file is deleted on read', () async {
    await cache.set<String>(
      'expired',
      'value',
      encoder: (value) => value,
      ttl: const Duration(milliseconds: 1),
    );
    final file = DiskJsonCache(
      options: CacheOptions(directory: directory),
    ).fileForKey('expired');
    await Future<void>.delayed(const Duration(milliseconds: 5));

    final value = await CacheDevStore(
      options: CacheOptions(directory: directory),
    ).get<String>('expired', decoder: (json) => json! as String);

    expect(value, isNull);
    expect(await file.exists(), isFalse);
  });

  test('remove deletes cache', () async {
    await cache.set<String>('profile', 'one', encoder: (value) => value);
    await cache.remove('profile');

    final value = await cache.get<String>(
      'profile',
      decoder: (json) => json! as String,
    );

    expect(value, isNull);
  });

  test('clear deletes all cache', () async {
    await cache.set<String>('a', '1', encoder: (value) => value);
    await cache.set<String>('b', '2', encoder: (value) => value);
    await cache.clear();

    expect(await directory.exists(), isFalse);
    expect(
      await cache.get<String>('a', decoder: (json) => json! as String),
      isNull,
    );
  });

  test('corrupted JSON returns null', () async {
    final disk = DiskJsonCache(options: CacheOptions(directory: directory));
    final file = disk.fileForKey('bad');
    await file.parent.create(recursive: true);
    await file.writeAsString('{bad json');

    final value = await cache.get<String>(
      'bad',
      decoder: (json) => json! as String,
    );

    expect(value, isNull);
    expect(await file.exists(), isFalse);
  });

  test('version field is preserved', () async {
    await cache.set<String>(
      'versioned',
      'value',
      encoder: (value) => value,
      version: 7,
    );

    final entry = await DiskJsonCache(
      options: CacheOptions(directory: directory),
    ).read('versioned');

    expect(entry?.version, 7);
  });

  test('warmUp loads provided keys into memory', () async {
    await cache.set<String>('home', 'warm', encoder: (value) => value);
    final warmed = CacheDevStore(options: CacheOptions(directory: directory));

    await warmed.warmUp(<String>['home']);
    await directory.delete(recursive: true);

    final value = await warmed.get<String>(
      'home',
      decoder: (json) => json! as String,
    );
    expect(value, 'warm');
  });

  test('concurrent writes for same key do not corrupt final file', () async {
    final writes = <Future<void>>[];
    for (var i = 0; i < 50; i++) {
      writes.add(
        cache.set<Map<String, Object?>>('same', <String, Object?>{
          'index': i,
          'items': List<int>.filled(100, i),
        }, encoder: (value) => value),
      );
    }

    await Future.wait(writes);

    final file = DiskJsonCache(
      options: CacheOptions(directory: directory),
    ).fileForKey('same');
    final decoded = jsonDecode(await file.readAsString());

    expect(decoded, isA<Map<String, Object?>>());
    expect(
      (decoded as Map<String, Object?>)['data'],
      isA<Map<String, Object?>>(),
    );
  });

  test('setJsonAll and getJsonAll handle bulk raw JSON values', () async {
    final fastCache = CacheDevStore(
      options: CacheOptions(
        directory: directory,
        flushWrites: false,
        bulkConcurrency: 3,
      ),
    );

    await fastCache.setJsonAll(<String, Object?>{
      'page_1': <String, Object?>{
        'items': <int>[1, 2, 3],
      },
      'page_2': <String, Object?>{
        'items': <int>[4, 5, 6],
      },
      'page_3': <String, Object?>{
        'items': <int>[7, 8, 9],
      },
    });

    final values = await CacheDevStore(
      options: CacheOptions(directory: directory),
    ).getJsonAll(<String>['page_1', 'page_2', 'page_3'], concurrency: 2);

    expect(values.keys, containsAll(<String>['page_1', 'page_2', 'page_3']));
    expect((values['page_2']! as Map<String, Object?>)['items'], <Object?>[
      4,
      5,
      6,
    ]);
  });

  test('sharded file path generation', () {
    const hasher = KeyHasher();
    final path = hasher.fileNameForKey('product_123');

    expect(path, endsWith('.json'));
    expect(path.contains(Platform.pathSeparator), isTrue);
    expect(path.split(Platform.pathSeparator).first.length, 2);
  });
}
