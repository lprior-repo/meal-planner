---
doc_id: concept/moonrepo/template
chunk_id: concept/moonrepo/template#chunk-5
heading_path: ["template.{pkl,yml}", "`destination` (v1.19.0)"]
chunk_type: prose
tokens: 104
summary: "`destination` (v1.19.0)"
---

## `destination` (v1.19.0)

An optional file path in which this template should be generated into. This provides a mechanism for standardizing a destination location, and avoids having to manually pass a destination to [`moon generate`](/docs/commands/generate).

If the destination is prefixed with `/`, it will be relative from the workspace root, otherwise it is relative from the current working directory.

template.yml

```yaml
destination: 'packages/[name]'
```

> This setting supports [template variables](#variables) through `[varName]` syntax. Learn more in the [code generation documentation](/docs/guides/codegen#interpolation).
