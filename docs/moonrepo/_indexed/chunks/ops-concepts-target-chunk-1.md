---
doc_id: ops/concepts/target
chunk_id: ops/concepts/target#chunk-1
heading_path: ["Targets"]
chunk_type: code
tokens: 100
summary: "Targets"
---

# Targets

> **Context**: A target is a compound identifier that pairs a [scope](#common-scopes) to a [task](/docs/concepts/task), separated by a `:`, in the format of `scope:t

A target is a compound identifier that pairs a [scope](#common-scopes) to a [task](/docs/concepts/task), separated by a `:`, in the format of `scope:task`.

Targets are used by terminal commands...

```bash
$ moon run designSystem:build
```

And configurations for declaring cross-project or cross-task dependencies.

```yaml
tasks:
  build:
    command: 'webpack'
    deps:
      - 'designSystem:build'
```
