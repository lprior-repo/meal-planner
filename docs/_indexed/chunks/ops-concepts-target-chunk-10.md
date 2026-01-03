---
doc_id: ops/concepts/target
chunk_id: ops/concepts/target#chunk-10
heading_path: ["Targets", "Resolves to"]
chunk_type: prose
tokens: 91
summary: "Resolves to"
---

## Resolves to
tasks:
  build:
    command: 'webpack'
    deps:
      - 'apiClients:build'
      - 'designSystem:build'
```

### Self `~`

When referring to another task within the current project, you can utilize the `~` scope, or omit the `~:` prefix altogether, which will be expanded to the current project's name. This is useful for situations where the name is unknown, for example, when configuring [`.moon/tasks.yml`](/docs/config/tasks), or if you just want a shortcut!

.moon/tasks.yml

```yaml
