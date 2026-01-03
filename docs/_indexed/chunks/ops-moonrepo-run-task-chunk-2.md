---
doc_id: ops/moonrepo/run-task
chunk_id: ops/moonrepo/run-task#chunk-2
heading_path: ["Run a task", "In v1.14+, \"run\" can be omitted"]
chunk_type: prose
tokens: 124
summary: "In v1.14+, \"run\" can be omitted"
---

## In v1.14+, "run" can be omitted
$ moon app:build
```

When this command is ran, it will do the following:

-   Generate a directed acyclic graph, known as the action (dependency) graph.
-   Insert `deps` as targets into the graph.
-   Insert the primary target into the graph.
-   Run all tasks in the graph in parallel and in topological order (the dependency chain).
-   For each task, calculate hashes and either:
    -   On cache hit, exit early and return the last run.
    -   On cache miss, run the task and generate a new cache.
