---
doc_id: ops/how-it-works/project-graph
chunk_id: ops/how-it-works/project-graph#chunk-1
heading_path: ["Project graph"]
chunk_type: prose
tokens: 122
summary: "Project graph"
---

# Project graph

> **Context**: The project graph is a representation of all configured projects in the workspace and their relationships between each other, and is represented inter

The project graph is a representation of all configured projects in the workspace and their relationships between each other, and is represented internally as a directed acyclic graph (DAG). Below is a visual representation of a project graph, composed of multiple applications and libraries, where both project types depend on libraries.

> The `moon project-graph` command can be used to view the structure of your workspace.
