import 'dart:isolate';
import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;

class MsgpackCodecWorker {
  const MsgpackCodecWorker({required this.isolateThresholdBytes});

  final int isolateThresholdBytes;

  Future<Uint8List> encode(Object? value) {
    final shouldUseIsolate = _estimateSize(value) >= isolateThresholdBytes;
    if (!shouldUseIsolate) {
      return Future<Uint8List>.value(msgpack.serialize(value));
    }
    return Isolate.run(() => msgpack.serialize(value));
  }

  Future<Object?> decode(Uint8List source) {
    // Normalize inside the isolate for large payloads. The deep-copy walk is as
    // expensive as the deserialize itself, so running it on the main isolate
    // would reintroduce the jank the threshold is meant to avoid.
    if (source.length < isolateThresholdBytes) {
      return Future<Object?>.value(_normalize(msgpack.deserialize(source)));
    }
    return Isolate.run(() => _normalize(msgpack.deserialize(source)));
  }

  // msgpack_dart returns Map<dynamic, dynamic> and List<dynamic>. Deep-convert
  // to Map<String, Object?> / List<Object?> so callers can cast cache values
  // the same way they could with JSON-decoded data. Unlike JSON, MessagePack
  // can encode non-string map keys; they are coerced to String here, so an
  // int-keyed map round-trips back as a String-keyed map.
  static Object? _normalize(Object? value) {
    if (value is Map) {
      final result = <String, Object?>{};
      for (final entry in value.entries) {
        result[entry.key.toString()] = _normalize(entry.value);
      }
      return result;
    }
    if (value is List) {
      return List<Object?>.generate(
        value.length,
        (index) => _normalize(value[index]),
      );
    }
    return value;
  }

  int _estimateSize(Object? value) {
    if (value == null) {
      return 4;
    }
    if (value is String) {
      // Approximate: code units, not encoded UTF-8 bytes. The threshold is a
      // heuristic for isolate offload, so an undercount here is acceptable.
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
