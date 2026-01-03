---
doc_id: ops/concepts/target
chunk_id: ops/concepts/target#chunk-8
heading_path: ["Targets", "Config scopes"]
chunk_type: prose
tokens: 83
summary: "Config scopes"
---

## Config scopes

These scopes are only available when configuring a task.

### Dependencies `^`

When you want to include a reference for each project [that's depended on](/docs/concepts/project#dependencies), you can utilize the `^` scope. This will be expanded to *all* depended on projects. If you do not want all projects, then you'll need to explicitly define them.

moon.yml

```yaml
dependsOn:
  - 'apiClients'
  - 'designSystem'
