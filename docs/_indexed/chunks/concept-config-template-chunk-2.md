---
doc_id: concept/config/template
chunk_id: concept/config/template#chunk-2
heading_path: ["template.{pkl,yml}", "`id` (v1.23.0)"]
chunk_type: prose
tokens: 59
summary: "`id` (v1.23.0)"
---

## `id` (v1.23.0)

Overrides the name (identifier) of the template, instead of inferring the name from the template folder. Be aware that template names must be unique across the workspace, and across all template locations that have been configured in [`generator.templates`](/docs/config/workspace#templates).

template.yml

```yaml
id: 'npm-package'
```
