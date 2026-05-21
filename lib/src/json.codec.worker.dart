import 'dart:convert';
import 'dart:isolate';

class JsonCodecWorker {
  const JsonCodecWorker({required this.isolateThresholdBytes});

  final int isolateThresholdBytes;

  Future<String> encode(Object? value) {
    final shouldUseIsolate = _estimateSize(value) >= isolateThresholdBytes;
    if (!shouldUseIsolate) {
      return Future<String>.value(jsonEncode(value));
    }
    return Isolate.run(() => jsonEncode(value));
  }

  Future<Object?> decode(String source) {
    if (source.length < isolateThresholdBytes) {
      return Future<Object?>.value(jsonDecode(source));
    }
    return Isolate.run(() => jsonDecode(source));
  }

  int _estimateSize(Object? value) {
    if (value == null) {
      return 4;
    }
    if (value is String) {
      return value.length;
    }
    if (value is num || value is bool) {
      return 8;
    }
    if (value is Map) {
      var size = 2;
      for (final entry in value.entries) {
        size += _estimateSize(entry.key);
        size += _estimateSize(entry.value);
        if (size >= isolateThresholdBytes) {
          return size;
        }
      }
      return size;
    }
    if (value is Iterable) {
      var size = 2;
      for (final item in value) {
        size += _estimateSize(item);
        if (size >= isolateThresholdBytes) {
          return size;
        }
      }
      return size;
    }
    return value.toString().length;
  }
}
