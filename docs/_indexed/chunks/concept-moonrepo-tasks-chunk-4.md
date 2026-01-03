---
doc_id: concept/moonrepo/tasks
chunk_id: concept/moonrepo/tasks#chunk-4
heading_path: [".moon/tasks\\[/\\*\\*/\\*\\].{pkl,yml}", "`implicitDeps`"]
chunk_type: prose
tokens: 74
summary: "`implicitDeps`"
---

## `implicitDeps`

Defines task [`deps`](/docs/config/project#deps) that are implicitly inserted into *all* inherited tasks within a project. This is extremely useful for pre-building projects that are used extensively throughout the repo, or always building project dependencies. Defaults to an empty list.

.moon/tasks.yml

```yaml
implicitDeps:
  - '^:build'
```

> Implicit dependencies are *always* inherited, regardless of the [`mergeDeps`](/docs/config/project#mergedeps) option.
