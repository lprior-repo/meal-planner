---
doc_id: ops/config/toolchain
chunk_id: ops/config/toolchain#chunk-9
heading_path: [".moon/toolchain.{pkl,yml}", "Go"]
chunk_type: prose
tokens: 62
summary: "Go"
---

## Go

### `unstable_go` (v1.38.0)

Enables and configures Go. This setting enables the new WASM powered Go toolchain.

#### `version`

Defines the explicit Go toolchain [version specification](/docs/concepts/toolchain#version-specification) to use. If this field is *not defined*, the global `go` binary will be used.

.moon/toolchain.yml

```yaml
unstable_go:
  version: '1.24.0'
```
