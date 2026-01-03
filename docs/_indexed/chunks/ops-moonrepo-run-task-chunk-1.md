---
doc_id: ops/moonrepo/run-task
chunk_id: ops/moonrepo/run-task#chunk-1
heading_path: ["Run a task"]
chunk_type: prose
tokens: 124
summary: "Run a task"
---

# Run a task

> **Context**: Even though we've created a task, it's not useful unless we *run it*, which is done with the `moon run <target>` command. This command requires a sing

Even though we've created a task, it's not useful unless we *run it*, which is done with the `moon run <target>` command. This command requires a single argument, a primary target, which is the pairing of a scope and task name. In the example below, our project is `app`, the task is `build`, and the target is `app:build`.

```
$ moon run app:build
