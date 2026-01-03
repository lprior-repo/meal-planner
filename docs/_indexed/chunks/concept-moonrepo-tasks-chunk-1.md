---
doc_id: concept/moonrepo/tasks
chunk_id: concept/moonrepo/tasks#chunk-1
heading_path: [".moon/tasks\\[/\\*\\*/\\*\\].{pkl,yml}"]
chunk_type: prose
tokens: 113
summary: ".moon/tasks\[/\*\*/\*\].{pkl,yml}"
---

# .moon/tasks\[/\*\*/\*\].{pkl,yml}

> **Context**: The `.moon/tasks.yml` file configures file groups and tasks that are inherited by *every* project in the workspace, while `.moon/tasks/**/*.yml` confi

The `.moon/tasks.yml` file configures file groups and tasks that are inherited by *every* project in the workspace, while `.moon/tasks/**/*.yml` configures for projects based on their language or type. [Learn more about task inheritance!](/docs/concepts/task-inheritance)

Projects can override or merge with these settings within their respective [`moon.yml`](/docs/config/project).

.moon/tasks.yml

```yaml
$schema: 'https://moonrepo.dev/schemas/tasks.json'
```

> Inherited tasks configuration can also be written in [Pkl](/docs/guides/pkl-config) instead of YAML.
