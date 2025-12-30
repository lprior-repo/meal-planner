---
doc_id: ops/config/project
chunk_id: ops/config/project#chunk-18
heading_path: ["moon.{pkl,yml}", "`workspace`"]
chunk_type: code
tokens: 340
summary: "`workspace`"
---

## `workspace`

### `inheritedTasks`

Provides a layer of control when inheriting tasks from [`.moon/tasks.yml`](/docs/config/tasks).

#### `exclude`

The optional `exclude` setting permits a project to exclude specific tasks from being inherited. It accepts a list of strings, where each string is the name of a global task to exclude.

moon.yml

```yaml
workspace:
  inheritedTasks:
    # Exclude the inherited `test` task for this project
    exclude: ['test']
```

> Exclusion is applied after inclusion and before renaming.

#### `include`

The optional `include` setting permits a project to *only* include specific inherited tasks (works like an allow/white list). It accepts a list of strings, where each string is the name of a global task to include.

When this field is not defined, the project will inherit all tasks from the global project config.

moon.yml

```yaml
workspace:
  inheritedTasks:
    # Include *no* tasks (works like a full exclude)
    include: []
    # Only include the `lint` and `test` tasks for this project
    include:
      - 'lint'
      - 'test'
```

> Inclusion is applied before exclusion and renaming.

#### `rename`

The optional `rename` setting permits a project to rename the inherited task within the current project. It accepts a map of strings, where the key is the original name (found in the global project config), and the value is the new name to use.

For example, say we have 2 tasks in the global project config called `buildPackage` and `buildApplication`, but we only need 1, and since we're an application, we should omit and rename.

moon.yml

```yaml
workspace:
  inheritedTasks:
    exclude: ['buildPackage']
    rename:
      buildApplication: 'build'
```

> Renaming occurs after inclusion and exclusion.
