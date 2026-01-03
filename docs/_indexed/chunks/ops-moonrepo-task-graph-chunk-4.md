---
doc_id: ops/moonrepo/task-graph
chunk_id: ops/moonrepo/task-graph#chunk-4
heading_path: ["task-graph", "Example output"]
chunk_type: prose
tokens: 80
summary: "Example output"
---

## Example output

The following output is an example of the graph in DOT format.

```
digraph {
    0 [ label="types:build" style=filled, shape=oval, fillcolor=gray, fontcolor=black]
    1 [ label="runtime:build" style=filled, shape=oval, fillcolor=gray, fontcolor=black]
    2 [ label="website:build" style=filled, shape=oval, fillcolor=gray, fontcolor=black]
    1 -> 0 [ label="required" arrowhead=box, arrowtail=box]
    2 -> 1 [ label="required" arrowhead=box, arrowtail=box]
    2 -> 0 [ label="required" arrowhead=box, arrowtail=box]
}
```
