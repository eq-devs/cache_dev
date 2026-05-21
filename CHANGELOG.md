## 0.0.1

Initial release.

* Memory LRU cache with a configurable maximum number of entries.
* Sharded JSON file cache — one key maps to one file, with SHA-1 hashed filenames.
* Per-entry TTL with lazy expiry on read and a `clearExpired()` sweep.
* Isolate-backed JSON encode/decode above a configurable byte threshold.
* Atomic file writes via temp-file rename, serialized per key.
* `warmUp()` for selective preloading of hot keys at startup.
