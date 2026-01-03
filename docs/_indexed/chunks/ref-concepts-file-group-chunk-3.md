---
doc_id: ref/concepts/file-group
chunk_id: ref/concepts/file-group#chunk-3
heading_path: ["File groups", "Inheritance and merging"]
chunk_type: code
tokens: 157
summary: "Inheritance and merging"
---

## Inheritance and merging

When a file group of the same name exists in both [configuration files](#configuration), the project-level group will override the workspace-level group, and all other workspace-level groups will be inherited as-is.

A primary scenario in which to define file groups at the project-level is when you want to *override* file groups defined at the workspace-level. For example, say we want to override the `sources` file group because our source folder is named "lib" and not "src", we would define our file groups as followed.

.moon/tasks.yml

```yaml
fileGroups:
  sources:
    - 'src/**/*'
    - 'types/**/*'
  tests:
    - 'tests/**/*.test.*'
    - '**/__tests__/**/*'
```

moon.yml

```yaml
fileGroups:
  # Overrides global
  sources:
    - 'lib/**/*'
    - 'types/**/*'
  # Inherited as-is
  tests:
    - 'tests/**/*.test.*'
    - '**/__tests__/**/*'
```
