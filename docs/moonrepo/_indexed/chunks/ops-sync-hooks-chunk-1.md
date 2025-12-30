---
doc_id: ops/sync/hooks
chunk_id: ops/sync/hooks#chunk-1
heading_path: ["sync hooks"]
chunk_type: prose
tokens: 83
summary: "sync hooks"
---

# sync hooks

> **Context**: The `moon sync hooks` command will manually sync hooks for the configured [VCS](/docs/config/workspace#vcs), by generating and referencing hook script

v1.9.0

The `moon sync hooks` command will manually sync hooks for the configured [VCS](/docs/config/workspace#vcs), by generating and referencing hook scripts from the [`vcs.hooks`](/docs/config/workspace#hooks) setting. Refer to the official [VCS hooks](/docs/guides/vcs-hooks) guide for more information.

```
$ moon sync hooks
```
