class MemoryLruCache<V> {
  MemoryLruCache({required int maxEntries}) : _maxEntries = maxEntries;

  final int _maxEntries;
  final _entries = <String, V>{};

  int get length => _entries.length;

  V? get(String key) {
    if (!_entries.containsKey(key)) {
      return null;
    }
    final value = _entries.remove(key) as V;
    _entries[key] = value;
    return value;
  }

  void set(String key, V value) {
    if (_maxEntries <= 0) {
      return;
    }

    _entries.remove(key);
    _entries[key] = value;

    while (_entries.length > _maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  void remove(String key) {
    _entries.remove(key);
  }

  void clear() {
    _entries.clear();
  }
}
