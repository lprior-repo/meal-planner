---
doc_id: ops/concepts/task-inheritance
chunk_id: ops/concepts/task-inheritance#chunk-1
heading_path: ["Task inheritance"]
chunk_type: prose
tokens: 133
summary: "Task inheritance"
---

# Task inheritance

> **Context**: Unlike other task runners that require the same tasks to be repeatedly defined for *every* project, moon uses an inheritance model where tasks can be 

Unlike other task runners that require the same tasks to be repeatedly defined for *every* project, moon uses an inheritance model where tasks can be defined once at the workspace-level, and are then inherited by *many or all* projects.

Workspace-level tasks (also known as global tasks) are defined in [`.moon/tasks.yml`](/docs/config/tasks) or [`.moon/tasks/**/*.yml`](/docs/config/tasks), and are inherited by default. However, projects are able to include, exclude, or rename inherited tasks using the [`workspace.inheritedTasks`](/docs/config/project#inheritedtasks) in [`moon.yml`](/docs/config/project).
