---
doc_id: meta/1_typescript_quickstart/index
chunk_id: meta/1_typescript_quickstart/index#chunk-9
heading_path: ["TypeScript quickstart", "Caching"]
chunk_type: prose
tokens: 44
summary: "Caching"
---

## Caching

Every bundle on Bun is cached on disk by default. Furtherfore if you use the [Distributed cache storage](../../../misc/13_s3_cache/index.mdx), it will be available to every other worker, allowing fast startup for every worker.
