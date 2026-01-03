---
doc_id: concept/config/tasks
chunk_id: concept/config/tasks#chunk-6
heading_path: [".moon/tasks\\[/\\*\\*/\\*\\].{pkl,yml}", "`tasks`"]
chunk_type: prose
tokens: 178
summary: "`tasks`"
---

## `tasks`

> For more information on task configuration, refer to the [`tasks`](/docs/config/project#tasks) section in the [`moon.yml`](/docs/config/project) doc.

As mentioned in the link above, [tasks](/docs/concepts/task) are actions that are ran within the context of a project, and commonly wrap a command. For most workspaces, every project *should* have linting, typechecking, testing, code formatting, so on and so forth. To reduce the amount of boilerplate that *every* project would require, this setting offers the ability to define tasks that are inherited by many projects within the workspace, but can also be overridden per project.

.moon/tasks.yml

```yaml
tasks:
  format:
    command: 'prettier --check .'
  lint:
    command: 'eslint --no-error-on-unmatched-pattern .'
  test:
    command: 'jest --passWithNoTests'
  typecheck:
    command: 'tsc --build'
```

> Relative file paths and globs used within a task are relative from the inherited project's root, and not the workspace root.
