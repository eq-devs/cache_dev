# cache_dev

`cache_dev` is a lightweight, mobile-first JSON file cache for Flutter apps.

It is designed for API response caching, offline-first screen restore, product and order lists, homepage data, price snapshots, and WebView-heavy hybrid apps that need fast exact-key cache access without adding a full database.

## Features

- Memory LRU cache for hot entries
- One cache key per JSON file
- Async file IO
- Safe writes through temp file + rename
- TTL expiration
- Version field for future migrations
- Background JSON encode/decode with `Isolate.run` for large payloads
- Direct JSON encode/decode for small payloads to avoid isolate overhead
- Hashed file names
- Optional sharded folders for large cache directories
- Per-key write serialization
- Corrupted JSON handling
- Warm startup support
- Android and iOS support
- No Hive, Isar, Drift, SQLite, or sqflite

## Architecture

```text
UI
↓
Memory LRU Cache
↓
Split JSON File Cache
↓
Remote API
```

Each key is stored as a separate file. The package never writes all cached data into one large `cache.json`.

Conceptually:

```text
cache/
├─ home.json
├─ profile.json
├─ order_page_1.json
├─ order_page_2.json
├─ product_123.json
└─ price_tracking.json
```

In production, keys are hashed into safe filenames. With sharding enabled, files are split into folders:

```text
cache/
├─ ab/
│  └─ cdef123....json
└─ 42/
   └─ a9810b....json
```

## Why not Hive or SQLite

Hive, Isar, Drift, SQLite, and sqflite are good choices when your app needs indexes, queries, relations, transactions, local-first data models, or complex persistence.

`cache_dev` is intentionally simpler. It is for JSON-compatible payloads that are read by exact key, where your remote API remains the source of truth. This keeps startup work low, memory usage predictable, and cache behavior easy to reason about.

## Installation

```yaml
dependencies:
  cache_dev: ^0.0.1
```

For mobile apps, use a directory from `path_provider`:

```yaml
dependencies:
  cache_dev: ^0.0.1
  path_provider: ^2.1.5
```

## Setup

```dart
import 'dart:io';

import 'package:cache_dev/cache_dev.dart';
import 'package:path_provider/path_provider.dart';

Future<CacheDevStore> createCache() async {
  final appDocDir = await getApplicationDocumentsDirectory();

  return CacheDevStore(
    options: CacheOptions(
      directory: Directory('${appDocDir.path}/cache_dev'),
      memoryMaxEntries: 24,
      defaultTtl: const Duration(minutes: 10),
    ),
  );
}
```

## Basic usage

```dart
await cache.set<HomeModel>(
  'home',
  home,
  encoder: (value) => value.toJson(),
  ttl: const Duration(minutes: 5),
  version: 1,
);

final home = await cache.get<HomeModel>(
  'home',
  decoder: (json) => HomeModel.fromJson(json as Map<String, dynamic>),
);
```

The cache stores JSON-compatible data internally, not model instances. Your `encoder` converts a model into JSON-compatible data, and your `decoder` converts JSON-compatible data back into your model.

Supported JSON-compatible values:

- `Map`
- `List`
- `String`
- `num`
- `bool`
- `null`

## Cache file format

Every file stores metadata and payload:

```json
{
  "version": 1,
  "updatedAt": 1710000000000,
  "ttl": 300000,
  "data": {}
}
```

Fields:

- `version`: app-controlled cache schema version
- `updatedAt`: write time in milliseconds since epoch
- `ttl`: time to live in milliseconds
- `data`: JSON-compatible payload

`Duration.zero` means the entry does not expire automatically.

## TTL

```dart
await cache.set(
  'profile_user_1',
  profile,
  encoder: (value) => value.toJson(),
  ttl: const Duration(hours: 6),
);
```

Expired entries return `null`. If an expired file is read from disk, it is deleted.

You can also remove expired files manually:

```dart
await cache.clearExpired();
```

Run `clearExpired()` during idle moments, not on every app launch.

## Warm startup

Warm only the keys needed for the first screen:

```dart
await cache.warmUp(<String>[
  'home',
  'profile_user_1',
]);
```

`warmUp` does not scan or preload the full cache directory. It only loads the keys you provide.

## Removing data

```dart
await cache.remove('home');
```

Clear the whole cache:

```dart
await cache.clear();
```

## Options

```dart
CacheOptions(
  directory: Directory('/path/to/cache'),
  memoryMaxEntries: 32,
  isolateThresholdBytes: 20 * 1024,
  enableSharding: true,
  defaultVersion: 1,
  defaultTtl: Duration.zero,
  deleteCorruptedFile: true,
  flushWrites: true,
  bulkConcurrency: 4,
)
```

### `directory`

Root directory for cache files. Use an application-owned directory, such as one returned by `path_provider`.

### `memoryMaxEntries`

Maximum number of hot entries kept in memory. The memory cache uses LRU eviction.

Set a smaller value for low-end devices or large payloads.

### `isolateThresholdBytes`

Payloads at or above this estimated size are encoded or decoded in a background isolate. Smaller payloads are processed directly to avoid isolate overhead.

### `enableSharding`

When enabled, hashed filenames are split into subfolders. This is recommended when an app may store many cache files.

