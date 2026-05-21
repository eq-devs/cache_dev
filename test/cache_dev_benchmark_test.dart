import 'dart:io';

import 'package:cache_dev/cache_dev.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'benchmark set, disk get, memory get, warmUp, and clearExpired',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'cache_dev_benchmark_',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      final cache = CacheDevStore(
        options: CacheOptions(
          directory: directory,
          memoryMaxEntries: 64,
          isolateThresholdBytes: 4 * 1024,
        ),
      );
      final payload = _largePayload(200);

      final writeWatch = Stopwatch()..start();
      for (var i = 0; i < 100; i++) {
        await cache.set<Map<String, Object?>>(
          'product_page_$i',
          payload,
          encoder: (value) => value,
          ttl: const Duration(minutes: 10),
        );
      }
      writeWatch.stop();

      final coldCache = CacheDevStore(
        options: CacheOptions(
          directory: directory,
          memoryMaxEntries: 64,
          isolateThresholdBytes: 4 * 1024,
        ),
      );

      final diskReadWatch = Stopwatch()..start();
      for (var i = 0; i < 100; i++) {
        final value = await coldCache.get<Map<String, Object?>>(
          'product_page_$i',
          decoder: (json) => Map<String, Object?>.from(json! as Map),
        );
        expect(value, isNotNull);
      }
      diskReadWatch.stop();

      final memoryReadWatch = Stopwatch()..start();
      for (var i = 0; i < 100; i++) {
        final value = await coldCache.get<Map<String, Object?>>(
          'product_page_$i',
          decoder: (json) => Map<String, Object?>.from(json! as Map),
        );
        expect(value, isNotNull);
      }
      memoryReadWatch.stop();

      final warmWatch = Stopwatch()..start();
      await CacheDevStore(
        options: CacheOptions(directory: directory, memoryMaxEntries: 64),
      ).warmUp(List<String>.generate(32, (index) => 'product_page_$index'));
      warmWatch.stop();

      final clearExpiredWatch = Stopwatch()..start();
      await cache.clearExpired();
      clearExpiredWatch.stop();

      debugPrint(
        'cache_dev benchmark: '
        'write100=${writeWatch.elapsedMilliseconds}ms, '
        'diskRead100=${diskReadWatch.elapsedMilliseconds}ms, '
        'memoryRead100=${memoryReadWatch.elapsedMilliseconds}ms, '
        'warm32=${warmWatch.elapsedMilliseconds}ms, '
        'clearExpired=${clearExpiredWatch.elapsedMilliseconds}ms',
      );

      expect(writeWatch.elapsedMicroseconds, greaterThan(0));
      expect(diskReadWatch.elapsedMicroseconds, greaterThan(0));
      expect(memoryReadWatch.elapsedMicroseconds, greaterThan(0));
    },
  );
}

Map<String, Object?> _largePayload(int count) {
  return <String, Object?>{
    'items': List<Map<String, Object?>>.generate(
      count,
      (index) => <String, Object?>{
        'id': index,
        'title': 'Product $index',
        'description': 'Large response payload item $index',
        'price': 10.5 + index,
        'tags': <String>['home', 'promo', 'mobile'],
        'available': index.isEven,
      },
    ),
    'nextPage': 2,
    'updatedAt': DateTime.now().millisecondsSinceEpoch,
  };
}
