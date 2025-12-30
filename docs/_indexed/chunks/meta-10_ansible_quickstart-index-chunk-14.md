---
doc_id: meta/10_ansible_quickstart/index
chunk_id: meta/10_ansible_quickstart/index#chunk-14
heading_path: ["Ansible quickstart", "Caching"]
chunk_type: prose
tokens: 44
summary: "Caching"
---

## Caching

Every dependency on Python is cached on disk by default. Furtherfore if you use the [Distributed cache storage](../../../misc/13_s3_cache/index.mdx), it will be available to every other worker, allowing fast startup for every worker.