### `defaultVersion`

Version used when `set` does not receive a specific version.

### `defaultTtl`

TTL used when `set` does not receive a specific TTL.

### `deleteCorruptedFile`

When enabled, unreadable or malformed cache files are deleted and treated as cache misses.

### `flushWrites`

When enabled, file writes request an OS flush before rename. This is safer, but slower. For non-critical API response cache data, setting this to `false` can significantly improve write-heavy benchmarks.

### `bulkConcurrency`

Default concurrency for bulk operations such as `setJsonAll` and `getJsonAll`.

## Public API

```dart
abstract interface class CacheDev {
  Future<T?> get<T>(
    String key, {
    required T Function(Object? json) decoder,
  });

  Future<Object?> getJson(String key);

  Future<Map<String, Object?>> getJsonAll(
    List<String> keys, {
    int? concurrency,
  });

  Future<void> set<T>(
    String key,
    T value, {
    required Object? Function(T value) encoder,
    Duration? ttl,
    int? version,
  });

  Future<void> setJson(
    String key,
    Object? json, {
    Duration? ttl,
    int? version,
  });

  Future<void> setJsonAll(
    Map<String, Object?> values, {
    Duration? ttl,
    int? version,
    int? concurrency,
  });

  Future<void> remove(String key);

  Future<void> clear();

  Future<void> clearExpired();

  Future<void> warmUp(List<String> keys);
}
```

## Concurrency behavior

Writes for the same key are serialized. This prevents two overlapping `set()` calls from writing the same file at the same time.

Writes use a temporary file and then rename it to the final path. If a write fails, the cache avoids leaving partially written final files.

`remove()` clears memory first and then removes the disk file through the same per-key queue.

## Error behavior

Normal cache failures do not crash the app:

- Missing file returns `null`
- Expired file returns `null`
- Corrupted file returns `null`
- Corrupted file is deleted when `deleteCorruptedFile` is enabled
- File-system errors during cache operations are swallowed as cache misses or failed cache writes

Your `decoder` can still reject invalid payloads. If decoding fails inside `get`, the method returns `null`.

## Example app

This repository includes a Flutter example app with Android and iOS projects:

```sh
cd example
flutter run
```

The example uses `path_provider` and works as a mobile cache console. It writes and reads multiple JSON payloads:

- homepage cache
- profile cache
- product pages
- order pages
- price tracking snapshots
- benchmark payloads

It also includes UI actions for warm-up, clear, benchmark runs, and a side-by-side Hive comparison.

Hive is intentionally used only by the example app. The `cache_dev` package itself does not depend on Hive.

The comparison separates raw reads from read-plus-map-copy work. This matters because Hive can return binary-stored Dart values directly, while `cache_dev` reads portable JSON files and decodes JSON text.

Example dependencies:

```yaml
dependencies:
  cache_dev:
    path: ..
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.5
```

Build checks:

```sh
cd example
flutter build apk --debug
flutter build ios --debug --no-codesign
```

## Benchmark test

A benchmark-style test is included:

```sh
flutter test test/cache_dev_benchmark_test.dart
```

It reports timings for:

- 100 writes
- 100 cold disk reads
- 100 hot memory reads
- warm-up of selected keys
- expired-file scanning

The benchmark does not enforce strict timing thresholds because results vary by CI machine, emulator, device, file system, and payload size.

## Low-end Android recommendations

- Keep `memoryMaxEntries` between `12` and `32`.
- Cache large lists page by page.
- Prefer keys such as `order_page_1`, `order_page_2`, and `product_123`.
- Keep sharding enabled when storing many entries.
- Avoid warming too many keys at startup.
- Run `clearExpired()` after first paint or during idle work.
- Tune `isolateThresholdBytes` based on payload size.

## WebView-heavy app recommendations

- Cache expensive API responses used by both Flutter and WebView flows.
- Keep homepage, account, cart, and product payloads under separate keys.
- Warm only the data needed by the first route.
- Use TTLs aggressively for data that changes often.
- Avoid a single giant key for an entire WebView session.

## Best use cases

- Homepage cache
- Product lists
- Category pages
- Paginated order lists
- Profile snapshots
- Price tracking snapshots
- Large API response cache
- Offline-first screen restore
- Hybrid Flutter/WebView apps
- Exact-key cache lookup

## Not suitable for

- Complex local queries
- Full-text search
- Relational data
- Joins
- Secondary indexes
- High-write transactional workloads
- Local-first databases
- Data that must be edited and synchronized record by record

Use a database for those cases.

## Performance tips

- Use one key per response or page.
- Keep hot data in memory and cold data on disk.
- Store only JSON-compatible payloads.
- Do not preload the whole cache directory.
- Keep payloads reasonably scoped.
- Use `setJsonAll` and `getJsonAll` for many keys.
- Consider `flushWrites: false` for recoverable API response caches.
- Use TTLs to prevent stale disk growth.
- Avoid running cleanup during app launch.
- Measure on real low-end Android hardware if that is your target.

## Development

Run package checks:

```sh
dart format .
flutter analyze
flutter test
```

Run example checks:

```sh
cd example
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --debug --no-codesign
```

## License

See `LICENSE`.
