---
doc_id: concept/moonrepo/file-pattern
chunk_id: concept/moonrepo/file-pattern#chunk-6
heading_path: ["File patterns", "Workspace relative"]
chunk_type: prose
tokens: 42
summary: "Workspace relative"
---

## Workspace relative

When configuring [`fileGroups`](/docs/config/project#filegroups), [`inputs`](/docs/config/project#inputs), and [`outputs`](/docs/config/project#outputs), a listed file path or glob can be prefixed with `/` to resolve relative from the workspace root, and *not* the project root.

```
