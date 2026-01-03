---
doc_id: ops/moonrepo/teardown
chunk_id: ops/moonrepo/teardown#chunk-1
heading_path: ["teardown"]
chunk_type: prose
tokens: 89
summary: "teardown"
---

# teardown

> **Context**: The `moon teardown` command, as its name infers, will teardown and clean the current environment, opposite the [`setup`](/docs/commands/setup) command

The `moon teardown` command, as its name infers, will teardown and clean the current environment, opposite the [`setup`](/docs/commands/setup) command. It achieves this by doing the following:

- Uninstalling all configured tools in the toolchain.
- Removing any download or temporary files/folders.

```
$ moon teardown
```
