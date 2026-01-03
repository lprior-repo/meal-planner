---
doc_id: ops/moonrepo/workspace
chunk_id: ops/moonrepo/workspace#chunk-4
heading_path: [".moon/workspace.{pkl,yml}", "`codeowners` (v1.8.0)"]
chunk_type: code
tokens: 149
summary: "`codeowners` (v1.8.0)"
---

## `codeowners` (v1.8.0)

Configures code owners (`CODEOWNERS`) integration across the entire workspace.

### `globalPaths`

This setting defines file patterns and their owners at the workspace-level, and are applied to any matching path, at any depth, within the entire workspace. This is useful for defining global or fallback owners when a granular [project-level path](/docs/config/project#paths) does not match or exist.

.moon/workspace.yml

```yaml
codeowners:
  globalPaths:
    '*': ['@admins']
    'config/': ['@infra']
    '/.github/': ['@infra']
```

### `syncOnRun`

Will automatically generate a `CODEOWNERS` file by aggregating and syncing all project [`owners`](/docs/config/project#owners) in the workspace when a [target is run](/docs/concepts/target). The format and location of the `CODEOWNERS` file is based on the [`vcs.provider`](#provider) setting. Defaults to `false`.

.moon/workspace.yml

```yaml
codeowners:
  syncOnRun: true
```
