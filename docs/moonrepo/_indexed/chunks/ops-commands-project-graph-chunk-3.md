---
doc_id: ops/commands/project-graph
chunk_id: ops/commands/project-graph#chunk-3
heading_path: ["project-graph", "Export to DOT format"]
chunk_type: prose
tokens: 146
summary: "Export to DOT format"
---

## Export to DOT format
$ moon project-graph --dot > graph.dot
```

> A project name can be passed to focus the graph to only that project and its dependencies. For example, `moon project-graph app`.

### Arguments

- `[name]` - Optional name or alias of a project to focus, as defined in [`projects`](/docs/config/workspace#projects).

### Options

- `--dependents` - Include direct dependents of the focused project.
- `--dot` - Print the graph in DOT format.
- `--host` - The host address. Defaults to `127.0.0.1`. v1.36.0
- `--json` - Print the graph in JSON format.
- `--port` - The port to bind to. Defaults to a random port. v1.36.0

### Configuration

- [`projects`](/docs/config/workspace#projects) in `.moon/workspace.yml`
