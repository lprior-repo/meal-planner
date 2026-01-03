---
doc_id: ops/moonrepo/toolchain-2
chunk_id: ops/moonrepo/toolchain-2#chunk-7
heading_path: [".moon/toolchain.{pkl,yml}", "Python (v1.30.0)"]
chunk_type: code
tokens: 91
summary: "Python (v1.30.0)"
---

## Python (v1.30.0)

### `python`

Enables and configures Python.

#### `version`

Defines the explicit Python toolchain [version specification](/docs/concepts/toolchain#version-specification) to use. If this field is *not defined*, the global `python` binary will be used.

.moon/toolchain.yml

```yaml
python:
  version: '3.11.10'
```

> Python installation's are based on pre-built binaries provided by [astral-sh/python-build-standalone](https://github.com/astral-sh/python-build-standalone).

#### `packageManager` (v1.32.0)

Defines which package manager to utilize. Supports `pip` (default) or `uv`.

.moon/toolchain.yml

```yaml
python:
  packageManager: 'uv'
```
