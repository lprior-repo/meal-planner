---
doc_id: concept/config/template
chunk_id: concept/config/template#chunk-1
heading_path: ["template.{pkl,yml}"]
chunk_type: prose
tokens: 87
summary: "template.{pkl,yml}"
---

# template.{pkl,yml}

> **Context**: The `template.yml` file configures metadata and variables for a template, [used by the generator](/docs/guides/codegen), and must exist at the root of

The `template.yml` file configures metadata and variables for a template, [used by the generator](/docs/guides/codegen), and must exist at the root of a named template folder.

template.yml

```yaml
$schema: 'https://moonrepo.dev/schemas/template.json'
```

> Template configuration can also be written in [Pkl](/docs/guides/pkl-config) instead of YAML.
