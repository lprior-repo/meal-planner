---
doc_id: ref/enumerations/cachesharingmode
chunk_id: ref/enumerations/cachesharingmode#chunk-2
heading_path: ["cachesharingmode", "Enumeration Members"]
chunk_type: prose
tokens: 61
summary: "> **Locked**: `\"LOCKED\"`

Shares the cache volume amongst many build pipelines, but will serialize t"
---
### Locked

> **Locked**: `"LOCKED"`

Shares the cache volume amongst many build pipelines, but will serialize the writes

---

### Private

> **Private**: `"PRIVATE"`

Keeps a cache volume for a single build pipeline

---

### Shared

> **Shared**: `"SHARED"`

Shares the cache volume amongst many build pipelines
