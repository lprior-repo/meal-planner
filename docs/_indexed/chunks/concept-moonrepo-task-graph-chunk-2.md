---
doc_id: concept/moonrepo/task-graph
chunk_id: concept/moonrepo/task-graph#chunk-2
heading_path: ["Task graph", "Relationships"]
chunk_type: prose
tokens: 118
summary: "Relationships"
---

## Relationships

A relationship is between a dependent (downstream task) and a dependency/requirement (upstream task). Relationships are derived explicitly with the task `deps` setting, and fall into 1 of 2 categories:

### Required

These are dependencies that are required to run and complete with a success, before the owning task can run. If a required dependency fails, then the owning task will abort.

### Optional

The opposite of required, these are dependencies that can either a) not exist during task inheritance, or b) run and fail without aborting the owning task.
