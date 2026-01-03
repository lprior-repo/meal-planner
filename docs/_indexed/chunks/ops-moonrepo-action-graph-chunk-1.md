---
doc_id: ops/moonrepo/action-graph
chunk_id: ops/moonrepo/action-graph#chunk-1
heading_path: ["action-graph"]
chunk_type: prose
tokens: 113
summary: "Action graph"
---

# Action graph

> **Context**: When you run a task on the command line, we generate an action graph to ensure dependencies of tasks have ran before running run the primary task.

When you run a task on the command line, we generate an action graph to ensure dependencies of tasks have ran before running run the primary task.

The action graph is a representation of all tasks, derived from the project graph and task graph, and is also represented internally as a directed acyclic graph (DAG).
