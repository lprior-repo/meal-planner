---
doc_id: ops/moonrepo/project-graph-2
chunk_id: ops/moonrepo/project-graph-2#chunk-3
heading_path: ["Project graph", "What is the graph used for?"]
chunk_type: prose
tokens: 92
summary: "What is the graph used for?"
---

## What is the graph used for?

Great question, the project graph is used throughout the codebase to accomplish a variety of functions, but mainly:

-   Is fed into the task graph to determine relationships of tasks between other tasks, and across projects.
-   Powers our Docker layer caching and scaffolding implementations.
-   Utilized for project syncing to ensure a healthy repository state.
-   Determines affected projects in continuous integration workflows.
