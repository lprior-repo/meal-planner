---
doc_id: ops/moonrepo/node-handbook
chunk_id: ops/moonrepo/node-handbook#chunk-2
heading_path: ["Node.js handbook", "moon setup"]
chunk_type: prose
tokens: 87
summary: "moon setup"
---

## moon setup

For this part of the handbook, we'll be focusing on [moon](/moon), our task runner. To start, languages in moon act like plugins, where their functionality and support *is not* enabled unless explicitly configured. We follow this approach to avoid unnecessary overhead.

### Enabling the language

To enable JavaScript support via Node.js, define the [`node`](/docs/config/toolchain#node) setting in [`.moon/toolchain.yml`](/docs/config/toolchain), even if an empty object.

.moon/toolchain.yml

```
