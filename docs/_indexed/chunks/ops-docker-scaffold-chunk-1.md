---
doc_id: ops/docker/scaffold
chunk_id: ops/docker/scaffold#chunk-1
heading_path: ["docker scaffold"]
chunk_type: prose
tokens: 80
summary: "docker scaffold"
---

# docker scaffold

> **Context**: The `moon docker scaffold <...projects>` command creates multiple repository skeletons for use within `Dockerfile`s, to effectively take advantage of 

The `moon docker scaffold <...projects>` command creates multiple repository skeletons for use within `Dockerfile`s, to effectively take advantage of Docker's layer caching. It utilizes the [project graph](/docs/config/workspace#projects) to copy only critical files, like manifests, lockfiles, and configuration.

```
