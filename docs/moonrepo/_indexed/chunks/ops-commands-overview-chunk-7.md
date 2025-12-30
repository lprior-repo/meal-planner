---
doc_id: ops/commands/overview
chunk_id: ops/commands/overview#chunk-7
heading_path: ["Overview", "Concurrency"]
chunk_type: prose
tokens: 55
summary: "Concurrency"
---

## Concurrency

The `--concurrency` option or `MOON_CONCURRENCY` environment variable can be used to control the maximum amount of threads to utilize in our thread pool. If not defined, defaults to the number of operating system cores.

```
$ moon run app:build --concurrency 1
