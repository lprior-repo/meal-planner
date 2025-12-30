---
doc_id: ops/config/project
chunk_id: ops/config/project#chunk-2
heading_path: ["moon.{pkl,yml}", "`dependsOn`"]
chunk_type: code
tokens: 136
summary: "`dependsOn`"
---

## `dependsOn`

Explicitly defines *other* projects that *this* project depends on, primarily when generating the project and task graphs. The most common use case for this is building those projects *before* building this one. When defined, this setting requires an array of project names, which are the keys found in the [`projects`](/docs/config/workspace#projects) map.

moon.yml

```yaml
dependsOn:
  - 'apiClients'
  - 'designSystem'
```

A dependency object can also be defined, where a specific `scope` can be assigned, which accepts "production" (default), "development", "build", or "peer".

moon.yml

```yaml
dependsOn:
  - id: 'apiClients'
    scope: 'production'
  - id: 'designSystem'
    scope: 'peer'
```

> Learn more about [implicit and explicit dependencies](/docs/concepts/project#dependencies).
