---
doc_id: ops/commands/project-graph
chunk_id: ops/commands/project-graph#chunk-4
heading_path: ["project-graph", "Example output"]
chunk_type: prose
tokens: 66
summary: "Example output"
---

## Example output

The following output is an example of the graph in DOT format.

```
digraph {
    0 [ label="(workspace)" style=filled, shape=circle, fillcolor=black, fontcolor=white]
    1 [ label="runtime" style=filled, shape=circle, fillcolor=gray, fontcolor=black]
    2 [ label="website" style=filled, shape=circle, fillcolor=gray, fontcolor=black]
    0 -> 1 [ arrowhead=none]
    0 -> 2 [ arrowhead=none]
}
```
