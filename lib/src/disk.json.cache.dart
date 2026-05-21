import 'dart:async';
import 'dart:io';

import 'cache.entry.dart';
import 'cache.exception.dart';
import 'cache.options.dart';
import 'json.codec.worker.dart';
import 'key.hasher.dart';

class DiskJsonCache {
  DiskJsonCache({
    required CacheOptions options,
    JsonCodecWorker? codec,
    KeyHasher? keyHasher,
  }) : _options = options,
       _codec =
           codec ??
           JsonCodecWorker(
             isolateThresholdBytes: options.isolateThresholdBytes,
           ),
       _keyHasher =
           keyHasher ?? KeyHasher(enableSharding: options.enableSharding);

  final CacheOptions _options;
  final JsonCodecWorker _codec;
  final KeyHasher _keyHasher;

  File fileForKey(String key) {
    return File(_join(_options.directory.path, _keyHasher.fileNameForKey(key)));
  }

  Future<CacheEntry?> read(String key) async {
    final file = fileForKey(key);
    try {
      if (!await file.exists()) {
        return null;
      }

      final source = await file.readAsString();
      final decoded = await _codec.decode(source);
      if (decoded is! Map) {
        throw const FormatException('Cache file root must be an object.');
      }

      final entry = CacheEntry.fromJson(Map<String, Object?>.from(decoded));
      if (entry.isExpired) {
        await _deleteFileIfExists(file);
        return null;
      }

      return entry;
    } on FormatException {
      await _deleteCorrupted(file);
      return null;
    } on FileSystemException {
      return null;
    } on Object {
      await _deleteCorrupted(file);
      return null;
    }
  }

  Future<void> write(String key, CacheEntry entry) async {
    final file = fileForKey(key);
    final parent = file.parent;
    final tempFile = File('${file.path}.tmp');

    final String source;
    try {
      source = await _codec.encode(entry.toJson());
    } on Object catch (error) {
      throw CacheDevException(
        'Failed to encode cache entry for key "$key". '
        'Cached values must be JSON-compatible.',
        error,
      );
    }

    try {
      await parent.create(recursive: true);
      await tempFile.writeAsString(source, flush: _options.flushWrites);
      await _atomicRename(tempFile, file);
    } on FileSystemException {
      await _deleteFileIfExists(tempFile);
    }
  }

  Future<void> _atomicRename(File tempFile, File file) async {
    try {
      // On POSIX (Android/iOS) rename atomically replaces the destination,
      // so there is never a window where the cache key is missing.
      await tempFile.rename(file.path);
    } on FileSystemException {
      // Some platforms cannot rename onto an existing file; fall back to a
      // delete-then-rename, accepting a tiny non-atomic window there.
      if (await file.exists()) {
        await file.delete();
      }
      await tempFile.rename(file.path);
    }
  }

  Future<void> remove(String key) async {
    await _deleteFileIfExists(fileForKey(key));
    await _deleteFileIfExists(File('${fileForKey(key).path}.tmp'));
  }

  Future<void> clear() async {
    try {
      if (await _options.directory.exists()) {
        await _options.directory.delete(recursive: true);
      }
    } on FileSystemException {
      return;
    }
  }

  Future<void> clearExpired() async {
    try {
      if (!await _options.directory.exists()) {
        return;
      }

      await for (final entity in _options.directory.list(recursive: true)) {
        if (entity is! File) {
          continue;
        }
        // Reclaim orphan temp files left behind by an interrupted write.
        if (entity.path.endsWith('.tmp')) {
          await _deleteFileIfExists(entity);
          continue;
        }
        if (!entity.path.endsWith('.json')) {
          continue;
        }
        await _removeIfExpiredOrCorrupt(entity);
      }
    } on FileSystemException {
      return;
    }
  }

  Future<void> _removeIfExpiredOrCorrupt(File file) async {
    try {
      final source = await file.readAsString();
      final decoded = await _codec.decode(source);
      if (decoded is! Map) {
        throw const FormatException('Cache file root must be an object.');
      }
      final entry = CacheEntry.fromJson(Map<String, Object?>.from(decoded));
      if (entry.isExpired) {
        await _deleteFileIfExists(file);
      }
    } on Object {
      await _deleteCorrupted(file);
    }
  }

  Future<void> _deleteCorrupted(File file) async {
    if (_options.deleteCorruptedFile) {
      await _deleteFileIfExists(file);
    }
  }

  Future<void> _deleteFileIfExists(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      return;
    }
  }

  String _join(String left, String right) {
    if (left.endsWith(Platform.pathSeparator)) {
      return '$left$right';
    }
    return '$left${Platform.pathSeparator}$right';
  }
}
