import 'dart:io';

class CacheOptions {
  const CacheOptions({
    required this.directory,
    this.memoryMaxEntries = 32,
    this.isolateThresholdBytes = 20 * 1024,
    this.enableSharding = true,
    this.defaultVersion = 1,
    this.defaultTtl = Duration.zero,
    this.deleteCorruptedFile = true,
    this.flushWrites = true,
    this.bulkConcurrency = 4,
  });

  final Directory directory;
  final int memoryMaxEntries;
  final int isolateThresholdBytes;
  final bool enableSharding;
  final int defaultVersion;
  final Duration defaultTtl;
  final bool deleteCorruptedFile;
  final bool flushWrites;
  final int bulkConcurrency;
}
