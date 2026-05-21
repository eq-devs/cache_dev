class CacheDevException implements Exception {
  const CacheDevException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'CacheDevException: $message';
    }
    return 'CacheDevException: $message ($cause)';
  }
}
