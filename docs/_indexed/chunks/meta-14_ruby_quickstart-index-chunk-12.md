---
doc_id: meta/14_ruby_quickstart/index
chunk_id: meta/14_ruby_quickstart/index#chunk-12
heading_path: ["Ruby quickstart", "Caching"]
chunk_type: prose
tokens: 45
summary: "Caching"
---

## Caching

Every gem dependency in Ruby is cached on disk by default. Furthermore if you use the [Distributed cache storage](../../../misc/13_s3_cache/index.mdx), it will be available to every other worker, allowing fast startup for every worker.
