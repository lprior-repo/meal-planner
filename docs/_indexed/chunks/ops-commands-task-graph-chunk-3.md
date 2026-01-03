---
doc_id: ops/commands/task-graph
chunk_id: ops/commands/task-graph#chunk-3
heading_path: ["task-graph", "Export to DOT format"]
chunk_type: prose
tokens: 130
summary: "Export to DOT format"
---

## Export to DOT format
$ moon task-graph --dot > graph.dot
```

> A task target can be passed to focus the graph to only that task and its dependencies. For example, `moon task-graph app:build`.

### Arguments

- `[target]` - Optional target of task to focus.

### Options

- `--dependents` - Include direct dependents of the focused task.
- `--dot` - Print the graph in DOT format.
- `--host` - The host address. Defaults to `127.0.0.1`. v1.36.0
- `--json` - Print the graph in JSON format.
- `--port` - The port to bind to. Defaults to a random port. v1.36.0
