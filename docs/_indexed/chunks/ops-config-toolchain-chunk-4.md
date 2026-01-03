---
doc_id: ops/config/toolchain
chunk_id: ops/config/toolchain#chunk-4
heading_path: [".moon/toolchain.{pkl,yml}", "`proto` (v1.39.0)"]
chunk_type: prose
tokens: 65
summary: "`proto` (v1.39.0)"
---

## `proto` (v1.39.0)

Configures how moon integrates with and utilizes [proto](/proto).

### `version`

The version of proto to install and run toolchains with. If proto or this version of proto has not been installed yet, it will be installed automatically when running a task.

.moon/toolchain.yml

```yaml
proto:
  version: '0.51.0'
```
