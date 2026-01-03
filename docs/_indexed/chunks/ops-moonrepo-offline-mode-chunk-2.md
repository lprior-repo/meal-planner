---
doc_id: ops/moonrepo/offline-mode
chunk_id: ops/moonrepo/offline-mode#chunk-2
heading_path: ["Offline mode", "What's disabled when offline"]
chunk_type: prose
tokens: 87
summary: "What's disabled when offline"
---

## What's disabled when offline

When offline, moon will skip or disable the following:

- Automatic dependency installation will be skipped.
- Toolchain will skip resolving, downloading, and installing tools, and instead use the local cache.
  - If no local cache available, will fallback to binaries found on `PATH`.
  - If not available on `PATH`, will fail to run.
- Upgrade and version checks will be skipped.
