---
id: ref/concepts/file-group
title: "File groups"
category: ref
tags: ["concepts", "reference", "file"]
---

# File groups

> **Context**: File groups are a mechanism for grouping similar types of files and environment variables within a project using [file glob patterns or literal file p

File groups are a mechanism for grouping similar types of files and environment variables within a project using [file glob patterns or literal file paths](/docs/concepts/file-pattern). These groups are then used by [tasks](/docs/concepts/task) to calculate functionality like cache computation, affected files since last change, deterministic builds, and more.

## Configuration

File groups can be configured per project through [`moon.yml`](/docs/config/project), or for many projects through [`.moon/tasks.yml`](/docs/config/tasks).

### Token functions

File groups can be referenced in [tasks](/docs/concepts/task) using [token functions](/docs/concepts/token). For example, the `@group(name)` token will expand to all paths configured in the `sources` file group.

moon.yml

```yaml
tasks:
  build:
    command: 'vite build'
    inputs:
      - '@group(sources)'
```

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


## See Also

- [file glob patterns or literal file paths](/docs/concepts/file-pattern)
- [tasks](/docs/concepts/task)
- [`moon.yml`](/docs/config/project)
- [`.moon/tasks.yml`](/docs/config/tasks)
- [tasks](/docs/concepts/task)
