abstract interface class CacheDev {
  Future<T?> get<T>(String key, {required T Function(Object? json) decoder});

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

  Future<void> setJson(String key, Object? json, {Duration? ttl, int? version});

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
