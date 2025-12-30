---
doc_id: meta/9_rust_quickstart/index
chunk_id: meta/9_rust_quickstart/index#chunk-7
heading_path: ["Rust quickstart", "Caching"]
chunk_type: prose
tokens: 44
summary: "Caching"
---

## Caching

Every bundle on Rust is cached on disk by default. Furtherfore if you use the [Distributed cache storage](../../../misc/13_s3_cache/index.mdx), it will be available to every other worker, allowing fast startup for every worker.
