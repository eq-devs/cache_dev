## 0.1.0

Switched the on-disk format from JSON to MessagePack.

* **Breaking:** cache files are now MessagePack binary (`.msgpack`) instead of JSON (`.json`). Existing `0.0.1` caches are not readable; they are treated as misses and replaced.
* **Breaking:** `DiskJsonCache` / `JsonCodecWorker` are replaced by `DiskMsgpackCache` / `MsgpackCodecWorker`.
* Isolate-backed MessagePack encode/decode above the configurable byte threshold, with decoding and normalization both performed in the isolate for large payloads.
* Added `msgpack_dart` dependency.
* Note: MessagePack supports non-string map keys; decoded keys are coerced to `String`, so an int-keyed map round-trips back as a `String`-keyed map.

## 0.0.1

Initial release.

* Memory LRU cache with a configurable maximum number of entries.
* Sharded JSON file cache — one key maps to one file, with SHA-1 hashed filenames.
* Per-entry TTL with lazy expiry on read and a `clearExpired()` sweep.
* Isolate-backed JSON encode/decode above a configurable byte threshold.
* Atomic file writes via temp-file rename, serialized per key.
* `warmUp()` for selective preloading of hot keys at startup.
