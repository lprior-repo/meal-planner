---
doc_id: ops/config/project
chunk_id: ops/config/project#chunk-12
heading_path: ["moon.{pkl,yml}", "`env`"]
chunk_type: prose
tokens: 66
summary: "`env`"
---

## `env`

The `env` field is map of strings that are passed as environment variables to *all tasks* within the current project. Project-level variables will not override task-level variables of the same name.

moon.yml

```yaml
env:
  NODE_ENV: 'production'
```

> View the task [`env`](#env-1) setting for more usage examples and information.
