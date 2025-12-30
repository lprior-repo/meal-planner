---
doc_id: ops/general/create-task
chunk_id: ops/general/create-task#chunk-1
heading_path: ["Create a task"]
chunk_type: prose
tokens: 150
summary: "Create a task"
---

# Create a task

> **Context**: The primary focus of moon is a task runner, and for it to operate in any capacity, it requires tasks to run. In moon, a task is a binary or system com

The primary focus of moon is a task runner, and for it to operate in any capacity, it requires tasks to run. In moon, a task is a binary or system command that is ran as a child process within the context of a project (is the current working directory). Tasks are defined per project with `moon.yml`, or inherited by many projects with `.moon/tasks.yml`, but can also be inferred from a language's ecosystem (we'll talk about this later).
