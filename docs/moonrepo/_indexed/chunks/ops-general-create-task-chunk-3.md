---
doc_id: ops/general/create-task
chunk_id: ops/general/create-task#chunk-3
heading_path: ["Create a task", "Depending on other tasks"]
chunk_type: prose
tokens: 102
summary: "Depending on other tasks"
---

## Depending on other tasks

For scenarios where you need run a task *before* another task, as you're expecting some repository state or artifact to exist, can be achieved with the `deps` setting, which requires a list of targets:

-   `<project>:<task>` - Full canonical target.
-   `~:<task>` or `<task>` - A task within the current project.
-   `^:<task>` - A task from all depended on projects.

<project>/moon.yml

```yaml
dependsOn:
  # ...

tasks:
  build:
    # ...
    deps:
      - '^:build'
```
