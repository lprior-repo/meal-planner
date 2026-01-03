---
doc_id: ops/moonrepo/workspace
chunk_id: ops/moonrepo/workspace#chunk-5
heading_path: [".moon/workspace.{pkl,yml}", "`constraints`"]
chunk_type: prose
tokens: 157
summary: "`constraints`"
---

## `constraints`

Configures constraints between projects that are enforced during project graph generation. This is also known as project boundaries.

### `enforceLayerRelationships`

> This was previously known as `enforceProjectTypeRelationships` and was renamed to `enforceLayerRelationships` in v1.39.

Enforces allowed relationships between a project and its dependencies based on the project's [`layer`](/docs/config/project#layer) and [`stack`](/docs/config/project#stack) settings. When a project depends on another project of an invalid layer, a layering violation error will be thrown when attempting to run a task.

### `tagRelationships`

Enforces allowed relationships between a project and its dependencies based on the project's [`tags`](/docs/config/project#tags) setting. This works in a similar fashion to `enforceLayerRelationships`, but gives you far more control over what these relationships look like.

.moon/workspace.yml

```yaml
constraints:
  tagRelationships:
    next: ['react']
```
