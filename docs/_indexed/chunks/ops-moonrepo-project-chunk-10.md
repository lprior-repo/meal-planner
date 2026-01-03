---
doc_id: ops/moonrepo/project
chunk_id: ops/moonrepo/project#chunk-10
heading_path: ["project", "`tags`"]
chunk_type: prose
tokens: 50
summary: "`tags`"
---

## `tags`

Tags are a simple mechanism for categorizing projects. They can be used to group projects together for [easier querying](/docs/commands/query/projects), enforcing of [project boundaries and constraints](/docs/config/workspace#constraints), [task inheritance](/docs/concepts/task-inheritance), and more.

moon.yml

```yaml
tags:
  - 'react'
  - 'prisma'
```
