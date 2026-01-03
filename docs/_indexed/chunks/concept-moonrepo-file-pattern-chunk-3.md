---
doc_id: concept/moonrepo/file-pattern
chunk_id: concept/moonrepo/file-pattern#chunk-3
heading_path: ["File patterns", "Project relative"]
chunk_type: prose
tokens: 44
summary: "Project relative"
---

## Project relative

When configuring [`fileGroups`](/docs/config/project#filegroups), [`inputs`](/docs/config/project#inputs), and [`outputs`](/docs/config/project#outputs), all listed file paths and globs are relative from the project root they will be ran in. They *must not* traverse upwards with `..`.

```
