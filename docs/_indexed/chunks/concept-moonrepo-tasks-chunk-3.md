---
doc_id: concept/moonrepo/tasks
chunk_id: concept/moonrepo/tasks#chunk-3
heading_path: [".moon/tasks\\[/\\*\\*/\\*\\].{pkl,yml}", "`fileGroups`"]
chunk_type: prose
tokens: 137
summary: "`fileGroups`"
---

## `fileGroups`

> For more information on file group configuration, refer to the [`fileGroups`](/docs/config/project#filegroups) section in the [`moon.yml`](/docs/config/project) doc.

Defines [file groups](/docs/concepts/file-group) that will be inherited by projects, and also enables enforcement of organizational patterns and file locations. For example, encourage projects to place source files in a `src` folder, and all test files in `tests`.

.moon/tasks.yml

```yaml
fileGroups:
  configs:
    - '*.config.{js,cjs,mjs}'
    - '*.json'
  sources:
    - 'src/**/*'
    - 'types/**/*'
  tests:
    - 'tests/**/*'
    - '**/__tests__/**/*'
  assets:
    - 'assets/**/*'
    - 'images/**/*'
    - 'static/**/*'
    - '**/*.{scss,css}'
```

> File paths and globs used within a file group are relative from the inherited project's root, and not the workspace root.
