---
doc_id: ops/moonrepo/project
chunk_id: ops/moonrepo/project#chunk-4
heading_path: ["project", "`id` (v1.18.0)"]
chunk_type: prose
tokens: 84
summary: "`id` (v1.18.0)"
---

## `id` (v1.18.0)

Overrides the name (identifier) of the project, which was configured in or derived from the [`projects`](/docs/config/workspace#projects) setting in [`.moon/workspace.yml`](/docs/config/workspace). This setting is useful when using glob based project location, and want to avoid using the folder name as the project name.

moon.yml

```yaml
id: 'custom-id'
```

> All references to the project must use the new identifier, including project and task dependencies.
