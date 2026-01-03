---
doc_id: ops/commands/action-graph
chunk_id: ops/commands/action-graph#chunk-3
heading_path: ["action-graph", "Export to DOT format"]
chunk_type: prose
tokens: 139
summary: "Export to DOT format"
---

## Export to DOT format
$ moon action-graph --dot > graph.dot
```

> A target can be passed to focus the graph, including dependencies *and* dependents. For example, `moon action-graph app:build`.

### Arguments

-   `[target]` - Optional target to focus.

### Options

-   `--dependents` - Include dependents of the focused target.
-   `--dot` - Print the graph in DOT format.
-   `--host` - The host address. Defaults to `127.0.0.1`. v1.36.0
-   `--json` - Print the graph in JSON format.
-   `--port` - The port to bind to. Defaults to a random port. v1.36.0

### Configuration

-   [`runner`](/docs/config/workspace#runner) in `.moon/workspace.yml`
-   [`tasks`](/docs/config/tasks#tasks) in `.moon/tasks.yml`
-   [`tasks`](/docs/config/project#tasks) in `moon.yml`
