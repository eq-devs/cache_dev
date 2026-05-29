import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

class KeyHasher {
  const KeyHasher({this.enableSharding = true});

  final bool enableSharding;

  String fileNameForKey(String key) {
    final hash = sha1.convert(utf8.encode(key)).toString();
    if (!enableSharding) {
      return '$hash.msgpack';
    }
    return '${hash.substring(0, 2)}${Platform.pathSeparator}'
        '${hash.substring(2)}.msgpack';
  }
}
