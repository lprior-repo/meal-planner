---
doc_id: concept/moonrepo/tasks
chunk_id: concept/moonrepo/tasks#chunk-5
heading_path: [".moon/tasks\\[/\\*\\*/\\*\\].{pkl,yml}", "`implicitInputs`"]
chunk_type: prose
tokens: 92
summary: "`implicitInputs`"
---

## `implicitInputs`

Defines task [`inputs`](/docs/config/project#inputs) that are implicitly inserted into *all* inherited tasks within a project. This is extremely useful for the "changes to these files should always trigger a task" scenario.

Like `inputs`, file paths/globs defined here are relative from the inheriting project. [Project and workspace relative file patterns](/docs/concepts/file-pattern#project-relative) are supported and encouraged.

.moon/tasks/node.yml

```yaml
implicitInputs:
  - 'package.json'
```

> Implicit inputs are *always* inherited, regardless of the [`mergeInputs`](/docs/config/project#mergeinputs) option.
