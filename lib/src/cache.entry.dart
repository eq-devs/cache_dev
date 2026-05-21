class CacheEntry {
  const CacheEntry({
    required this.version,
    required this.updatedAt,
    required this.ttl,
    required this.data,
  });

  final int version;
  final int updatedAt;
  final int ttl;
  final Object? data;

  bool get isExpired {
    if (ttl <= 0) {
      return false;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - updatedAt >= ttl;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'version': version,
      'updatedAt': updatedAt,
      'ttl': ttl,
      'data': data,
    };
  }

  static CacheEntry fromJson(Map<String, Object?> json) {
    final version = json['version'];
    final updatedAt = json['updatedAt'];
    final ttl = json['ttl'];

    if (version is! int || updatedAt is! int || ttl is! int) {
      throw const FormatException('Invalid cache entry metadata.');
    }

    return CacheEntry(
      version: version,
      updatedAt: updatedAt,
      ttl: ttl,
      data: json['data'],
    );
  }
}
