---
doc_id: ref/moonrepo/project
chunk_id: ref/moonrepo/project#chunk-2
heading_path: ["Projects", "IDs"]
chunk_type: prose
tokens: 136
summary: "IDs"
---

## IDs

A project identifier (or name) is a unique resource for locating a project. The ID is explicitly configured within [`.moon/workspace.yml`](/docs/config/workspace), as a key within the [`projects`](/docs/config/workspace#projects) setting, and can be written in camel/kebab/snake case. IDs support alphabetic unicode characters, `0-9`, `_`, `-`, `/`, `.`, and must start with a character.

IDs are used heavily by configuration and the command line to link and reference everything. They're also a much easier concept for remembering projects than file system paths, and they typically can be written with less key strokes.

Lastly, a project ID can be paired with a task ID to create a [target](/docs/concepts/target).
