---
doc_id: ref/concepts/task
chunk_id: ref/concepts/task#chunk-2
heading_path: ["Tasks", "IDs"]
chunk_type: prose
tokens: 85
summary: "IDs"
---

## IDs

A task identifier (or name) is a unique resource for locating a task *within* a project. The ID is explicitly configured as a key within the [`tasks`](/docs/config/project#tasks) setting, and can be written in camel/kebab/snake case. IDs support alphabetic unicode characters, `0-9`, `_`, `-`, `/`, `.`, and must start with a character.

A task ID can be paired with a scope to create a [target](/docs/concepts/target).
