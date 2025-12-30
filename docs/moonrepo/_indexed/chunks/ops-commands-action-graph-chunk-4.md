---
doc_id: ops/commands/action-graph
chunk_id: ops/commands/action-graph#chunk-4
heading_path: ["action-graph", "Example output"]
chunk_type: prose
tokens: 94
summary: "Example output"
---

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
