# action-graph

v1.15.0

The `moon action-graph [target]` (or `moon ag`) command will generate and serve a visual graph of all actions and tasks within the workspace, known as the [action graph](/docs/how-it-works/action-graph). In other tools, this is sometimes referred to as a dependency graph or task graph.

```
# Run the visualizer locally
$ moon action-graph

# Export to DOT format
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

## Example output

The following output is an example of the graph in DOT format.

```
digraph {
    0 [ label="SetupToolchain(node)" style=filled, shape=oval, fillcolor=black, fontcolor=white]
    1 [ label="InstallWorkspaceDeps(node)" style=filled, shape=oval, fillcolor=gray, fontcolor=black]
    2 [ label="SyncProject(node, node)" style=filled, shape=oval, fillcolor=gray, fontcolor=black]
    3 [ label="RunTask(node:standard)" style=filled, shape=oval, fillcolor=gray, fontcolor=black]
    1 -> 0 [ arrowhead=box, arrowtail=box]
    2 -> 0 [ arrowhead=box, arrowtail=box]
    3 -> 1 [ arrowhead=box, arrowtail=box]
    3 -> 2 [ arrowhead=box, arrowtail=box]
}
```
