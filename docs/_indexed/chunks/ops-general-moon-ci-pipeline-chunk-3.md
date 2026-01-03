---
doc_id: ops/general/moon-ci-pipeline
chunk_id: ops/general/moon-ci-pipeline#chunk-3
heading_path: ["Build & Test (Moon)", "What It Does"]
chunk_type: prose
tokens: 75
summary: "What It Does"
---

## What It Does

```
:ci Pipeline
├── fmt       - Rust format check
├── clippy    - Rust lints (-D warnings)
├── validate  - YAML validation
├── test      - cargo nextest (parallel)
├── build     - cargo build --release
└── copy      - Copy binaries to bin/
```

**Caching**: Moon skips unchanged tasks. First build is slow, subsequent builds are fast.
