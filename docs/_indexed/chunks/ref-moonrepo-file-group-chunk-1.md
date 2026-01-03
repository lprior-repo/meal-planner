---
doc_id: ref/moonrepo/file-group
chunk_id: ref/moonrepo/file-group#chunk-1
heading_path: ["File groups"]
chunk_type: prose
tokens: 100
summary: "File groups"
---

# File groups

> **Context**: File groups are a mechanism for grouping similar types of files and environment variables within a project using [file glob patterns or literal file p

File groups are a mechanism for grouping similar types of files and environment variables within a project using [file glob patterns or literal file paths](/docs/concepts/file-pattern). These groups are then used by [tasks](/docs/concepts/task) to calculate functionality like cache computation, affected files since last change, deterministic builds, and more.
