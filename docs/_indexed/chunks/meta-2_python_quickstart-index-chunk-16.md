---
doc_id: meta/2_python_quickstart/index
chunk_id: meta/2_python_quickstart/index#chunk-16
heading_path: ["Python quickstart", "Caching"]
chunk_type: prose
tokens: 44
summary: "Caching"
---

## Caching

Every dependency on Python is cached on disk by default. Furtherfore if you use the [Distributed cache storage](../../../misc/13_s3_cache/index.mdx), it will be available to every other worker, allowing fast startup for every worker.
