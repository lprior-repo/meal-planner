---
doc_id: ops/general/run-task
chunk_id: ops/general/run-task#chunk-6
heading_path: ["Run a task", "Advanced run targeting"]
chunk_type: code
tokens: 96
summary: "Advanced run targeting"
---

## Advanced run targeting

By this point you should have a basic understanding of how to run tasks, but with moon, we want to provide support for advanced workflows and development scenarios. For example, running a target in all projects:

```
$ moon run :build
```

Or perhaps running a target based on a query:

```
$ moon run :build --query "language=[javascript, typescript]"
```

Jump to the official `moon run` documentation for more examples!
